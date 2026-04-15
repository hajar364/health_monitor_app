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
import 'live_dashboard_wifi.dart';

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
      home: const MainNavigation(),
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
    LiveDashboardWiFi(),
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
