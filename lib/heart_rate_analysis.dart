import 'package:flutter/material.dart';

class HeartRateAnalysis extends StatelessWidget {
  const HeartRateAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Heart Rate Analysis"),
        backgroundColor: Color(0xFF135BEC),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Current Status Section
          MetricCard(
            title: "❤️ Current Heart Rate",
            value: "72 BPM",
            subtitle: "Resting: 62 BPM (Excellent)",
            color: Colors.red,
            icon: Icons.favorite,
          ),
          MetricCard(
            title: "Daily Average",
            value: "68 BPM",
            subtitle: "Lower than yesterday by 3 BPM",
            color: Colors.blue,
            icon: Icons.trending_down,
          ),
          MetricCard(
            title: "Heart Rate Variability (HRV)",
            value: "58 ms",
            subtitle: "Good recovery | Trending up",
            color: Colors.orange,
            icon: Icons.show_chart,
          ),
          MetricCard(
            title: "Min / Max Today",
            value: "58 / 112 BPM",
            subtitle: "Range: 54 BPM | Normal variation",
            color: Colors.green,
            icon: Icons.equalizer,
          ),
          
          SizedBox(height: 24),
          Text("💪 Heart Rate Zones Distribution",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          
          ZoneTile(
            zone: "🔴 Peak Zone (155+ BPM)",
            duration: "12 min",
            color: Colors.red,
            percentage: 1,
          ),
          ZoneTile(
            zone: "🟠 Cardio Zone (125-154 BPM)",
            duration: "45 min",
            color: Colors.orange,
            percentage: 4,
          ),
          ZoneTile(
            zone: "🟡 Fat Burn (95-124 BPM)",
            duration: "2 hr 15 min",
            color: Colors.amber,
            percentage: 9,
          ),
          ZoneTile(
            zone: "🟢 Light (65-94 BPM)",
            duration: "4 hr 30 min",
            color: Colors.green,
            percentage: 19,
          ),
          ZoneTile(
            zone: "⚪ Rest (0-64 BPM)",
            duration: "16 hr 18 min",
            color: Colors.grey,
            percentage: 67,
          ),
          
          SizedBox(height: 24),
          Text("📊 Daily Resting Heart Rate Trend",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          
          // Mini chart representation
          RHRTrendCard(
            values: ["62", "63", "61", "64", "62", "61", "62"],
            dates: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
          ),
          
          SizedBox(height: 24),
          Text("🩺 Health Assessment",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          
          MedicalInsight(
            icon: Icons.info_outline,
            title: "Excellent Cardiovascular Health",
            insight:
                "Your resting heart rate of 62 BPM is in the excellent range for adults. "
                "The consistent downward trend in recent days indicates improving cardiovascular fitness. "
                "Your HRV of 58ms is healthy, suggesting good autonomic nervous system balance.",
            color: Colors.green,
          ),
          
          MedicalInsight(
            icon: Icons.lightbulb_outline,
            title: "Recommendations",
            insight:
                "• Maintain your current activity level\n"
                "• Continue monitoring daily trends\n"
                "• Stay hydrated (especially with slight temp elevation)\n"
                "• Consider 20-min cardio session to maintain fitness\n"
                "• Schedule follow-up measurement in 2 hours",
            color: Colors.blue,
          ),
          
          SizedBox(height: 12),
          StatComparisonCard(
            metricName: "Resting Heart Rate",
            today: "62 BPM",
            yesterday: "64 BPM",
            week: "62.4 BPM",
            month: "63.1 BPM",
          ),
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
  final IconData? icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    this.icon,
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
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(icon, color: color, size: 28),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ZoneTile extends StatelessWidget {
  final String zone;
  final String duration;
  final Color color;
  final int percentage;

  const ZoneTile({
    super.key,
    required this.zone,
    required this.duration,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(zone, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(duration, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text("$percentage% of day",
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class RHRTrendCard extends StatelessWidget {
  final List<String> values;
  final List<String> dates;

  const RHRTrendCard({
    super.key,
    required this.values,
    required this.dates,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  values.length,
                  (index) => Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(values[index],
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 60,
                        width: 30,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: (int.parse(values[index]) - 50) * 2.0,
                            width: 20,
                            decoration: BoxDecoration(
                              color: Colors.red.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(dates[index],
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Avg: 62 BPM",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text("Range: 61-64",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MedicalInsight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String insight;
  final Color color;

  const MedicalInsight({
    super.key,
    required this.icon,
    required this.title,
    required this.insight,
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
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight,
                style: const TextStyle(fontSize: 12, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class StatComparisonCard extends StatelessWidget {
  final String metricName;
  final String today;
  final String yesterday;
  final String week;
  final String month;

  const StatComparisonCard({
    super.key,
    required this.metricName,
    required this.today,
    required this.yesterday,
    required this.week,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metricName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildComparisonRow("Today", today),
            _buildComparisonRow("Yesterday", yesterday),
            _buildComparisonRow("Weekly Avg", week),
            _buildComparisonRow("Monthly Avg", month),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
