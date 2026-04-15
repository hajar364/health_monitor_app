/// Énumération des statuts de santé
enum HealthStatus {
  normal,     // Données normales
  warning,    // Attention requise (température légèrement élevée)
  alert,      // Alerte urgente (fièvre, chute, hypothermie)
}

/// Énumération des types d'alerte
enum AlertType {
  none,           // Pas d'alerte
  fever,          // Fièvre modérée (38-39.5°C)
  highFever,      // Fièvre élevée (>39.5°C)
  hypothermia,    // Hypothermie (<35°C)
  fall,           // Détection de chute
  abnormalAccel,  // Accélération anormale
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
  
  /// Type d'alerte détecté
  final AlertType alertType;
  
  /// Température ambiante (ESP32)
  final double? temperatureAmbient;
  
  /// LED active (ESP32)
  final bool ledActive;

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
    this.alertType = AlertType.none,
    this.temperatureAmbient,
    this.ledActive = false,
  });

  /// Parser depuis JSON (compatible avec ESP32 et format legacy)
  factory HealthData.fromJson(Map<String, dynamic> json) {
    // Déterminer alertType
    AlertType alertType = AlertType.none;
    HealthStatus status = HealthStatus.normal;
    
    if (json['fallDetected'] == true) {
      alertType = AlertType.fall;
      status = HealthStatus.alert;
    } else if (json['hypothermiaDetected'] == true) {
      alertType = AlertType.hypothermia;
      status = HealthStatus.alert;
    } else if (json['feverDetected'] == true) {
      double temp = (json['temperature'] ?? 0).toDouble();
      if (temp >= 39.5) {
        alertType = AlertType.highFever;
      } else {
        alertType = AlertType.fever;
      }
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
      reason: json['reason'] ?? json['status'] ?? '',
      alertType: alertType,
      temperatureAmbient: json['temperatureAmbient']?.toDouble(),
      ledActive: json['ledActive'] ?? false,
    );
  }

  /// Parser depuis JSON WiFi (ESP32 HTTP response)
  factory HealthData.fromJsonWiFi(Map<String, dynamic> json) {
    // Identique à fromJson, just pour clarité
    return HealthData.fromJson(json);
  }

  /// Exporter en JSON
  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'temperature': temperature,
      'temperatureAmbient': temperatureAmbient,
      'humidity': humidity,
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'steps': steps,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'alertType': alertType.name,
      'reason': reason,
      'ledActive': ledActive,
      'isAbnormal': status == HealthStatus.alert,
    };
  }

  /// String description pour debug
  @override
  String toString() {
    return '''HealthData(
      heartRate: $heartRate BPM,
      temperature: $temperature°C (ambient: ${temperatureAmbient ?? 'N/A'}°C),
      humidity: $humidity%,
      accel: ($accelX, $accelY, $accelZ) g,
      status: ${status.name},
      alertType: ${alertType.name},
      ledActive: $ledActive,
      reason: $reason,
      timestamp: ${timestamp.toIso8601String()}
    )''';
  }

  /// Vérifier si les données sont anormales
  bool get isAbnormal => status == HealthStatus.alert;
  
  /// Obtenir la magnitude totale d'accélération
  double get accelMagnitude => 
    (accelX * accelX + accelY * accelY + accelZ * accelZ).toDouble();
  
  /// Vérifier si c'est une alerte critique (chute, fièvre élevée, hypothermie)
  bool get isCritical => 
    alertType == AlertType.fall || 
    alertType == AlertType.highFever || 
    alertType == AlertType.hypothermia;
  
  /// Description courte de l'alerte
  String get alertDescription {
    switch (alertType) {
      case AlertType.none:
        return 'Santé normale';
      case AlertType.fever:
        return '🤒 Fièvre modérée (38-39.5°C)';
      case AlertType.highFever:
        return '🔴 Fièvre élevée (>39.5°C)';
      case AlertType.hypothermia:
        return '❄️ Hypothermie (<35°C)';
      case AlertType.fall:
        return '🚨 Chute détectée';
      case AlertType.abnormalAccel:
        return '⚠️ Mouvement anormal';
    }
  }
}