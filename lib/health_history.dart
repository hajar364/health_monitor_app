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
          backgroundColor: Color(0xFF135BEC),
          bottom: const TabBar(
            tabs: [
              Tab(text: "📅 Day"),
              Tab(text: "📊 Week"),
              Tab(text: "📈 Month"),
              Tab(text: "📉 Year"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDayView(),
            _buildWeekView(),
            _buildMonthView(),
            _buildYearView(),
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
          value: "68-74 BPM",
          change: "-2%",
          color: Colors.red,
          description: "Average: 71 BPM | Peak: 98 BPM",
        ),
        const HealthMetricCard(
          title: "Body Temperature",
          value: "36.8-37.8 °C",
          change: "+0.2°C",
          color: Colors.orange,
          description: "Average: 37.3°C | Stable",
        ),
        const HealthMetricCard(
          title: "Blood Pressure",
          value: "115-122 mmHg",
          change: "Stable",
          color: Colors.blue,
          description: "Average: 118/76 | Normal range",
        ),
        const HealthMetricCard(
          title: "Blood Oxygen",
          value: "96-99%",
          change: "+1%",
          color: Colors.purple,
          description: "Average: 97.5% | Excellent",
        ),
        const SizedBox(height: 20),
        const Text("📋 Today's Measurements (Updated 2 min ago)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const MeasurementTile(
          metric: "Heart Rate",
          value: "72 bpm",
          time: "Today, 2:45 PM",
          status: "✅ Normal",
        ),
        const MeasurementTile(
          metric: "Temperature",
          value: "37.6 °C",
          time: "Today, 2:45 PM",
          status: "⚠️ Elevated",
        ),
        const MeasurementTile(
          metric: "Blood Pressure",
          value: "120/78 mmHg",
          time: "Today, 1:30 PM",
          status: "✅ Normal",
        ),
        const MeasurementTile(
          metric: "Blood Oxygen",
          value: "98%",
          time: "Today, 1:30 PM",
          status: "✅ Healthy",
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("📊 Weekly Summary (Last 7 days)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const HealthMetricCard(
          title: "Avg Heart Rate (Weekly)",
          value: "70 BPM",
          change: "-4%",
          color: Colors.red,
          description: "Range: 58-142 BPM | Resting: 62 BPM",
        ),
        const HealthMetricCard(
          title: "Avg Temperature (Weekly)",
          value: "37.0 °C",
          change: "Stable",
          color: Colors.orange,
          description: "Range: 36.4-37.8°C | Normal",
        ),
        const SizedBox(height: 12),
        const Text("Daily Breakdown:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const DailyBreakdownTile(day: "Monday", avg: "71 BPM", status: "Normal"),
        const DailyBreakdownTile(day: "Tuesday", avg: "69 BPM", status: "Normal"),
        const DailyBreakdownTile(day: "Wednesday", avg: "72 BPM", status: "Normal"),
        const DailyBreakdownTile(day: "Thursday", avg: "70 BPM", status: "Normal"),
        const DailyBreakdownTile(day: "Friday", avg: "68 BPM", status: "Good"),
        const DailyBreakdownTile(day: "Saturday", avg: "72 BPM", status: "Normal"),
        const DailyBreakdownTile(day: "Today", avg: "71 BPM", status: "Normal"),
      ],
    );
  }

  Widget _buildMonthView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("📈 Monthly Summary (April 2026)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const HealthMetricCard(
          title: "Avg Heart Rate (Monthly)",
          value: "69 BPM",
          change: "-3%",
          color: Colors.red,
          description: "Improvement from March: +2%",
        ),
        const HealthMetricCard(
          title: "Avg Temperature (Monthly)",
          value: "36.9 °C",
          change: "Stable",
          color: Colors.orange,
          description: "Days with elevated temp: 3",
        ),
        const SizedBox(height: 12),
        const Text("Health Trends:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const StatTile(label: "Active Days", value: "28/30", percentage: 93),
        const StatTile(label: "Days with Alerts", value: "2/30", percentage: 7),
        const StatTile(label: "Heart Health Score", value: "92/100", percentage: 92),
        const StatTile(label: "Temperature Stability", value: "96/100", percentage: 96),
      ],
    );
  }

  Widget _buildYearView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("📉 Yearly Summary (2026)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const HealthMetricCard(
          title: "Avg Heart Rate (YTD)",
          value: "69 BPM",
          change: "↓ -2%",
          color: Colors.red,
          description: "Overall cardiovascular improvement",
        ),
        const SizedBox(height: 12),
        const Text("Monthly Progress:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const MonthlyProgressTile(month: "January", avgHR: "71", temp: "37.2"),
        const MonthlyProgressTile(month: "February", avgHR: "70", temp: "37.0"),
        const MonthlyProgressTile(month: "March", avgHR: "70", temp: "36.9"),
        const MonthlyProgressTile(month: "April (Current)", avgHR: "69", temp: "36.9"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "✨ Great Progress! Your heart health is improving. Keep maintaining your current activity level and monitor temperature regularly.",
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(change,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
        subtitle: Text(time),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(status, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class DailyBreakdownTile extends StatelessWidget {
  final String day;
  final String avg;
  final String status;

  const DailyBreakdownTile({
    super.key,
    required this.day,
    required this.avg,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(day),
        subtitle: Text(avg),
        trailing: Chip(label: Text(status)),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final int percentage;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                color: percentage >= 90 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlyProgressTile extends StatelessWidget {
  final String month;
  final String avgHR;
  final String temp;

  const MonthlyProgressTile({
    super.key,
    required this.month,
    required this.avgHR,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(month, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("HR: $avgHR BPM | Temp: ${temp}°C"),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
