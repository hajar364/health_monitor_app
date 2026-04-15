import 'package:flutter/material.dart';

class AlertsNotifications extends StatelessWidget {
  const AlertsNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts & Notifications"),
        backgroundColor: Color(0xFF135BEC),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Alert Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text("All"),
                    selected: true,
                    onSelected: (value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Critical"),
                    onSelected: (value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Warnings"),
                    onSelected: (value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Info"),
                    onSelected: (value) {},
                  ),
                ],
              ),
            ),
          ),
          
          // Critical Alert
          const AlertCard(
            icon: Icons.priority_high,
            color: Colors.red,
            title: "⚠️ Temperature Alert",
            time: "2 min ago",
            description:
                "🌡️ Body temperature elevated to 37.8°C. Please drink water and rest. Will recheck in 30 minutes.",
            severity: "Critical",
          ),
          
          // Warning Alert - WiFi Connection
          const AlertCard(
            icon: Icons.signal_wifi_off,
            color: Colors.amber,
            title: "📡 WiFi Signal Weak",
            time: "15 min ago",
            description:
                "WiFi connection to ESP32 is weak. Signal strength: -68 dBm. Move closer to device or check interference.",
            severity: "Warning",
          ),
          
          // Info Alert - Measurement Complete
          const AlertCard(
            icon: Icons.check_circle,
            color: Colors.green,
            title: "✅ Measurement Complete",
            time: "32 min ago",
            description:
                "Regular health measurement completed. All values normal. Heart rate: 72 BPM, Temp: 37.2°C",
            severity: "Info",
          ),
          
          // Warning Alert - Battery
          const AlertCard(
            icon: Icons.battery_alert,
            color: Colors.amber,
            title: "🔋 ESP32 Battery Low",
            time: "1 hour ago",
            description:
                "The ESP32 device battery is below 25%. Please power up the device soon to ensure continuous monitoring.",
            severity: "Warning",
          ),
          
          // System Alert
          const AlertCard(
            icon: Icons.update,
            color: Colors.blue,
            title: "🔧 Firmware Update Available",
            time: "Today, 8:30 AM",
            description:
                "New firmware v2.2.0 is available for your ESP32 device. Update includes improved sensor calibration.",
            severity: "System",
          ),
          
          // Recovery Alert
          const AlertCard(
            icon: Icons.favorite,
            color: Colors.green,
            title: "💚 Health Status Improved",
            time: "Yesterday, 6:15 PM",
            description:
                "Temperature has normalized. Your body is recovering well. Continue hydration and rest.",
            severity: "Info",
          ),
          
          // Historical Alert
          const AlertCard(
            icon: Icons.history,
            color: Colors.grey,
            title: "📊 Daily Summary Recorded",
            time: "Yesterday, 11:59 PM",
            description:
                "Daily health summary saved. Average HR: 70 BPM, Avg Temp: 36.9°C. No issues detected.",
            severity: "Archive",
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  final String description;
  final String severity;

  const AlertCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    required this.description,
    required this.severity,
  });

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: widget.color.withOpacity(0.2),
                    foregroundColor: widget.color,
                    radius: 24,
                    child: Icon(widget.icon, size: 28),
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
                                widget.title,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.severity,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: severityColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.time,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (!_expanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 60),
                  child: Text(
                    widget.description,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.description,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.color,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            child: const Text("Action",
                                style: TextStyle(fontSize: 11, color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            child: const Text("Dismiss",
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor() {
    switch (widget.severity) {
      case "Critical":
        return Colors.red;
      case "Warning":
        return Colors.amber;
      case "Info":
        return Colors.green;
      case "System":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
