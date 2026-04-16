// Configure les seuils critiques pour la détection
class ThresholdSettings {
  double fallDetectionSensitivity;      // 0.5 - 2.0
  double accelerationThreshold;         // en g (9.8 = 1g)
  double temperatureHighAlert;          // °C
  double temperatureLowAlert;           // °C
  int fallConfirmationDelay;            // ms
  int sosActivationTime;                // ms avant appel auto
  bool enableAutoCall;                  // Appel auto après SOS
  String sosPhoneNumber;                // Numéro à appeler

  ThresholdSettings({
    this.fallDetectionSensitivity = 1.0,
    this.accelerationThreshold = 1.5,
    this.temperatureHighAlert = 39.0,
    this.temperatureLowAlert = 35.0,
    this.fallConfirmationDelay = 300,
    this.sosActivationTime = 60000,
    this.enableAutoCall = true,
    this.sosPhoneNumber = '',
  });

  factory ThresholdSettings.fromJson(Map<String, dynamic> json) {
    return ThresholdSettings(
      fallDetectionSensitivity: (json['fallDetectionSensitivity'] ?? 1.0).toDouble(),
      accelerationThreshold: (json['accelerationThreshold'] ?? 1.5).toDouble(),
      temperatureHighAlert: (json['temperatureHighAlert'] ?? 39.0).toDouble(),
      temperatureLowAlert: (json['temperatureLowAlert'] ?? 35.0).toDouble(),
      fallConfirmationDelay: json['fallConfirmationDelay'] ?? 300,
      sosActivationTime: json['sosActivationTime'] ?? 60000,
      enableAutoCall: json['enableAutoCall'] ?? true,
      sosPhoneNumber: json['sosPhoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'fallDetectionSensitivity': fallDetectionSensitivity,
    'accelerationThreshold': accelerationThreshold,
    'temperatureHighAlert': temperatureHighAlert,
    'temperatureLowAlert': temperatureLowAlert,
    'fallConfirmationDelay': fallConfirmationDelay,
    'sosActivationTime': sosActivationTime,
    'enableAutoCall': enableAutoCall,
    'sosPhoneNumber': sosPhoneNumber,
  };

  ThresholdSettings copyWith({
    double? fallDetectionSensitivity,
    double? accelerationThreshold,
    double? temperatureHighAlert,
    double? temperatureLowAlert,
    int? fallConfirmationDelay,
    int? sosActivationTime,
    bool? enableAutoCall,
    String? sosPhoneNumber,
  }) {
    return ThresholdSettings(
      fallDetectionSensitivity: fallDetectionSensitivity ?? this.fallDetectionSensitivity,
      accelerationThreshold: accelerationThreshold ?? this.accelerationThreshold,
      temperatureHighAlert: temperatureHighAlert ?? this.temperatureHighAlert,
      temperatureLowAlert: temperatureLowAlert ?? this.temperatureLowAlert,
      fallConfirmationDelay: fallConfirmationDelay ?? this.fallConfirmationDelay,
      sosActivationTime: sosActivationTime ?? this.sosActivationTime,
      enableAutoCall: enableAutoCall ?? this.enableAutoCall,
      sosPhoneNumber: sosPhoneNumber ?? this.sosPhoneNumber,
    );
  }
}
