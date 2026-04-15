import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/health_data.dart';

/// Service pour gérer les interactions avec l'ESP32
/// Supporte Bluetooth Serial et HTTP
class ESP32Service {
  static const String baseUrl = "http://192.168.1.100"; // IP ESP32
  
  // Streaming pour données Bluetooth
  final _healthDataController = StreamController<HealthData>.broadcast();
  
  String _lastRawData = "";
  bool _isConnected = false;

  // ========== MODE SIMULÉ (Pour tests sans matériel) ==========
  static Future<HealthData> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    final simulatedJson = {
      "heartRate": 72,
      "temperature": 36.6,
      "humidity": 45,
      "accelX": 0.1,
      "accelY": 0.05,
      "accelZ": 0.98,
      "fallDetected": false,
      "feverDetected": false,
      "hypothermiaDetected": false,
      "alertStatus": "NORMAL",
      "timestamp": DateTime.now().millisecondsSinceEpoch
    };
    return HealthData.fromJson(simulatedJson);
  }

  // ========== MODE RÉEL (Bluetooth + IP) ==========
  
  /// Récupérer les données via HTTP depuis ESP32
  Future<HealthData> fetchDataFromESP32() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        return HealthData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erreur ESP32: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur connexion ESP32: $e');
      rethrow;
    }
  }

  /// Écouter un stream de données Bluetooth
  Stream<HealthData> streamBluetoothData() {
    return _healthDataController.stream;
  }

  /// Parser et traiter les données reçues du ESP32 via Bluetooth
  void parseAndProcessData(String rawData) {
    try {
      _lastRawData = rawData.trim();
      
      if (_lastRawData.isEmpty) return;
      
      HealthData healthData;
      
      // Vérifier si c'est du JSON valide
      if (_lastRawData.startsWith('{') && _lastRawData.endsWith('}')) {
        healthData = _parseJSONData(rawData);
      } else {
        print('⚠️ Format non reconnu - pas du JSON valide');
        return;
      }
      
      // Émettre les données parsées
      _healthDataController.add(healthData);
      
      // Log
      _printDataSummary(healthData);
      
    } catch (e) {
      print('❌ Erreur parsing: $e');
      print('   Données brutes: $_lastRawData');
    }
  }

  /// Parser les données JSON envoyées par le firmware ESP32
  /// Le firmware envoie:
  /// {
  ///   "temperature": 36.5,
  ///   "temperatureAmbient": 25.0,
  ///   "accelX": 0.05,
  ///   "accelY": 0.1,
  ///   "accelZ": 0.95,
  ///   "fallDetected": false,
  ///   "feverDetected": false,
  ///   "hypothermiaDetected": false,
  ///   "ledActive": false,
  ///   "status": "OK",
  ///   "alertStatus": "NORMAL",
  ///   "timestamp": 12345678
  /// }
  HealthData _parseJSONData(String jsonString) {
    final json = jsonDecode(jsonString);
    
    // Déterminer le statut global
    HealthStatus status = HealthStatus.normal;
    String reason = '';
    
    bool fallDetected = json['fallDetected'] ?? false;
    bool feverDetected = json['feverDetected'] ?? false;
    bool hypothermiaDetected = json['hypothermiaDetected'] ?? false;
    
    if (fallDetected) {
      status = HealthStatus.alert;
      reason = '🚨 CHUTE DÉTECTÉE - Intervention requise!';
    } else if (feverDetected) {
      status = HealthStatus.alert;
      double temp = (json['temperature'] ?? 0).toDouble();
      if (temp >= 39.5) {
        reason = '🔴 FIÈVRE ÉLEVÉE (${temp.toStringAsFixed(1)}°C) - Assistance médicale!';
      } else {
        reason = '🤒 FIÈVRE MODÉRÉE (${temp.toStringAsFixed(1)}°C) - Surveillance requise';
      }
    } else if (hypothermiaDetected) {
      status = HealthStatus.alert;
      double temp = (json['temperature'] ?? 0).toDouble();
      reason = '❄️ HYPOTHERMIE (${temp.toStringAsFixed(1)}°C) - Réchauffement requis!';
    } else {
      status = HealthStatus.normal;
      reason = 'Santé normale - Paramètres stables';
    }
    
    return HealthData(
      heartRate: (json['heartRate'] ?? 72).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      accelX: (json['accelX'] ?? 0).toDouble(),
      accelY: (json['accelY'] ?? 0).toDouble(),
      accelZ: (json['accelZ'] ?? 0).toDouble(),
      steps: 0,
      timestamp: json['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt())
        : DateTime.now(),
      status: status,
      reason: reason,
    );
  }

  /// Afficher un résumé des données reçues
  void _printDataSummary(HealthData data) {
    print('''
✓ Données ESP32 reçues:
  📊 Température: ${data.temperature.toStringAsFixed(1)}°C
  🤖 Accélération: X=${data.accelX.toStringAsFixed(2)}, Y=${data.accelY.toStringAsFixed(2)}, Z=${data.accelZ.toStringAsFixed(2)} g
  📍 Statut: ${data.status.name.toUpperCase()}
  💬 ${data.reason}
    ''');
  }

  /// Ajouter des données de test au stream
  void injectTestData() {
    final testData = HealthData(
      heartRate: 72.0,
      temperature: 36.8,
      humidity: 55.0,
      accelX: 0.05,
      accelY: 0.10,
      accelZ: 0.95,
      timestamp: DateTime.now(),
      status: HealthStatus.normal,
      reason: '✅ Santé normale - Données de test',
    );
    _healthDataController.add(testData);
  }

  /// Injecter une alerte de fièvre
  void injectFeverAlert() {
    final alertData = HealthData(
      heartRate: 88.0,
      temperature: 38.5,
      humidity: 60.0,
      accelX: 0.1,
      accelY: 0.05,
      accelZ: 1.0,
      timestamp: DateTime.now(),
      status: HealthStatus.alert,
      reason: '🤒 FIÈVRE MODÉRÉE (38.5°C) - Surveillance requise',
    );
    _healthDataController.add(alertData);
  }

  /// Injecter une alerte de chute
  void injectFallAlert() {
    final alertData = HealthData(
      heartRate: 95.0,
      temperature: 36.5,
      humidity: 50.0,
      accelX: 2.5,
      accelY: 1.8,
      accelZ: 0.3,
      timestamp: DateTime.now(),
      status: HealthStatus.alert,
      reason: '🚨 CHUTE DÉTECTÉE - Intervention requise!',
    );
    _healthDataController.add(alertData);
  }

  /// Injecter une alerte d'hypothermie
  void injectHypothermiaAlert() {
    final alertData = HealthData(
      heartRate: 58.0,
      temperature: 34.5,
      humidity: 45.0,
      accelX: 0.02,
      accelY: 0.01,
      accelZ: 0.98,
      timestamp: DateTime.now(),
      status: HealthStatus.alert,
      reason: '❄️ HYPOTHERMIE (34.5°C) - Réchauffement requis!',
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
    _healthDataController.close();
  }
}