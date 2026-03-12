class HealthData {
  final int heartRate;
  final double temperature;
  final int steps;
  final DateTime timestamp;

  HealthData({
    required this.heartRate,
    required this.temperature,
    required this.steps,
    required this.timestamp,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      heartRate: json['heart_rate'],
      temperature: (json['temperature'] as num).toDouble(),
      steps: json['steps'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heart_rate': heartRate,
      'temperature': temperature,
      'steps': steps,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}