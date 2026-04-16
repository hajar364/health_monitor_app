import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wifi_tcp_service.dart';
import '../models/threshold_settings.dart';
import '../models/patient_profile.dart';
import '../models/alert_event.dart';
import '../models/fall_detection_data.dart';

// ============================================================
// CONNECTIVITY PROVIDER
// ============================================================

final wifiServiceProvider = Provider<WifiTcpService>((ref) {
  return WifiTcpService();
});

final esp32ConnectionProvider = StateNotifierProvider<ESP32ConnectionNotifier, ESP32ConnectionState>((ref) {
  final wifiService = ref.watch(wifiServiceProvider);
  return ESP32ConnectionNotifier(wifiService);
});

class ESP32ConnectionState {
  final bool isConnected;
  final String ipAddress;
  final int port;
  final String statusMessage;
  final DateTime? lastUpdate;

  ESP32ConnectionState({
    this.isConnected = false,
    this.ipAddress = '192.168.1.100',
    this.port = 5000,
    this.statusMessage = 'Déconnecté',
    this.lastUpdate,
  });

  ESP32ConnectionState copyWith({
    bool? isConnected,
    String? ipAddress,
    int? port,
    String? statusMessage,
    DateTime? lastUpdate,
  }) {
    return ESP32ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      statusMessage: statusMessage ?? this.statusMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class ESP32ConnectionNotifier extends StateNotifier<ESP32ConnectionState> {
  final WifiTcpService wifiService;

  ESP32ConnectionNotifier(this.wifiService) : super(ESP32ConnectionState());

  Future<void> connectToESP32(String ip, int port) async {
    state = state.copyWith(statusMessage: 'Connexion en cours...');
    
    final success = await wifiService.connectToESP32(ip, port: port);
    
    if (success) {
      state = state.copyWith(
        isConnected: true,
        ipAddress: ip,
        port: port,
        statusMessage: 'Connecté ✅',
        lastUpdate: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isConnected: false,
        statusMessage: 'Erreur connexion',
      );
    }
  }

  Future<void> disconnect() async {
    await wifiService.disconnect();
    state = state.copyWith(
      isConnected: false,
      statusMessage: 'Déconnecté',
    );
  }
}

// ============================================================
// SENSOR DATA PROVIDER
// ============================================================

final sensorDataProvider = StreamProvider<IMUSensorData>((ref) {
  final wifiService = ref.watch(wifiServiceProvider);
  return wifiService.getSensorDataStream();
});

final sensorBufferProvider = StateNotifierProvider<SensorBufferNotifier, List<IMUSensorData>>((ref) {
  return SensorBufferNotifier();
});

class SensorBufferNotifier extends StateNotifier<List<IMUSensorData>> {
  SensorBufferNotifier() : super([]);

  void addSensorData(IMUSensorData data) {
    state = [...state, data];
    // Garder les 50 dernières mesures
    if (state.length > 50) {
      state = state.sublist(state.length - 50);
    }
  }

  void clear() {
    state = [];
  }
}

// ============================================================
// SETTINGS PROVIDER
// ============================================================

final thresholdSettingsProvider = StateNotifierProvider<ThresholdSettingsNotifier, ThresholdSettings>((ref) {
  return ThresholdSettingsNotifier(ThresholdSettings());
});

class ThresholdSettingsNotifier extends StateNotifier<ThresholdSettings> {
  ThresholdSettingsNotifier(ThresholdSettings settings) : super(settings);

  void updateSensitivity(double value) {
    state = state.copyWith(fallDetectionSensitivity: value);
  }

  void updateAccelerationThreshold(double value) {
    state = state.copyWith(accelerationThreshold: value);
  }

  void updateTemperatureHighAlert(double value) {
    state = state.copyWith(temperatureHighAlert: value);
  }

  void updateTemperatureLowAlert(double value) {
    state = state.copyWith(temperatureLowAlert: value);
  }

  void updateSosActivationTime(int value) {
    state = state.copyWith(sosActivationTime: value);
  }

  void updateEnableAutoCall(bool value) {
    state = state.copyWith(enableAutoCall: value);
  }

  void resetToDefaults() {
    state = ThresholdSettings();
  }
}

// ============================================================
// ALERTS PROVIDER
// ============================================================

final alertHistoryProvider = StateNotifierProvider<AlertHistoryNotifier, List<AlertEvent>>((ref) {
  return AlertHistoryNotifier();
});

class AlertHistoryNotifier extends StateNotifier<List<AlertEvent>> {
  AlertHistoryNotifier() : super([]);

  void addAlert(AlertEvent alert) {
    state = [alert, ...state];
  }

  void resolveAlert(String alertId, String resolution) {
    state = state.map((alert) {
      if (alert.id == alertId) {
        return AlertEvent(
          id: alert.id,
          timestamp: alert.timestamp,
          alertType: alert.alertType,
          severity: alert.severity,
          patient: alert.patient,
          message: alert.message,
          isResolved: true,
          resolution: resolution,
          resolvedAt: DateTime.now(),
        );
      }
      return alert;
    }).toList();
  }

  void clearAll() {
    state = [];
  }

  int getUnresolvedCount() {
    return state.where((a) => !a.isResolved).length;
  }
}

final unresolvedAlertsProvider = Provider<List<AlertEvent>>((ref) {
  final alerts = ref.watch(alertHistoryProvider);
  return alerts.where((a) => !a.isResolved).toList();
});

// ============================================================
// PATIENTS PROVIDER
// ============================================================

final patientsProvider = StateNotifierProvider<PatientsNotifier, List<PatientProfile>>((ref) {
  return PatientsNotifier();
});

class PatientsNotifier extends StateNotifier<List<PatientProfile>> {
  PatientsNotifier() : super([]);

  void addPatient(PatientProfile patient) {
    state = [...state, patient];
  }

  void updatePatient(PatientProfile patient) {
    state = state.map((p) => p.id == patient.id ? patient : p).toList();
  }

  void deletePatient(String patientId) {
    state = state.where((p) => p.id != patientId).toList();
  }

  PatientProfile? getPatient(String patientId) {
    try {
      return state.firstWhere((p) => p.id == patientId);
    } catch (e) {
      return null;
    }
  }
}

// ============================================================
// APP STATE PROVIDER (Global state)
// ============================================================

final appStateProvider = Provider<AppState>((ref) {
  final connectivity = ref.watch(esp32ConnectionProvider);
  final sensorBuffer = ref.watch(sensorBufferProvider);
  final alerts = ref.watch(alertHistoryProvider);
  final patients = ref.watch(patientsProvider);
  final settings = ref.watch(thresholdSettingsProvider);

  return AppState(
    connectivity: connectivity,
    sensorBuffer: sensorBuffer,
    alerts: alerts,
    patients: patients,
    settings: settings,
  );
});

class AppState {
  final ESP32ConnectionState connectivity;
  final List<IMUSensorData> sensorBuffer;
  final List<AlertEvent> alerts;
  final List<PatientProfile> patients;
  final ThresholdSettings settings;

  AppState({
    required this.connectivity,
    required this.sensorBuffer,
    required this.alerts,
    required this.patients,
    required this.settings,
  });
}
