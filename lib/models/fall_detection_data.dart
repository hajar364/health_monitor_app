// Données IMU du capteur MPU6050
class IMUSensorData {
  final DateTime timestamp;
  final double accelX;      // m/s² ou g
  final double accelY;
  final double accelZ;
  final double gyroX;       // °/s
  final double gyroY;
  final double gyroZ;
  final double magnitude;   // Magnitude totale accélération
  final double temperature; // °C

  IMUSensorData({
    required this.timestamp,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.magnitude,
    required this.temperature,
  });

  factory IMUSensorData.fromJson(Map<String, dynamic> json) {
    final List<double> accel = List<double>.from(json['accel'] ?? [0, 0, -9.8]);
    final List<double> gyro = List<double>.from(json['gyro'] ?? [0, 0, 0]);
    final temp = (json['temperature'] ?? 36.5).toDouble();
    
    final mag = (accel[0] * accel[0] + 
                 accel[1] * accel[1] + 
                 accel[2] * accel[2]).toDouble();

    return IMUSensorData(
      timestamp: DateTime.now(),
      accelX: accel[0],
      accelY: accel[1],
      accelZ: accel[2],
      gyroX: gyro[0],
      gyroY: gyro[1],
      gyroZ: gyro[2],
      magnitude: mag,
      temperature: temp,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'accelX': accelX,
    'accelY': accelY,
    'accelZ': accelZ,
    'gyroX': gyroX,
    'gyroY': gyroY,
    'gyroZ': gyroZ,
    'magnitude': magnitude,
    'temperature': temperature,
  };
}

// Événement détection de chute
class FallEvent {
  final String id;
  final DateTime timestamp;
  final String severity;    // "LOW", "MEDIUM", "HIGH"
  final double confidence;  // 0-100
  final String reason;
  final bool isConfirmed;
  final IMUSensorData? sensorData;

  FallEvent({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.confidence,
    required this.reason,
    required this.isConfirmed,
    this.sensorData,
  });

  factory FallEvent.fromJson(Map<String, dynamic> json) {
    return FallEvent(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      severity: json['severity'] ?? 'MEDIUM',
      confidence: (json['confidence'] ?? 50).toDouble(),
      reason: json['reason'] ?? 'Fall detected',
      isConfirmed: json['isConfirmed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity,
    'confidence': confidence,
    'reason': reason,
    'isConfirmed': isConfirmed,
  };
}
