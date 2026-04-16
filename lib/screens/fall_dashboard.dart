import 'package:flutter/material.dart';
import 'dart:async';
import '../services/wifi_tcp_service.dart';
import '../services/fall_detection_service.dart';
import '../services/alert_service.dart';
import '../models/fall_detection_data.dart';
import '../models/threshold_settings.dart';
import '../models/alert_event.dart';

class FallDetectionDashboard extends StatefulWidget {
  const FallDetectionDashboard({Key? key}) : super(key: key);

  @override
  State<FallDetectionDashboard> createState() => _FallDetectionDashboardState();
}

class _FallDetectionDashboardState extends State<FallDetectionDashboard> {
  late WifiTcpService wifiService;
  late FallDetectionService fallService;
  late AlertService alertService;

  IMUSensorData? lastSensorData;
  List<IMUSensorData> sensorBuffer = [];
  bool isConnected = false;
  String connectionStatus = 'Déconnecté';
  
  // Gestion des streams pour éviter les fuites mémoire
  StreamSubscription? _sensorStreamSubscription;
  StreamSubscription? _testStreamSubscription;

  @override
  void initState() {
    super.initState();
    wifiService = WifiTcpService();
    fallService = FallDetectionService(thresholds: ThresholdSettings());
    alertService = AlertService();
    
    _initializeDashboard();
  }

  @override
  void dispose() {
    // Annuler les streams pour éviter setState après dispose
    _sensorStreamSubscription?.cancel();
    _testStreamSubscription?.cancel();
    super.dispose();
  }

  void _initializeDashboard() async {
    // Connexion ESP32 de test
    final connected = await wifiService.connectToESP32('192.168.1.100');
    
    if (connected) {
      if (mounted) {
        setState(() {
          isConnected = true;
          connectionStatus = 'Connecté ✅';
        });
      }
      _startSensorStream();
    } else {
      if (mounted) {
        setState(() {
          isConnected = false;
          connectionStatus = 'Mode test (sans ESP32)';
        });
      }
      _startTestSensorStream();
    }
  }

  void _startSensorStream() {
    _sensorStreamSubscription = wifiService.getSensorDataStream().listen(
      (data) {
        if (mounted) {
          setState(() {
            lastSensorData = data;
            sensorBuffer.add(data);
            if (sensorBuffer.length > 50) sensorBuffer.removeAt(0);
          });
        }

        // Analyser chute
        final fall = fallService.analyzeSensorData(sensorBuffer);
        if (fall != null && fall.confidence > 75) {
          _handleFallDetected(fall);
        }
      },
      onError: (e) {
        print('❌ Erreur stream: $e');
        if (mounted) {
          setState(() {
            isConnected = false;
            connectionStatus = 'Erreur connexion';
          });
        }
      },
    );
  }

  void _startTestSensorStream() {
    // Flux de test avec données simulées
    _testStreamSubscription = Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
      if (mounted) {
        final testData = wifiService.generateTestSensorData();
        setState(() {
          lastSensorData = testData;
          sensorBuffer.add(testData);
        if (sensorBuffer.length > 50) sensorBuffer.removeAt(0);
        });
      }
    });
  }

  void _handleFallDetected(FallEvent fall) {
    print('🚨 Chute détectée! Confiance: ${fall.confidence}%');
    
    // Créer alerte
    final alert = AlertEvent(
      id: fall.id,
      timestamp: fall.timestamp,
      alertType: 'FALL',
      severity: fall.severity,
      message: 'Chute détectée - ${fall.reason}',
    );

    // Déclencher alerte SOS
    alertService.triggerSOSAlert(alert);

    // Afficher dialog alerte
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 ALERTE CHUTE DÉTECTÉE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confiance: ${fall.confidence.toStringAsFixed(1)}%'),
            Text('Sévérité: ${fall.severity}'),
            Text('Raison: ${fall.reason}'),
            const SizedBox(height: 16),
            const Text('Appel aux services d\'urgence dans 60s...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER ALERTE'),
          ),
          TextButton(
            onPressed: () {
              alertService.emergencyCall('15'); // SAMU
              Navigator.pop(context);
            },
            child: const Text('APPELER URGENCE'),
          ),
        ],
      ),
    );
  }

  void _simulateFall() {
    print('🧪 Simulation chute...');
    
    // Créer données de chute simulée
    for (int i = 0; i < 20; i++) {
      final intensity = 1 + (i / 20) * 3; // Augmente de 1g à 4g
      sensorBuffer.add(
        IMUSensorData(
          timestamp: DateTime.now(),
          accelX: 2.0 * intensity,
          accelY: 1.5 * intensity,
          accelZ: -9.8 + (3.0 * intensity),
          gyroX: 50 * intensity,
          gyroY: 40 * intensity,
          gyroZ: 30 * intensity,
          magnitude: 9.8 * intensity,
          temperature: 36.5,
        ),
      );
    }

    // Ajouter donnée sol
    for (int i = 0; i < 10; i++) {
      sensorBuffer.add(
        IMUSensorData(
          timestamp: DateTime.now(),
          accelX: 0.1,
          accelY: 0.1,
          accelZ: -9.8,
          gyroX: 1,
          gyroY: 1,
          gyroZ: 1,
          magnitude: 9.8,
          temperature: 36.5,
        ),
      );
    }

    // Analyser
    final fall = fallService.analyzeSensorData(sensorBuffer);
    if (fall != null) {
      _handleFallDetected(fall);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Chute non détectée (confiance insuffisante)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Détection de Chute'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CONNEXION ===
            Card(
              color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: isConnected ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'État ESP32',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(connectionStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // === DONNÉES TEMPS RÉEL ===
            const Text(
              'Données Capteurs (Temps réel)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (lastSensorData != null) ...[
              _buildSensorCard(
                'Accélération',
                'X: ${lastSensorData!.accelX.toStringAsFixed(2)}g  Y: ${lastSensorData!.accelY.toStringAsFixed(2)}g  Z: ${lastSensorData!.accelZ.toStringAsFixed(2)}g',
                Icons.speed,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildSensorCard(
                'Magnétude Accélération',
                '${lastSensorData!.magnitude.toStringAsFixed(2)} g',
                Icons.trending_up,
                lastSensorData!.magnitude > 12 ? Colors.red : Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildSensorCard(
                'Température',
                '${lastSensorData!.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat,
                _getTemperatureColor(lastSensorData!.temperature),
              ),
              const SizedBox(height: 12),
              _buildSensorCard(
                'Gyroscope',
                'X: ${lastSensorData!.gyroX.toStringAsFixed(1)}°/s',
                Icons.rotate_right,
                Colors.green,
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // === BOUTON TEST CHUTE ===
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simulateFall,
                icon: const Icon(Icons.warning),
                label: const Text('🧪 SIMULER CHUTE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // === INFOS ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Statistiques',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Buffer capteurs: ${sensorBuffer.length}/50'),
                  Text('Dernière mise à jour: ${DateTime.now().toString().split('.')[0]}'),
                  if (lastSensorData != null)
                    Text('Magnitude: ${lastSensorData!.magnitude.toStringAsFixed(2)} g'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp > 39) return Colors.red;
    if (temp < 35) return Colors.blue;
    return Colors.green;
  }
}
