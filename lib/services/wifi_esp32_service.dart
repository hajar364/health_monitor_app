import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/health_data.dart';

class WiFiESP32Service {
  // Configuration WiFi
  static const String ESP32_SSID = "ESP32_HealthMonitor";
  static const String ESP32_IP = "192.168.4.1";
  static const int ESP32_PORT = 80;
  static const String ESP32_BASE_URL = "http://$ESP32_IP:$ESP32_PORT";

  // Timeout des requêtes
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 5);

  // État de connexion
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Flag pour éviter d'ajouter aux streams après dispose
  bool _disposed = false;

  // Streams pour les données
  final StreamController<HealthData> _healthDataController =
      StreamController<HealthData>.broadcast();
  Stream<HealthData> get healthDataStream => _healthDataController.stream;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Polling timer
  Timer? _pollingTimer;
  final Duration _pollingInterval = Duration(milliseconds: 500);

  // Cache des dernières données
  HealthData? _lastHealthData;

  // Compteur d'erreurs consécutives
  int _consecutiveErrors = 0;
  static const int MAX_CONSECUTIVE_ERRORS = 5;

  /// ===== CONNEXION & INITIALISATION =====

  /// Connecter à l'ESP32 via WiFi
  Future<bool> connectToESP32() async {
    try {
      _statusController.add("Connexion à $ESP32_SSID...");

      // Vérifier la connectivité basique avec l'ESP32
      final response = await http
          .get(
            Uri.parse("$ESP32_BASE_URL/status"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        _isConnected = true;
        _consecutiveErrors = 0;
        if (!_disposed) _statusController.add("✅ Connecté à l'ESP32");

        // Démarrer le polling des données
        _startPolling();
        return true;
      } else {
        _isConnected = false;
        if (!_disposed) _statusController.add("❌ ESP32 hors ligne (${response.statusCode})");
        return false;
      }
    } catch (e) {
      _isConnected = false;
      if (!_disposed) _statusController.add("❌ Erreur: $e");
      return false;
    }
  }

  /// Vérifier l'état de la connexion
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse("$ESP32_BASE_URL/status"))
          .timeout(REQUEST_TIMEOUT);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Déconnecter de l'ESP32
  void disconnect() {
    _stopPolling();
    _isConnected = false;
    _consecutiveErrors = 0;
    _statusController.add("Déconnecté");
  }

  /// ===== POLLING DES DONNÉES =====

  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _fetchHealthData();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Récupérer les données de santé (GET /health)
  Future<void> _fetchHealthData() async {
    try {
      final response = await http
          .get(
            Uri.parse("$ESP32_BASE_URL/health"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        _consecutiveErrors = 0;
        final jsonData = jsonDecode(response.body);
        final healthData = HealthData.fromJsonWiFi(jsonData);

        _lastHealthData = healthData;
        if (!_disposed) _healthDataController.add(healthData);

        // Vérifier la connexion
        if (!_isConnected) {
          _isConnected = true;
          if (!_disposed) _statusController.add("✅ Synchronisé avec l'ESP32");
        }
      } else {
        _handlePollingError("Erreur HTTP ${response.statusCode}");
      }
    } on TimeoutException {
      _handlePollingError("Timeout - ESP32 ne répond pas");
    } catch (e) {
      _handlePollingError("Erreur: $e");
    }
  }

  void _handlePollingError(String message) {
    _consecutiveErrors++;
    if (_consecutiveErrors >= MAX_CONSECUTIVE_ERRORS) {
      _isConnected = false;
      _stopPolling();
      if (!_disposed) _statusController.add("❌ Connexion perdue: $message");
    }
  }

  /// ===== CONTRÔLE DE LA LED =====

  /// Contrôler la LED d'alerte (POST /led)
  Future<bool> setLED(bool active) async {
    try {
      final response = await http
          .post(
            Uri.parse("$ESP32_BASE_URL/led"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "action": active ? "on" : "off",
            }),
          )
          .timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("[LED] ${result['status']}");
        return true;
      }
      return false;
    } catch (e) {
      print("[LED Error] $e");
      return false;
    }
  }

  /// ===== CONFIGURATION =====

  /// Modifier l'intervalle de mesure (POST /config)
  Future<bool> setMeasureInterval(int milliseconds) async {
    try {
      final response = await http
          .post(
            Uri.parse("$ESP32_BASE_URL/config"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "interval": milliseconds,
            }),
          )
          .timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        print("[CONFIG] Intervalle = ${milliseconds}ms");
        return true;
      }
      return false;
    } catch (e) {
      print("[CONFIG Error] $e");
      return false;
    }
  }

  /// Modifier la température de seuil fièvre
  Future<bool> setFeverThreshold(double celsius) async {
    try {
      final response = await http
          .post(
            Uri.parse("$ESP32_BASE_URL/config"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "tempFever": celsius,
            }),
          )
          .timeout(REQUEST_TIMEOUT);

      return response.statusCode == 200;
    } catch (e) {
      print("[CONFIG Error] $e");
      return false;
    }
  }

  /// ===== COMMANDES UTILITAIRES =====

  /// Envoyer une commande générique (compatible avec ancien système)
  Future<String> sendCommand(String command) async {
    try {
      // Mapper les anciennes commandes aux nouvelles routes
      if (command == "LED_ON") {
        await setLED(true);
        return "LED_ON";
      } else if (command == "LED_OFF") {
        await setLED(false);
        return "LED_OFF";
      }

      // Pour les autres commandes, envoyer en POST à /config
      final response = await http
          .post(
            Uri.parse("$ESP32_BASE_URL/config"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"command": command}),
          )
          .timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['status'] ?? "OK";
      }
      return "Error: ${response.statusCode}";
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Récupérer le statut actuel de l'ESP32
  Future<Map<String, dynamic>?> getESP32Status() async {
    try {
      final response = await http
          .get(
            Uri.parse("$ESP32_BASE_URL/status"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("[Status Error] $e");
      return null;
    }
  }

  /// Récupérer une mesure instantanée
  Future<HealthData?> getMeasure() async {
    try {
      final response = await http
          .get(
            Uri.parse("$ESP32_BASE_URL/measure"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return HealthData.fromJsonWiFi(jsonData);
      }
      return null;
    } catch (e) {
      print("[Measure Error] $e");
      return null;
    }
  }

  /// ===== INJECTION POUR TESTS =====

  /// Injecter des données de test (sans WiFi réel)
  void injectTestData(HealthData data) {
    _lastHealthData = data;
    if (!_disposed) _healthDataController.add(data);
  }

  /// Obtenir les dernières données en cache
  HealthData? getLastHealthData() => _lastHealthData;

  /// ===== NETTOYAGE =====

  void dispose() {
    _disposed = true;
    _stopPolling();
    _healthDataController.close();
    _statusController.close();
  }
}
