import 'patient_profile.dart';

// Événement alerte (Chute, Température, etc)
class AlertEvent {
  final String id;
  final DateTime timestamp;
  final String alertType;      // "FALL", "TEMP_HIGH", "TEMP_LOW", "OFFLINE"
  final String severity;       // "LOW", "MEDIUM", "HIGH", "CRITICAL"
  final PatientProfile? patient;
  final String message;
  final bool isResolved;
  final String? resolution;    // "False Alarm", "Treated", "Manual Cancel"
  final DateTime? resolvedAt;

  AlertEvent({
    required this.id,
    required this.timestamp,
    required this.alertType,
    required this.severity,
    this.patient,
    required this.message,
    this.isResolved = false,
    this.resolution,
    this.resolvedAt,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) {
    return AlertEvent(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String()
      ),
      alertType: json['alertType'] ?? 'UNKNOWN',
      severity: json['severity'] ?? 'MEDIUM',
      patient: json['patient'] != null 
        ? PatientProfile.fromJson(json['patient']) 
        : null,
      message: json['message'] ?? '',
      isResolved: json['isResolved'] ?? false,
      resolution: json['resolution'],
      resolvedAt: json['resolvedAt'] != null 
        ? DateTime.parse(json['resolvedAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'alertType': alertType,
    'severity': severity,
    'patient': patient?.toJson(),
    'message': message,
    'isResolved': isResolved,
    'resolution': resolution,
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  String getSeverityIcon() {
    switch (severity) {
      case 'CRITICAL':
        return '🔴';
      case 'HIGH':
        return '🟠';
      case 'MEDIUM':
        return '🟡';
      default:
        return '🔵';
    }
  }

  String getAlertTypeLabel() {
    switch (alertType) {
      case 'FALL':
        return 'Chute détectée';
      case 'TEMP_HIGH':
        return 'Température élevée';
      case 'TEMP_LOW':
        return 'Température basse';
      case 'OFFLINE':
        return 'Dispositif hors ligne';
      default:
        return 'Alerte';
    }
  }
}
