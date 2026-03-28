// Énumération des statuts de santé
enum HealthStatus {
  normal,     // Données normales
  warning,    // Attention requise
  alert,      // Alerte urgente
}

class HealthData {
  /// Fréquence cardiaque en BPM
  final double heartRate;
  
  /// Température corporelle en °C
  final double temperature;
  
  /// Humidité ambiante en %
  final double humidity;
  
  /// Accélération X-axis en g
  final double accelX;
  
  /// Accélération Y-axis en g
  final double accelY;
  
  /// Accélération Z-axis en g
  final double accelZ;
  
  /// Nombre de pas (legacy)
  final int steps;
  
  /// Timestamp de la mesure
  final DateTime timestamp;
  
  /// Statut de santé
  final HealthStatus status;
  
  /// Raison de l'alerte ou contexte
  final String reason;

  HealthData({
    required this.heartRate,
    required this.temperature,
    this.humidity = 0.0,
    this.accelX = 0.0,
    this.accelY = 0.0,
    this.accelZ = 0.0,
    this.steps = 0,
    required this.timestamp,
    this.status = HealthStatus.normal,
    this.reason = '',
  });

  /// Parser depuis JSON (compatible avec ESP32 et format legacy)
  factory HealthData.fromJson(Map<String, dynamic> json) {
    // Déterminer le statut depuis isAbnormal
    HealthStatus status = HealthStatus.normal;
    if (json['isAbnormal'] == true) {
      status = HealthStatus.alert;
    }
    
    return HealthData(
      heartRate: (json['heartRate'] ?? json['heart_rate'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      accelX: (json['accelX'] ?? 0).toDouble(),
      accelY: (json['accelY'] ?? 0).toDouble(),
      accelZ: (json['accelZ'] ?? 0).toDouble(),
      steps: json['steps'] ?? 0,
      timestamp: json['timestamp'] != null 
        ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt())
        : DateTime.now(),
      status: status,
      reason: json['reason'] ?? '',
    );
  }

  /// Exporter en JSON
  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'temperature': temperature,
      'humidity': humidity,
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'steps': steps,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'reason': reason,
      'isAbnormal': status == HealthStatus.alert,
    };
  }

  /// String description pour debug
  @override
  String toString() {
    return '''HealthData(
      heartRate: $heartRate BPM,
      temperature: $temperature°C,
      humidity: $humidity%,
      accel: ($accelX, $accelY, $accelZ) g,
      status: ${status.name},
      reason: $reason,
      timestamp: ${timestamp.toIso8601String()}
    )''';
  }

  /// Vérifier si les données sont anormales
  bool get isAbnormal => status == HealthStatus.alert;
  
  /// Obtenir la magnitude totale d'accélération
  double get accelMagnitude => 
    (accelX * accelX + accelY * accelY + accelZ * accelZ).toDouble();
}