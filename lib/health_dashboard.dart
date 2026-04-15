import 'package:flutter/material.dart';

class HealthDashboard extends StatelessWidget {
  const HealthDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Dashboard"),
        backgroundColor: Color(0xFF135BEC),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                "Updated: 2 min ago",
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Heart Rate Card
          HealthCard(
            icon: Icons.favorite,
            color: Colors.red,
            title: "Heart Rate",
            status: "✅ NORMAL",
            description: "Regular rhythm detected",
            value: "72 BPM",
            trend: "↓ -3 BPM",
          ),
          
          // Body Temperature Card
          HealthCard(
            icon: Icons.thermostat,
            color: Colors.orange,
            title: "Body Temperature",
            status: "⚠️ WARNING",
            description: "Slightly elevated",
            value: "37.8 °C",
            trend: "↑ +0.5 °C",
          ),
          
          // Blood Pressure Card
          HealthCard(
            icon: Icons.favorite_border,
            color: Colors.blue,
            title: "Blood Pressure",
            status: "✅ NORMAL",
            description: "Systolic/Diastolic reading",
            value: "118 / 78 mmHg",
            trend: "→ Stable",
          ),
          
          // SpO2 Card
          HealthCard(
            icon: Icons.cloud,
            color: Colors.purple,
            title: "Blood Oxygen (SpO2)",
            status: "✅ NORMAL",
            description: "Oxygen saturation level",
            value: "98%",
            trend: "↑ +1%",
          ),
          
          // Physical Activity Card
          HealthCard(
            icon: Icons.directions_walk,
            color: Colors.green,
            title: "Daily Activity",
            status: "✅ GOOD",
            description: "Goal progress: 78%",
            value: "7,800 steps",
            trend: "Target: 10,000",
          ),
          
          // Summary Note
          PhysicianNote(
            icon: Icons.info,
            title: "Today's Summary",
            note:
                "All vital signs are within normal range. Your body temperature is slightly elevated—stay hydrated and monitor for the next hour. Continue your current activity level. No medications taken today as per schedule.",
            color: Colors.blue,
          ),
          
          // Alert Box if needed
          PhysicianNote(
            icon: Icons.warning,
            title: "⚠️ Action Required",
            note:
                "Temperature trending upward. Recommended: Drink water, rest 30 minutes, then recheck. Contact physician if > 38.5°C or if symptoms develop.",
            color: Colors.orange,
          ),
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
  final String trend;

  const HealthCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.status,
    required this.description,
    required this.value,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 32,
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
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
  final IconData icon;
  final String title;
  final String note;
  final Color color;

  const PhysicianNote({
    super.key,
    required this.icon,
    required this.title,
    required this.note,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
