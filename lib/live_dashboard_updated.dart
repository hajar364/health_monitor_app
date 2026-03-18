import 'package:flutter/material.dart';

class LiveDashboardUpdated extends StatelessWidget {
  const LiveDashboardUpdated({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Pro")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HealthMetricCard(
            icon: Icons.favorite,
            color: Colors.green,
            title: "Heart Rate",
            status: "NORMAL",
            intensity: "Low Intensity",
            value: "78 BPM",
          ),
          HealthMetricCard(
            icon: Icons.thermostat,
            color: Colors.orange,
            title: "Body Temperature",
            status: "NORMAL",
            intensity: "Low Intensity",
            value: "36.7 °C",
          ),
          HealthMetricCard(
            icon: Icons.directions_walk,
            color: Colors.blue,
            title: "Physical Activity",
            status: "NORMAL",
            intensity: "Low Intensity",
            value: "Level 2 (Scale: 1-10)",
          ),
          PhysicianNote(
            note: "All vitals stable.",
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Dashboard tab active
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: "Records"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class HealthMetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String status;
  final String intensity;
  final String value;

  const HealthMetricCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.status,
    required this.intensity,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              foregroundColor: color,
              radius: 28,
              child: Icon(icon, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(status,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  Text(intensity,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhysicianNote extends StatelessWidget {
  final String note;

  const PhysicianNote({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Physician's Note",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
