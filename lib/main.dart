import 'package:flutter/material.dart';
import 'models/health_data.dart';
import 'services/esp32_service.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF135BEC),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

////////////////////////////////////////////////////////////
/// LOGIN PAGE
////////////////////////////////////////////////////////////

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.medical_services, size: 60, color: Color(0xFF135BEC)),
              const SizedBox(height: 20),
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Log in to monitor your health data",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              TextField(
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                    );
                  },
                  child: const Text("Login"),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Sign Up"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// DASHBOARD PAGE
////////////////////////////////////////////////////////////

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  HealthData? healthData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await ESP32Service.fetchData();
      setState(() {
        healthData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error: $e');
    }
  }

  Widget healthCard(IconData icon, String title, String value, String status, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 20)),
                Text(status, style: TextStyle(color: color, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Dashboard"), backgroundColor: const Color(0xFF135BEC)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  healthCard(
                    Icons.favorite,
                    "Heart Rate",
                    "${healthData!.heartRate} bpm",
                    healthData!.heartRate > 100 ? "High" : "Normal",
                    healthData!.heartRate > 100 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 15),
                  healthCard(
                    Icons.thermostat,
                    "Temperature",
                    "${healthData!.temperature} °C",
                    healthData!.temperature > 37.5 ? "High" : "Normal",
                    healthData!.temperature > 37.5 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 15),
                  healthCard(
                    Icons.directions_walk,
                    "Activity",
                    "${healthData!.steps} steps",
                    healthData!.steps < 5000 ? "Low" : "Good",
                    healthData!.steps < 5000 ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryPage(data: healthData!)),
                      );
                    },
                    child: const Text("View History"),
                  )
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HISTORY PAGE
////////////////////////////////////////////////////////////

class HistoryPage extends StatelessWidget {
  final HealthData data;

  const HistoryPage({super.key, required this.data});

  Widget historyItem(HealthData hd) {
    return Card(
      child: ListTile(
        title: Text("Time: ${DateFormat('yyyy-MM-dd – kk:mm:ss').format(hd.timestamp)}"),
        subtitle: Text("Heart: ${hd.heartRate} bpm   |   Temp: ${hd.temperature} °C   |   Steps: ${hd.steps}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health History"), backgroundColor: const Color(0xFF135BEC)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          historyItem(data),
          // Tu pourras ajouter d'autres données ici si tu as un historique réel
        ],
      ),
    );
  }
}