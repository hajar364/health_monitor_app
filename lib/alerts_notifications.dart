import 'package:flutter/material.dart';

class AlertsNotifications extends StatelessWidget {
  const AlertsNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts & Notifications"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          // Critical Alert
          AlertCard(
            icon: Icons.emergency,
            color: Colors.red,
            title: "Heart rate exceeded 100bpm",
            time: "10:45 AM",
            description:
                "Critical alert: Resting heart rate spiked suddenly. Please check patient immediately.",
          ),
          // Warning Alert
          AlertCard(
            icon: Icons.warning,
            color: Colors.amber,
            title: "Blood pressure slightly elevated",
            time: "09:30 AM",
            description:
                "Warning: Sustained high reading (145/95) over the last 15 minutes.",
          ),
          // Info Alert
          AlertCard(
            icon: Icons.check_circle,
            color: Colors.green,
            title: "SpO2 Levels Stabilized",
            time: "08:15 AM",
            description:
                "Recovery detected: Blood oxygen levels have returned to normal range (98%).",
          ),
          // Battery Warning
          AlertCard(
            icon: Icons.battery_alert,
            color: Colors.amber,
            title: "Sensor Battery Low",
            time: "Yesterday",
            description:
                "The wearable IoT device battery is below 15%. Please charge soon to ensure continuous monitoring.",
          ),
          // System Update
          AlertCard(
            icon: Icons.update,
            color: Colors.blue,
            title: "System Update Complete",
            time: "Yesterday",
            description:
                "Health monitoring algorithms have been updated to version 4.2.0.",
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  final String description;

  const AlertCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              foregroundColor: color,
              radius: 24,
              child: Icon(icon, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
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
