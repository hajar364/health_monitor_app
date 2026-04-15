import 'package:flutter/material.dart';

class DeviceConnectivity extends StatelessWidget {
  const DeviceConnectivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WiFi Connectivity"),
        backgroundColor: Color(0xFF135BEC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESP32 Status Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.green, size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "✅ Connected to ESP32",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              "WiFi AP: ESP32_HealthMonitor",
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow("IP Address:", "192.168.4.1"),
                    _buildInfoRow("Signal Strength:", "89% (-51 dBm)"),
                    _buildInfoRow("Data Rate:", "72 Mbps"),
                    _buildInfoRow("Connection Time:", "2 hours 45 min"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Device Information
            const Text(
              "ESP32 Device Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildDeviceInfo("Device Name:", "ESP32_HealthMonitor"),
                    _buildDeviceInfo("Firmware Version:", "v2.1.0"),
                    _buildDeviceInfo("MAC Address:", "48:E7:29:A4:21:74"),
                    _buildDeviceInfo("Uptime:", "72 hours 15 minutes"),
                    _buildDeviceInfo("Free Memory:", "156 KB"),
                    _buildDeviceInfo("Sensor Type:", "Multi-parameter IoT"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Network Stats
            const Text(
              "Network Statistics",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildStatRow("Total Data Sent:", "2.4 MB"),
                    _buildStatRow("Total Data Received:", "18.7 MB"),
                    _buildStatRow("Packets Lost:", "0.2%"),
                    _buildStatRow("Average Ping:", "12 ms"),
                    _buildStatRow("Current Bandwidth:", "145 KB/s"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Connection Instructions
            const Text(
              "WiFi Connection Setup",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "1. Ensure ESP32 device is powered on\n"
              "2. Look for WiFi network: ESP32_HealthMonitor\n"
              "3. No password required to connect\n"
              "4. App will auto-detect and connect\n"
              "5. Make sure device is within 30m range",
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),

            // Troubleshooting
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "⚠️ Troubleshooting",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "• Can't find WiFi? Restart the ESP32\n"
                    "• Connection drops? Check power supply\n"
                    "• Slow response? Move closer to device\n"
                    "• Need factory reset? Long press button 5sec",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, 
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
