import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fall_detection_data.dart';
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
// PROVIDERS
// ============================================================

// Accéder à SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Provider principal pour les paramètres ESP32 avec persistance
final esp32SettingsProvider =
    StateNotifierProvider<ESP32SettingsNotifier, AsyncValue<ESP32Settings>>((ref) {
  return ESP32SettingsNotifier();
});

// Provider pour le WiFi service
final wifiServiceProvider = Provider<WifiTcpService>((ref) {
  return WifiTcpService();
});

// Provider stream pour les données des capteurs en temps réel
final esp32SensorStreamProvider = StreamProvider<IMUSensorData>((ref) async* {
  try {
    final settings = ref.watch(esp32SettingsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );

    if (settings == null) throw Exception('Paramètres ESP32 non chargés');

    final wifiService = ref.watch(wifiServiceProvider);

    // Connecter à l'ESP32 d'abord
    final connected = await wifiService.connectToESP32(
      settings.ipAddress,
      port: settings.port,
    );

    if (!connected) {
      throw Exception(
          'Impossible de se connecter à l\'ESP32 ${settings.ipAddress}:${settings.port}');
    }

    // Émettre les données du stream
    await for (final data in wifiService.getSensorDataStream()) {
      yield data;
    }
  } catch (e) {
    throw Exception('Erreur stream capteurs: $e');
  }
});

// Provider utile pour accéder rapidement à l'IP sauvegardée
final savedIPProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('esp32_ip') ?? '192.168.1.100';
});

// Provider pour accéder à la dernière IP connue (synchrone)
final lastKnownIPProvider = Provider<String>((ref) {
  return ref.watch(esp32SettingsProvider).when(
        data: (settings) => settings.ipAddress,
        loading: () => '192.168.1.100',
        error: (_, __) => '192.168.1.100',
      );
});

// Provider pour l'état de connexion
final esp32ConnectionStatusProvider = StreamProvider<bool>((ref) async* {
  try {
    final wifiService = ref.watch(wifiServiceProvider);

    while (true) {
      try {
        final settings = ref.watch(esp32SettingsProvider).maybeWhen(
              data: (s) => s,
              orElse: () => null,
            );

        if (settings != null) {
          final connected = await wifiService.connectToESP32(
            settings.ipAddress,
            port: settings.port,
          );
          yield connected;
        } else {
          yield false;
        }
      } catch (e) {
        yield false;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  } catch (e) {
    yield false;
  }
});

// ============================================================
// NOTIFIER CLASS - Gère la persistance des paramètres
// ============================================================

class ESP32SettingsNotifier extends StateNotifier<AsyncValue<ESP32Settings>> {
  ESP32SettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('esp32_settings');

      if (settingsJson != null && settingsJson.isNotEmpty) {
        // Charger depuis SharedPreferences
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        final settings = ESP32Settings.fromJson(json);
        state = AsyncValue.data(settings);
      } else {
        // Paramètres par défaut
        state = AsyncValue.data(
          ESP32Settings(ipAddress: '192.168.1.100'),
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> saveSettings(ESP32Settings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString('esp32_settings', json);
      
      // Sauvegarder aussi l'IP seule pour accès rapide
      await prefs.setString('esp32_ip', settings.ipAddress);
      
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> saveIPAddress(String ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (state.hasValue) {
        final currentSettings = state.value!;
        final updatedSettings = currentSettings.copyWith(
          ipAddress: ipAddress,
          lastConnectedAt: DateTime.now(),
        );

        final json = jsonEncode(updatedSettings.toJson());
        await prefs.setString('esp32_settings', json);
        await prefs.setString('esp32_ip', ipAddress);

        state = AsyncValue.data(updatedSettings);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> savePort(int port) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (state.hasValue) {
        final currentSettings = state.value!;
        final updatedSettings = currentSettings.copyWith(port: port);

        final json = jsonEncode(updatedSettings.toJson());
        await prefs.setString('esp32_settings', json);

        state = AsyncValue.data(updatedSettings);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateLastConnectedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (state.hasValue) {
        final currentSettings = state.value!;
        final updatedSettings = currentSettings.copyWith(
          lastConnectedAt: DateTime.now(),
        );

        final json = jsonEncode(updatedSettings.toJson());
        await prefs.setString('esp32_settings', json);

        state = AsyncValue.data(updatedSettings);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('esp32_settings');
      await prefs.remove('esp32_ip');

      state = AsyncValue.data(
        ESP32Settings(ipAddress: '192.168.1.100'),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
