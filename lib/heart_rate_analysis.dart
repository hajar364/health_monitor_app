import 'package:flutter/material.dart';

class HeartRateAnalysis extends StatelessWidget {
  const HeartRateAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Heart Rate Analysis")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MetricCard(
            title: "Current Heart Rate",
            value: "72 BPM",
            subtitle: "Resting: 64 BPM (Normal)",
            color: Colors.red,
          ),
          MetricCard(
            title: "AVERAGE",
            value: "68 BPM",
            color: Colors.blue,
          ),
          MetricCard(
            title: "HRV",
            value: "54 ms",
            color: Colors.orange,
          ),
          MetricCard(
            title: "MIN / MAX",
            value: "58 / 142",
            color: Colors.green,
          ),
          MetricCard(
            title: "DAILY TREND",
            value: "-3.2%",
            color: Colors.purple,
          ),
          SizedBox(height: 20),
          Text("Heart Rate Zones",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ZoneTile(zone: "Peak (155+ BPM)", duration: "12 min"),
          ZoneTile(zone: "Cardio (125 - 154 BPM)", duration: "45 min"),
          ZoneTile(zone: "Fat Burn (95 - 124 BPM)", duration: "2 hr 51 min"),
          ZoneTile(zone: "Out of Zone (0 - 64 BPM)", duration: "20 hr 46 min"),
          SizedBox(height: 20),
          Text("Daily Resting Heart Rate",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 80, child: Placeholder()), // Graph placeholder
          SizedBox(height: 20),
          MedicalInsight(
            insight:
                "Your average resting heart rate of 64 BPM is within the healthy adult range. "
                "The recent downward trend suggests improved cardiovascular fitness. "
                "However, your HRV has decreased slightly since yesterday, which might indicate "
                "your body needs more recovery time after your last 'Peak' zone session.",
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Example: first tab active
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Heart"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class ZoneTile extends StatelessWidget {
  final String zone;
  final String duration;

  const ZoneTile({super.key, required this.zone, required this.duration});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(zone),
      trailing: Text(duration,
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class MedicalInsight extends StatelessWidget {
  final String insight;

  const MedicalInsight({super.key, required this.insight});

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
            const Text("Medical Insight",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(insight, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // action pour voir la recommandation complète
              },
              child: const Text("View full recommendation >"),
            )
          ],
        ),
      ),
    );
  }
}
