import 'package:flutter/material.dart';
import 'services/bluetooth_esp32_service.dart';
import 'services/alert_service.dart';
import 'models/health_data.dart';

class LiveDashboardUpdated extends StatefulWidget {
  const LiveDashboardUpdated({super.key});

  @override
  State<LiveDashboardUpdated> createState() => _LiveDashboardUpdatedState();
}

class _LiveDashboardUpdatedState extends State<LiveDashboardUpdated> {
  late BluetoothESP32Service _bluetoothService;
  late AlertService _alertService;
  
  HealthData? _currentData;
  bool _isConnected = false;
  String _statusMessage = 'Démarrage...';

  @override
  void initState() {
    super.initState();
    _bluetoothService = BluetoothESP32Service();
    _alertService = AlertService();
    _initializeConnection();
  }

  void _initializeConnection() {
    _bluetoothService.healthDataStream.listen((data) {
      setState(() {
        _currentData = data;
        _isConnected = _bluetoothService.isConnected;
      });
      
      // Traiter les alertes
      _alertService.processHealthData(data);
      
      // Afficher alerte visuelle si critique
      if (data.isCritical) {
        _showAlertDialog(data);
      }
    });
    
    _connectToESP32();
  }

  Future<void> _connectToESP32() async {
    setState(() => _statusMessage = 'Recherche ESP32...');
    
    bool connected = await _bluetoothService.connectToFirstESP32();
    
    setState(() {
      _isConnected = connected;
      _statusMessage = connected 
        ? 'Connecté à ESP32' 
        : 'Impossible de se connecter';
    });

    if (!connected) {
      // Utiliser les données de test si pas de connexion
      _bluetoothService.disconnect();
    }
  }

  void _showAlertDialog(HealthData data) {
    AlertService.showCriticalAlertDialog(context, data);
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Monitor - Live"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _isConnected
                ? const Tooltip(
                    message: 'Connecté à ESP32',
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth_connected, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Connecté', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                : Tooltip(
                    message: 'Déconnecté - Données simulées',
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth_disabled, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Hors-ligne', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
      body: _currentData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Injecter des données de test
                      _bluetoothService.getAvailableDevices().then((_) {
                        _bluetoothService._esp32Service.injectTestData();
                      });
                    },
                    child: const Text('Utiliser données de test'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Alert Banner si anormal
                if (_currentData!.isAbnormal)
                  _buildAlertBanner(_currentData!),
                
                // Métriques principales
                HealthMetricCard(
                  icon: Icons.favorite,
                  color: _getHeartRateColor(_currentData!.heartRate),
                  title: "Fréquence Cardiaque",
                  status: _currentData!.heartRate > 100 
                    ? "ÉLEVÉE" 
                    : _currentData!.heartRate < 60 
                      ? "BASSE" 
                      : "NORMALE",
                  intensity: "${_currentData!.heartRate.toStringAsFixed(0)} BPM",
                  value: _getHeartRateIntensity(_currentData!.heartRate),
                ),
                
                HealthMetricCard(
                  icon: Icons.thermostat,
                  color: _getTemperatureColor(_currentData!.temperature),
                  title: "Température Corporelle",
                  status: _getTemperatureStatus(_currentData!.temperature),
                  intensity: "${_currentData!.temperature.toStringAsFixed(1)} °C",
                  value: _currentData!.temperatureAmbient != null 
                    ? "Ambiance: ${_currentData!.temperatureAmbient!.toStringAsFixed(1)}°C"
                    : "",
                ),
                
                HealthMetricCard(
                  icon: Icons.trending_up,
                  color: _getAccelColor(_currentData!.accelMagnitude),
                  title: "Accélération",
                  status: _currentData!.accelMagnitude > 2.0 
                    ? "IMPORTANTE" 
                    : "NORMALE",
                  intensity: "${_currentData!.accelMagnitude.toStringAsFixed(2)} g",
                  value: "X: ${_currentData!.accelX.toStringAsFixed(2)}, "
                      "Y: ${_currentData!.accelY.toStringAsFixed(2)}, "
                      "Z: ${_currentData!.accelZ.toStringAsFixed(2)}",
                ),
                
                // Status LED
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _currentData!.ledActive 
                            ? Icons.lightbulb 
                            : Icons.lightbulb_outline,
                          color: _currentData!.ledActive ? Colors.red : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "LED d'alerte",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentData!.ledActive ? "ACTIVE" : "Inactif",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _currentData!.ledActive 
                                    ? Colors.red 
                                    : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Notes du médecin
                PhysicianNote(
                  note: _currentData!.reason.isNotEmpty
                    ? _currentData!.reason
                    : "Tous les paramètres sont stables.",
                ),
                
                // Boutons d'action
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isConnected
                          ? () => _bluetoothService.requestMeasurement()
                          : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Mesure'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isConnected
                          ? () => _bluetoothService.requestStatus()
                          : null,
                        icon: const Icon(Icons.info),
                        label: const Text('Statut'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildAlertBanner(HealthData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.isCritical ? Colors.red : Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            data.isCritical ? Icons.warning : Icons.info,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.alertDescription,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data.reason,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper functions for colors
  Color _getTemperatureColor(double temp) {
    if (temp < 35) return Colors.blue;
    if (temp <= 37.5) return Colors.green;
    if (temp < 39.5) return Colors.orange;
    return Colors.red;
  }

  String _getTemperatureStatus(double temp) {
    if (temp < 35) return "HYPOTHERMIE";
    if (temp <= 37.5) return "NORMAL";
    if (temp < 39.5) return "FIÈVRE";
    return "FIÈVRE ÉLEVÉE";
  }

  Color _getHeartRateColor(double hr) {
    if (hr < 60) return Colors.blue;
    if (hr <= 100) return Colors.green;
    if (hr < 120) return Colors.orange;
    return Colors.red;
  }

  String _getHeartRateIntensity(double hr) {
    if (hr < 60) return "Ralentie";
    if (hr <= 100) return "Normale";
    if (hr < 120) return "Élevée";
    return "Très élevée";
  }

  Color _getAccelColor(double accel) {
    if (accel < 1.0) return Colors.green;
    if (accel < 2.0) return Colors.orange;
    return Colors.red;
  }
}

class HealthMetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String status;
  final String intensity;
  final String value;

  const HealthMetricCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.status,
    required this.intensity,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              foregroundColor: color,
              radius: 28,
              child: Icon(icon, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    intensity,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhysicianNote extends StatelessWidget {
  final String note;

  const PhysicianNote({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Note Médicale",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
