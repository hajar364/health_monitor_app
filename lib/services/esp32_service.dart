import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/health_data.dart';
import 'esp32_firmware_adapter.dart';

class ESP32Service {
  static const String baseUrl = "http://192.168.30.105"; // Port 80 par défaut
  
  // Streaming Bluetooth
  StreamSubscription? _dataSubscription;
  final _healthDataController = StreamController<HealthData>.broadcast();
  
  String _lastRawData = "";
  bool _isConnected = false;

  // ========== MODE SIMULÉ (Pour tests sans matériel) ==========
  static Future<HealthData> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    final simulatedJson = '''
    {
      "heartRate": 72,
      "temperature": 36.6,
      "humidity": 45,
      "accelX": 0.1,
      "accelY": 0.05,
      "accelZ": 0.98,
      "isAbnormal": false,
      "reason": "Santé stable",
      "timestamp": "${DateTime.now().millisecondsSinceEpoch}"
    }
    ''';
    return HealthData.fromJson(jsonDecode(simulatedJson));
  }

  // ========== MODE RÉEL (Bluetooth + IP) ==========
  
  /// Récupérer les données via HTTP depuis ESP32
  Future<HealthData> fetchDataFromESP32() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));
      if (response.statusCode == 200) {
        return HealthData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erreur ESP32: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur connexion ESP32: $e');
      throw Exception('Impossible de se connecter à l\'ESP32');
    }
  }

  /// Écouter un stream de données Bluetooth
  /// À utiliser avec flutter_bluetooth_serial
  Stream<HealthData> streamBluetoothData() {
    return _healthDataController.stream;
  }

  /// Parser les données reçues du ESP32
  /// Supporte deux formats:
  /// 1. JSON: {"heartRate": 72, "temperature": 36.6, ...}
  /// 2. Format firmware: "=== Mesures ===\nTempérature: Amb=26.71 °C | Obj=27.91 °C\n..."
  void parseAndProcessData(String rawData) {
    try {
      _lastRawData = rawData.trim();
      
      if (_lastRawData.isEmpty) return;
      
      HealthData healthData;
      
      // Déterminer le format
      if (_lastRawData.startsWith('{') && _lastRawData.endsWith('}')) {
        // === FORMAT JSON (ancien) ===
        healthData = _parseJSON(rawData);
      } else if (_lastRawData.contains('=== Mesures ===')) {
        // === FORMAT FIRMWARE (nouveau) ===
        healthData = _parseFirmwareFormat(rawData);
      } else {
        print('⚠️ Format non reconnu: $_lastRawData');
        return;
      }
      
      // Émettre les données
      _healthDataController.add(healthData);
      
      print('✓ Données santé reçues: FC=${healthData.heartRate.toStringAsFixed(1)} BPM, '
            'T=${healthData.temperature.toStringAsFixed(1)}°C, Status=${healthData.status.name}');
      
    } catch (e) {
      print('❌ Erreur parsing: $e');
      print('   Données brutes: $_lastRawData');
    }
  }

  /// Parser le format JSON (ancien)
  HealthData _parseJSON(String jsonString) {
    final json = jsonDecode(jsonString);
    
    return HealthData(
      heartRate: (json['heartRate'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      accelX: (json['accelX'] ?? 0.0).toDouble(),
      accelY: (json['accelY'] ?? 0.0).toDouble(),
      accelZ: (json['accelZ'] ?? 0.0).toDouble(),
      timestamp: DateTime.now(),
      status: (json['isAbnormal'] ?? false) ? HealthStatus.alert : HealthStatus.normal,
      reason: json['reason'] ?? 'Pas de raison',
    );
  }

  /// Parser le format du firmware ESP32 (nouveau)
  /// Format:
  /// === Mesures ===
  /// Température: Amb=26.71 °C | Obj=27.91 °C
  /// MAX30100: IR=0 | RED=0
  /// MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
  /// ⚠️ Alerte : LED allumée ! / OK : LED éteinte.
  HealthData _parseFirmwareFormat(String serialData) {
    return ESP32FirmwareAdapter.parseSerialOutput(serialData);
  }

  /// Ajouter des données de test au stream
  void injectTestData() {
    final testData = HealthData(
      heartRate: 78.5,
      temperature: 36.8,
      humidity: 55.0,
      accelX: 0.05,
      accelY: 0.10,
      accelZ: 0.95,
      timestamp: DateTime.now(),
      status: HealthStatus.normal,
      reason: 'Données de test injectées',
    );
    _healthDataController.add(testData);
  }

  /// Injecter une alerte de test
  void injectAlertData() {
    final alertData = HealthData(
      heartRate: 145.0,
      temperature: 38.2,
      humidity: 60.0,
      accelX: 0.2,
      accelY: 0.15,
      accelZ: 1.05,
      timestamp: DateTime.now(),
      status: HealthStatus.alert,
      reason: 'TACHYCARDIE - Température élevée - Données d\'alerte de test',
    );
    _healthDataController.add(alertData);
  }

  /// Vérifier si la connexion est établie
  bool get isConnected => _isConnected;

  /// Définir l'état de connexion
  void setConnectionStatus(bool connected) {
    _isConnected = connected;
  }

  /// Fermer la connexion et nettoyer les ressources
  void dispose() {
    _dataSubscription?.cancel();
    _healthDataController.close();
  }
}