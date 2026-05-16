import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/threshold_settings.dart';
import '../services/wifi_tcp_service.dart';

// ============================================================
// ESP32 SETTINGS - Model pour stocker IP et paramètres
// ============================================================

class ESP32Settings {
  final String ipAddress;
  final int port;
  final String deviceName;
  final DateTime? lastConnectedAt;
  final bool rememberDevice;

  ESP32Settings({
    required this.ipAddress,
    this.port = 5000,
    this.deviceName = 'ESP32 Health Monitor',
    this.lastConnectedAt,
    this.rememberDevice = true,
  });

  ESP32Settings copyWith({
    String? ipAddress,
    int? port,
    String? deviceName,
    DateTime? lastConnectedAt,
    bool? rememberDevice,
  }) {
    return ESP32Settings(
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      deviceName: deviceName ?? this.deviceName,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      rememberDevice: rememberDevice ?? this.rememberDevice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'port': port,
      'deviceName': deviceName,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      'rememberDevice': rememberDevice,
    };
  }

  factory ESP32Settings.fromJson(Map<String, dynamic> json) {
    return ESP32Settings(
      ipAddress: json['ipAddress'] ?? '192.168.1.100',
      port: json['port'] ?? 5000,
      deviceName: json['deviceName'] ?? 'ESP32 Health Monitor',
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
      rememberDevice: json['rememberDevice'] ?? true,
    );
  }

  @override
  String toString() =>
      'ESP32Settings(ip: $ipAddress:$port, device: $deviceName)';
}

// ============================================================
// NOTIFIER CLASS - Gère la persistance des paramètres avec ChangeNotifier
// ============================================================

class ESP32SettingsNotifier extends ChangeNotifier {
  ESP32Settings _settings = ESP32Settings(ipAddress: '192.168.1.100');
  bool _isLoading = true;
  String? _error;

  ESP32Settings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ESP32SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('esp32_settings');

      if (settingsJson != null && settingsJson.isNotEmpty) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = ESP32Settings.fromJson(json);
      } else {
        _settings = ESP32Settings(ipAddress: '192.168.1.100');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSettings(ESP32Settings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString('esp32_settings', json);
      _settings = settings;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveIPAddress(String ip) async {
    final updated = _settings.copyWith(ipAddress: ip);
    await saveSettings(updated);
  }

  Future<void> savePort(int port) async {
    final updated = _settings.copyWith(port: port);
    await saveSettings(updated);
  }

  Future<void> updateLastConnectedTime() async {
    final updated = _settings.copyWith(lastConnectedAt: DateTime.now());
    await saveSettings(updated);
  }

  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('esp32_settings');
      _settings = ESP32Settings(ipAddress: '192.168.1.100');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

// ============================================================
// WIFI SERVICE NOTIFIER
// ============================================================

class WifiServiceNotifier extends ChangeNotifier {
  final WifiTcpService _wifiService = WifiTcpService();
  bool _isConnected = false;
  String? _error;

  WifiTcpService get service => _wifiService;
  bool get isConnected => _isConnected;
  String? get error => _error;

  Future<bool> connectToESP32(String ip, {int port = 5000}) async {
    try {
      _error = null;
      _isConnected = await _wifiService.connectToESP32(ip, port: port);
      notifyListeners();
      return _isConnected;
    } catch (e) {
      _error = e.toString();
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _wifiService.disconnect();
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}


// ============================================================
// THRESHOLD SETTINGS NOTIFIER - Persistance des seuils de détection
// ============================================================

class ThresholdSettingsNotifier extends ChangeNotifier {
  ThresholdSettings _settings = ThresholdSettings();
  bool _isLoaded = false;

  ThresholdSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  ThresholdSettingsNotifier() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('threshold_settings');
      if (raw != null && raw.isNotEmpty) {
        _settings = ThresholdSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(ThresholdSettings s) async {
    _settings = s;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('threshold_settings', jsonEncode(s.toJson()));
  }

  Future<void> reset() async {
    await save(ThresholdSettings());
  }
}
