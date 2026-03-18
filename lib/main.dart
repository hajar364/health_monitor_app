import 'package:flutter/material.dart';
import 'models/health_data.dart';
import 'services/esp32_service.dart';
import 'package:intl/intl.dart';

// Import des 6 nouveaux modules
import 'alerts_notifications.dart';
import 'device_connectivity.dart';
import 'health_dashboard.dart';
import 'health_history.dart';
import 'heart_rate_analysis.dart';
import 'live_dashboard_updated.dart';

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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigation()),
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
/// MAIN NAVIGATION (relie les 6 modules)
////////////////////////////////////////////////////////////

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LiveDashboardUpdated(),
    DeviceConnectivity(),
    HealthDashboard(),
    HealthHistory(),
    HeartRateAnalysis(),
    AlertsNotifications(),
  ];

  final List<String> _titles = const [
    "Live Dashboard",
    "Connectivity",
    "Dashboard",
    "History",
    "Heart Analysis",
    "Alerts",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Live"),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: "Connect"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Heart"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
        ],
      ),
    );
  }
}
