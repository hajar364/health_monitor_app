import 'package:flutter/material.dart';

class HealthHistory extends StatelessWidget {
  const HealthHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Health History"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Day"),
              Tab(text: "Week"),
              Tab(text: "Month"),
              Tab(text: "Year"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDayView(),
            Center(child: Text("Weekly history coming soon")),
            Center(child: Text("Monthly history coming soon")),
            Center(child: Text("Yearly history coming soon")),
          ],
        ),
      ),
    );
  }

  Widget _buildDayView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HealthMetricCard(
          title: "Heart Rate",
          value: "72 BPM",
          change: "-2%",
          color: Colors.red,
          description: "Trend from 12 AM to 6 PM",
        ),
        const HealthMetricCard(
          title: "Body Temperature",
          value: "98.6 °F",
          change: "+0.1%",
          color: Colors.orange,
          description: "Trend from 12 AM to 6 PM",
        ),
        const SizedBox(height: 20),
        const Text("Recent Measurements",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const MeasurementTile(
          metric: "Heart Rate",
          value: "74 bpm",
          time: "Today, 2:45 PM",
          status: "Normal",
        ),
        const MeasurementTile(
          metric: "Temperature",
          value: "98.4 °F",
          time: "Today, 1:15 PM",
          status: "Normal",
        ),
        const MeasurementTile(
          metric: "Blood Pressure",
          value: "118/79",
          time: "Yesterday, 9:00 PM",
          status: "Healthy",
        ),
      ],
    );
  }
}

class HealthMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color color;
  final String description;

  const HealthMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.color,
    required this.description,
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
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(change,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(description,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 80, child: Placeholder()), // Graph placeholder
          ],
        ),
      ),
    );
  }
}

class MeasurementTile extends StatelessWidget {
  final String metric;
  final String value;
  final String time;
  final String status;

  const MeasurementTile({
    super.key,
    required this.metric,
    required this.value,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(metric, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$time • $status"),
        trailing: Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
