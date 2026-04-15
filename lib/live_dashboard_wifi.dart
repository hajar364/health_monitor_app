import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_data.dart';
import '../services/wifi_esp32_service.dart';
import '../services/alert_service.dart';

class LiveDashboardWiFi extends StatefulWidget {
  const LiveDashboardWiFi({Key? key}) : super(key: key);

  @override
  State<LiveDashboardWiFi> createState() => _LiveDashboardWiFiState();
}

class _LiveDashboardWiFiState extends State<LiveDashboardWiFi> {
  late WiFiESP32Service wifiService;
  late AlertService alertService;

  HealthData? currentData;
  bool isConnected = false;
  String connectionStatus = "Démarrage...";
  int updateCount = 0;
  DateTime? lastUpdateTime;

  @override
  void initState() {
    super.initState();
    wifiService = WiFiESP32Service();
    alertService = AlertService();
    _initializeServices();
  }

  void _initializeServices() async {
    // Se connecter à l'ESP32
    bool connected = await wifiService.connectToESP32();
    
    // Écouter les changements de statut
    wifiService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          connectionStatus = status;
          isConnected = status.contains("✅");
        });
      }
    });

    // Écouter les données de santé
    wifiService.healthDataStream.listen((healthData) {
      if (mounted) {
        setState(() {
          currentData = healthData;
          lastUpdateTime = DateTime.now();
          updateCount++;
        });
      }

      // Traiter les alertes
      alertService.processHealthData(healthData);
    });

    if (mounted) {
      setState(() {
        isConnected = connected;
      });
    }
  }

  Color _getTemperatureColor(double temp) {
    if (temp >= 39.5) return Colors.red;           // Fièvre critique
    if (temp >= 38.0) return Colors.orange;        // Fièvre modérée
    if (temp < 35.0) return Colors.blue;           // Hypothermie
    if (temp >= 36.5 && temp <= 37.5) return Colors.green; // Normal
    return Colors.amber;                           // Anormal
  }

  Color _getAccelerationColor(double magnitude) {
    if (magnitude > 18000) return Colors.red;      // Chute/impact
    if (magnitude > 10000) return Colors.orange;   // Accélération notable
    return Colors.green;                           // Normal
  }

  Color _getStatusColor(HealthStatus status, AlertType alertType) {
    switch (alertType) {
      case AlertType.fall:
      case AlertType.highFever:
      case AlertType.hypothermia:
        return Colors.red;
      case AlertType.fever:
      case AlertType.abnormalAccel:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withAlpha(30), color.withAlpha(10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color, width: 2),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📊 Tableau de Bord WiFi'),
        backgroundColor: Color(0xFF135BEC),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: isConnected ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: currentData == null
          ? _buildLoadingState()
          : _buildDashboard(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Connexion à l\'ESP32...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            connectionStatus,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (currentData == null) return SizedBox.shrink();

    final tempColor = _getTemperatureColor(currentData!.temperature);
    final accelMag = currentData!.accelMagnitude;
    final accelColor = _getAccelerationColor(accelMag);
    final statusColor = _getStatusColor(currentData!.status, currentData!.alertType);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====  STATUT PRINCIPAL =====
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [statusColor.withAlpha(50), statusColor.withAlpha(20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: statusColor, width: 3),
                ),
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      currentData!.alertType == AlertType.none
                          ? Icons.favorite
                          : Icons.warning_amber_rounded,
                      size: 48,
                      color: statusColor,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentData!.alertDescription,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'LED: ${currentData!.ledActive ? "🔴 ACTIVE" : "⚫ Inactive"}',
                            style: TextStyle(
                              fontSize: 14,
                              color: currentData!.ledActive
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

            SizedBox(height: 20),

            // ===== TEMPÉRATURE & HUMIDITÉ =====
            Text(
              '🌡️ Température',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  title: 'Température Corporelle',
                  value: currentData!.temperature.toStringAsFixed(1),
                  unit: '°C',
                  color: tempColor,
                  icon: Icons.thermostat,
                ),
                _buildMetricCard(
                  title: 'Température Ambiante',
                  value: (currentData!.temperatureAmbient ?? 0).toStringAsFixed(1),
                  unit: '°C',
                  color: Colors.indigo,
                  icon: Icons.cloud,
                ),
              ],
            ),

            SizedBox(height: 20),

            // ===== ACCÉLÉRATION & MOUVEMENT =====
            Text(
              '📊 Mouvement & Accélération',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  title: 'Accél. Totale',
                  value: accelMag.toStringAsFixed(0),
                  unit: 'm/s²',
                  color: accelColor,
                  icon: Icons.motion_photos_on,
                ),
                _buildMetricCard(
                  title: 'Fréquence Cardiaque',
                  value: currentData!.heartRate.toStringAsFixed(0),
                  unit: 'BPM',
                  color: Colors.pink,
                  icon: Icons.favorite,
                ),
              ],
            ),

            SizedBox(height: 20),

            // ===== COMPOSANTES ACCÉLÉRATION =====
            Text(
              '📈 Composantes XYZ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAccelRow('X-axis', currentData!.accelX, Colors.red),
                    Divider(),
                    _buildAccelRow('Y-axis', currentData!.accelY, Colors.green),
                    Divider(),
                    _buildAccelRow('Z-axis', currentData!.accelZ, Colors.blue),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // ===== INFORMATION SYSTÈME =====
            Text(
              '⚙️ Système',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('WiFi SSID', 'ESP32_HealthMonitor', Colors.blue),
                    Divider(),
                    _buildInfoRow('IP Serveur', '192.168.4.1:80', Colors.teal),
                    Divider(),
                    _buildInfoRow(
                      'Dernière MAJ',
                      lastUpdateTime != null
                          ? DateFormat('HH:mm:ss').format(lastUpdateTime!)
                          : 'N/A',
                      Colors.grey,
                    ),
                    Divider(),
                    _buildInfoRow('Total Updates', updateCount.toString(), Colors.purple),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // ===== BOUTONS DE CONTRÔLE =====
            Text(
              '🎮 Contrôles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleLED(),
                    icon: Icon(currentData!.ledActive ? Icons.lightbulb : Icons.lightbulb_outline),
                    label: Text(currentData!.ledActive ? 'LED OFF' : 'LED ON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentData!.ledActive ? Colors.red : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reconnect(),
                    icon: Icon(Icons.refresh),
                    label: Text('Reconnecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF135BEC),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAccelRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Row(
          children: [
            Container(
              width: 120,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.grey[300],
              ),
              child: FractionallySizedBox(
                widthFactor: (value.abs() / 20000).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: color,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleLED() async {
    final newState = !(currentData?.ledActive ?? false);
    bool success = await wifiService.setLED(newState);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState ? '🔴 LED activée' : '⚫ LED désactivée'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur communication WiFi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reconnect() async {
    setState(() => connectionStatus = "Reconnexion...");
    bool connected = await wifiService.connectToESP32();
    
    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Reconnecté à l\'ESP32'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Impossible de se reconnecter'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    wifiService.dispose();
    super.dispose();
  }
}
