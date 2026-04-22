import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/fall_detection_data.dart';

class WifiTcpService {
  String? esp32Ip;
  int esp32Port = 80;  // Changé de 5000 à 80
  bool isConnected = false;
  late Stream<IMUSensorData> _sensorStream;

  // Singleton pattern
  static final WifiTcpService _instance = WifiTcpService._internal();

  factory WifiTcpService() {
    return _instance;
  }

  WifiTcpService._internal();

  // Connexion à l'ESP32
  Future<bool> connectToESP32(String ipAddress, {int port = 5000}) async {
    try {
      esp32Ip = ipAddress;
      esp32Port = port;

      // Test de ping
      final response = await http
          .get(
            Uri.parse('http://$esp32Ip:$esp32Port/ping'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isConnected = true;
        print('✅ ESP32 connecté: $esp32Ip:$esp32Port');
        return true;
      }
    } catch (e) {
      print('❌ Erreur connexion ESP32: $e');
      isConnected = false;
    }
    return false;
  }

  // Récupérer les données du capteur (simulation)
  Stream<IMUSensorData> getSensorDataStream({Duration interval = const Duration(milliseconds: 100)}) {
    return Stream.periodic(interval, (_) async {
      if (!isConnected) {
        throw Exception('ESP32 not connected');
      }

      try {
        final response = await http.get(
          Uri.parse('http://$esp32Ip:$esp32Port/sensors'),
        ).timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return IMUSensorData.fromJson(data);
        }
      } catch (e) {
        print('❌ Erreur lecture capteurs: $e');
      }
      
      // Données de test si ESP32 non disponible
      return _generateTestSensorData();
    }).asyncExpand((future) => Stream.fromFuture(future));
  }

  // Envoyer commande à l'ESP32
  Future<bool> sendCommand(String command) async {
    try {
      final response = await http.post(
        Uri.parse('http://$esp32Ip:$esp32Port/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cmd': command}),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur envoi commande: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> disconnect() async {
    isConnected = false;
    esp32Ip = null;
    print('✅ Déconnexion ESP32');
  }

  // Données de test
  IMUSensorData generateTestSensorData() {
    final random = DateTime.now().millisecond % 100;
    return IMUSensorData(
      timestamp: DateTime.now(),
      accelX: (random - 50) / 50 * 0.5,
      accelY: (random - 50) / 50 * 0.3,
      accelZ: -9.8 + (random - 50) / 50 * 0.2,
      gyroX: (random - 50) / 50 * 5,
      gyroY: (random - 50) / 50 * 3,
      gyroZ: (random - 50) / 50 * 2,
      magnitude: 9.8,
      temperature: 36.5 + (random - 50) / 50 * 0.5,
    );
  }

  // Données de test (alias)
  IMUSensorData _generateTestSensorData() {
    return generateTestSensorData();
  }

  // Diagnostic connexion
  Future<Map<String, dynamic>> diagnosticConnection() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32Ip:$esp32Port/status'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return {
          'connected': true,
          'data': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
      };
    }
    return {'connected': false};
  }
}
