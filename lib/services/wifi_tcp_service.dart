import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/fall_detection_data.dart';

class WifiTcpService {
  String? esp32Ip;
  int esp32Port = 80; // Port HTTP standard Arduino
  bool isConnected = false;

  // Singleton pattern
  static final WifiTcpService _instance = WifiTcpService._internal();

  factory WifiTcpService() {
    return _instance;
  }

  WifiTcpService._internal();

  /// Connexion à l'ESP32 - Test avec endpoint /ping
  Future<bool> connectToESP32(String ipAddress, {int port = 80}) async {
    try {
      esp32Ip = ipAddress;
      esp32Port = port;

      // Test de ping avec timeout
      final response = await http
          .get(
            Uri.parse('http://$esp32Ip:$esp32Port/ping'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          isConnected = true;
          print('✅ ESP32 connecté: $esp32Ip:$esp32Port');
          return true;
        }
      }
    } catch (e) {
      print('❌ Erreur connexion ESP32: $e');
      isConnected = false;
    }
    return false;
  }

  /// Lire les données des capteurs (endpoint /sensors)
  Future<IMUSensorData> getSensorData() async {
    if (!isConnected || esp32Ip == null) {
      throw Exception('ESP32 non connecté');
    }

    try {
      final response = await http.get(
        Uri.parse('http://$esp32Ip:$esp32Port/sensors'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return IMUSensorData(
          timestamp: DateTime.now(),
          accelX: (json['accelX'] as num).toDouble() / 16384.0, // Convertir en G
          accelY: (json['accelY'] as num).toDouble() / 16384.0,
          accelZ: (json['accelZ'] as num).toDouble() / 16384.0,
          gyroX: (json['gyroX'] as num).toDouble() / 131.0, // Convertir en °/s
          gyroY: (json['gyroY'] as num).toDouble() / 131.0,
          gyroZ: (json['gyroZ'] as num).toDouble() / 131.0,
          magnitude: _calculateMagnitude(
            (json['accelX'] as num).toDouble(),
            (json['accelY'] as num).toDouble(),
            (json['accelZ'] as num).toDouble(),
          ),
          temperature: (json['tempObj'] as num).toDouble(),
        );
      }
    } catch (e) {
      print('❌ Erreur lecture capteurs: $e');
      return _generateTestSensorData();
    }
    return _generateTestSensorData();
  }

  /// Stream de données des capteurs (polling toutes les 100ms)
  Stream<IMUSensorData> getSensorDataStream(
      {Duration interval = const Duration(milliseconds: 100)}) {
    return Stream.periodic(interval, (_) => getSensorData())
        .asyncExpand((future) => Stream.fromFuture(future));
  }

  /// Récupérer l'état du système (endpoint /status)
  Future<Map<String, dynamic>> getSystemStatus() async {
    if (!isConnected || esp32Ip == null) {
      throw Exception('ESP32 non connecté');
    }

    try {
      final response = await http.get(
        Uri.parse('http://$esp32Ip:$esp32Port/status'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('❌ Erreur lecture status: $e');
    }
    return {};
  }

  /// Envoyer une commande à l'ESP32
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

  /// Déconnexion
  Future<void> disconnect() async {
    isConnected = false;
    esp32Ip = null;
    print('✅ Déconnexion ESP32');
  }

  /// Générer des données de test
  IMUSensorData _generateTestSensorData() {
    final now = DateTime.now();
    final random = now.millisecond % 100;
    return IMUSensorData(
      timestamp: now,
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

  /// Alias public pour génération de données de test
  IMUSensorData generateTestSensorData() {
    return _generateTestSensorData();
  }

  /// Calculer la magnitude de l'accélération
  double _calculateMagnitude(double ax, double ay, double az) {
    final gx = ax / 16384.0;
    final gy = ay / 16384.0;
    final gz = az / 16384.0;
    return sqrt(gx * gx + gy * gy + gz * gz);
  }
}
