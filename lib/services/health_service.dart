import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthService {

  static Future<Map<String, dynamic>> getHealthData() async {

    final response = await http.get(
      Uri.parse("http://192.168.1.100/data"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load health data");
    }
  }
}