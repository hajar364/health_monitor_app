import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/health_data.dart';

class ESP32Service {
  static const String baseUrl = "http://192.168.1.100"; // À remplacer avec ton ESP32

  // Pour tester sans matériel
  static Future<HealthData> fetchData() async {
    await Future.delayed(const Duration(seconds: 1)); // Simule le temps de réponse
    final simulatedJson = '''
    {
      "heart_rate": 72,
      "temperature": 36.6,
      "steps": 8500,
      "timestamp": "${DateTime.now().toIso8601String()}"
    }
    ''';
    return HealthData.fromJson(jsonDecode(simulatedJson));
  }

  // Quand tu auras le matériel, décommente et utilise ceci :
  /*
  static Future<HealthData> fetchData() async {
    final response = await http.get(Uri.parse('$baseUrl/data'));
    if (response.statusCode == 200) {
      return HealthData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load data from ESP32');
    }
  }
  */
}