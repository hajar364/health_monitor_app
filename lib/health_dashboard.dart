import 'package:flutter/material.dart';

class HealthDashboard extends StatelessWidget {
  const HealthDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Pro"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                "Last updated: Just now",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HealthCard(
            icon: Icons.favorite,
            color: Colors.green,
            title: "Heart Rate",
            status: "NORMAL",
            description: "Consistent rhythm",
            value: "72 BPM",
          ),
          HealthCard(
            icon: Icons.thermostat,
            color: Colors.orange,
            title: "Body Temperature",
            status: "WARNING",
            description: "Slightly elevated",
            value: "38.2 °C",
          ),
          HealthCard(
            icon: Icons.directions_walk,
            color: Colors.red,
            title: "Physical Activity",
            status: "ALERT",
            description: "Target not reached",
            value: "500 steps / Goal: 10,000",
          ),
          PhysicianNote(
            note:
                "Your temperature is above normal. Please stay hydrated and rest for the next 4 hours. Re-check in 30 minutes.",
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

class HealthCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String status;
  final String description;
  final String value;

  const HealthCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.status,
    required this.description,
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
                  Text(description,
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
