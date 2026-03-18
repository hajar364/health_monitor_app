import 'package:flutter/material.dart';

class DeviceConnectivity extends StatelessWidget {
  const DeviceConnectivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Connectivity"),
      ),
      body: SingleChildScrollView(   // ✅ Correction : scrollable
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanning progress
            const Text(
              "Scanning for medical devices (10 ft range)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              value: 0.65, // 65% progress
              backgroundColor: Colors.grey,
              color: Colors.blue,
              minHeight: 8,
            ),
            const SizedBox(height: 24),

            // Available Devices
            const Text(
              "Available Devices",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            DeviceTile(
              name: "ESP32 Health Sensor",
              id: "4F:E2:B9:10:94:77",
              status: "Pair",
              buttonColor: Colors.blue,
            ),
            DeviceTile(
              name: "Smart B.P. Monitor",
              id: "2A:C1:99:43:F2:12",
              status: "Wait",
              buttonColor: Colors.grey,
            ),
            DeviceTile(
              name: "MedTemp Pro V2",
              id: "88:5D:12:92:90:11",
              status: "Wait",
              buttonColor: Colors.grey,
            ),

            const SizedBox(height: 24),

            // Pairing Instructions
            const Text(
              "PAIRING INSTRUCTIONS",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("1. Ensure your ESP32 device is in Discovery Mode (blue light blinking)."),
            const Text("2. Select the device from the list above to initiate secure handshake."),
            const Text("3. Accept the pairing request on both phone and device screen if prompted."),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Connect tab active
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: "Connect"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class DeviceTile extends StatelessWidget {
  final String name;
  final String id;
  final String status;
  final Color buttonColor;

  const DeviceTile({
    super.key,
    required this.name,
    required this.id,
    required this.status,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("ID: $id"),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
          onPressed: () {
            // action de pairing
          },
          child: Text(status),
        ),
      ),
    );
  }
}
