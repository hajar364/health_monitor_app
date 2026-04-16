// Profil patient
class PatientProfile {
  final String id;
  final String name;
  final int age;
  final double height;      // cm
  final double weight;      // kg
  final String emergencyContact;  // Nom
  final String emergencyPhone;    // Numéro
  final List<String> medicalConditions;
  final DateTime registeredDate;
  final bool isActive;

  PatientProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.emergencyContact,
    required this.emergencyPhone,
    this.medicalConditions = const [],
    required this.registeredDate,
    this.isActive = true,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      age: json['age'] ?? 0,
      height: (json['height'] ?? 170).toDouble(),
      weight: (json['weight'] ?? 70).toDouble(),
      emergencyContact: json['emergencyContact'] ?? '',
      emergencyPhone: json['emergencyPhone'] ?? '',
      medicalConditions: List<String>.from(json['medicalConditions'] ?? []),
      registeredDate: DateTime.parse(
        json['registeredDate'] ?? DateTime.now().toIso8601String()
      ),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'height': height,
    'weight': weight,
    'emergencyContact': emergencyContact,
    'emergencyPhone': emergencyPhone,
    'medicalConditions': medicalConditions,
    'registeredDate': registeredDate.toIso8601String(),
    'isActive': isActive,
  };

  String getDisplayName() => '$name ($age ans)';
}
