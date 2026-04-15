# Integration Guide - WiFi Dashboard

## 🚀 Quick Start

### 1. Update main.dart

Remplacer l'import et la route du dashboard:

```dart
// AVANT (Bluetooth)
import 'package:health_monitor_app/live_dashboard_updated.dart';

// APRÈS (WiFi)
import 'package:health_monitor_app/live_dashboard_wifi.dart';

// Dans build(), remplacer:
body: widget.index == 0
    ? LiveDashboardUpdated()  // ❌ OLD
    : LiveDashboardUpdated()  // ❌ OLD

// Par:
body: widget.index == 0
    ? LiveDashboardWiFi()     // ✅ NEW
    : LiveDashboardWiFi()     // ✅ NEW
```

### 2. Installer dépendances

```bash
flutter pub get
# http package devrait être déjà présent
flutter pub add http:^1.1.0
```

### 3. Configuration Android (si nécessaire)

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 4. Flash firmware ESP32

```
Arduino IDE:
1. Ouvrir esp32_health_monitor_WIFI.ino
2. Board: ESP32 Dev Module
3. Upload
4. Vérifier Serial Monitor (115200 baud)
```

### 5. Test

```
1. Connecter téléphone au WiFi "ESP32_HealthMonitor"
2. Lancer app: flutter run
3. Dashboard devrait se connecter automatiquement
4. Vérifier statut en haut à droite
```

---

## 📋 Fichiers à modifier

### main.dart

```dart
import 'package:flutter/material.dart';
import 'package:health_monitor_app/live_dashboard_wifi.dart';  // ← CHANGE
import 'package:health_monitor_app/alerts_notifications.dart';
import 'package:health_monitor_app/device_connectivity.dart';
import 'package:health_monitor_app/health_dashboard.dart';
import 'package:health_monitor_app/health_history.dart';
import 'package:health_monitor_app/heart_rate_analysis.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitor - WiFi',
      theme: ThemeData(
        primaryColor: Color(0xFF135BEC),
        useMaterial3: false,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LiveDashboardWiFi(),              // ← CHANGE (was LiveDashboardUpdated)
          DeviceConnectivity(),
          HealthDashboard(),
          HealthHistory(),
          HeartRateAnalysis(),
          AlertsNotifications(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF135BEC),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Connectivité',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Santé',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Cœur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertes',
          ),
        ],
      ),
    );
  }
}
```

### pubspec.yaml

```yaml
name: health_monitor_app
description: Health monitoring app with ESP32 and WiFi

version: 2.0.0+wifi

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Network
  http: ^1.1.0                    # ← Ensure présent
  
  # JSON
  json_serializable: ^6.6.2
  
  # UI
  intl: ^0.19.0
  
  # Local Storage
  sqflite: ^2.3.0
  path_provider: ^2.0.0
  
  # Bluetooth (garder pour legacy)
  flutter_bluetooth_serial: ^0.4.0
  
  # Audio
  audioplayers: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  json_serializable: ^6.6.2

flutter:
  uses-material-design: true
```

### device_connectivity.dart (Optionnel - enhancer)

Pour montrer la connexion WiFi au lieu de Bluetooth:

```dart
import 'package:flutter/material.dart';
import 'services/wifi_esp32_service.dart';

class DeviceConnectivity extends StatefulWidget {
  @override
  State<DeviceConnectivity> createState() => _DeviceConnectivityState();
}

class _DeviceConnectivityState extends State<DeviceConnectivity> {
  late WiFiESP32Service wifiService;
  bool isConnected = false;
  String wifiSSID = "ESP32_HealthMonitor";
  String wifiIP = "192.168.4.1:80";

  @override
  void initState() {
    super.initState();
    wifiService = WiFiESP32Service();
    _checkConnection();
  }

  void _checkConnection() async {
    bool connected = await wifiService.checkConnection();
    setState(() => isConnected = connected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📡 WiFi Connectivity'),
        backgroundColor: Color(0xFF135BEC),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WiFi Status Card
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 32,
                ),
                title: Text(
                  isConnected ? 'WiFi Connected' : 'WiFi Disconnected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SSID: $wifiSSID'),
                    Text('IP: $wifiIP'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Instructions
            Text(
              'Connection Instructions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _instructionStep(
                      '1',
                      'Go to WiFi Settings',
                      'Android: Settings > WiFi\niOS: Settings > WiFi',
                    ),
                    SizedBox(height: 16),
                    _instructionStep(
                      '2',
                      'Select Network',
                      'Find and tap "ESP32_HealthMonitor"',
                    ),
                    SizedBox(height: 16),
                    _instructionStep(
                      '3',
                      'Enter Password',
                      'Password: 12345678',
                    ),
                    SizedBox(height: 16),
                    _instructionStep(
                      '4',
                      'Confirm Connection',
                      'App will auto-connect to dashboard',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Connection Test
            ElevatedButton.icon(
              onPressed: _checkConnection,
              icon: Icon(Icons.refresh),
              label: Text('Test Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF135BEC),
                minimumSize: Size.fromHeight(50),
              ),
            ),

            SizedBox(height: 20),

            // ESP32 Info
            Text(
              'ESP32 Hardware Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Firmware', 'v1.0.0-WiFi'),
                    Divider(),
                    _infoRow('WiFi MAC', 'AA:BB:CC:DD:EE:FF'),
                    Divider(),
                    _infoRow('Temperature Sensor', 'MLX90614'),
                    Divider(),
                    _infoRow('Motion Sensor', 'MPU6050'),
                    Divider(),
                    _infoRow('Communication', 'HTTP REST'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructionStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF135BEC),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(description, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700])),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  void dispose() {
    wifiService.dispose();
    super.dispose();
  }
}
```

---

## ✅ Validation List

- [ ] main.dart imports updated
- [ ] main.dart navigator uses LiveDashboardWiFi
- [ ] pubspec.yaml has http package
- [ ] Android manifest has INTERNET permission
- [ ] Firebase/pubspec.lock updated
- [ ] esp32_health_monitor_WIFI.ino flashed
- [ ] Flutter app compiled without errors
- [ ] Device connected to WiFi "ESP32_HealthMonitor"
- [ ] Dashboard shows connection status
- [ ] Data polling every 500ms
- [ ] Alerts triggered correctly
- [ ] LED toggles from UI

---

## 🐛 Common Issues

### "http" package not found

```bash
flutter pub get
flutter pub add http
```

### ESP32 WiFi not appearing

```
1. Check Serial Monitor for errors
2. Verify GPIO32/33 I2C connections
3. Ensure power supply 5V+
4. Reboot ESP32
```

### App crashes on LiveDashboardWiFi

```
1. Check imports in main.dart
2. Ensure HealthData has fromJsonWiFi
3. Check WiFiESP32Service path
4. Run: flutter clean && flutter pub get
```

### No data updates

```
1. Verify device connected to ESP32_HealthMonitor WiFi
2. Check Serial Monitor logs
3. Test API manually: curl http://192.168.4.1/health
4. Verify poll interval 500ms not too fast
```

---

## 📁 New File Structure

```
lib/
├── main.dart (modified)
├── models/
│   └── health_data.dart (modified: added fromJsonWiFi)
├── services/
│   ├── wifi_esp32_service.dart ✨ NEW
│   ├── bluetooth_esp32_service.dart (kept for legacy)
│   ├── alert_service.dart (unchanged)
│   └── health_service.dart
├── live_dashboard_wifi.dart ✨ NEW
├── live_dashboard_updated.dart (kept for legacy)
├── device_connectivity.dart (can update with WiFi info)
└── ...

esp32_health_monitor/
└── esp32_health_monitor_WIFI.ino ✨ NEW

Documentation/
├── MIGRATION_WIFI_GUIDE.md ✨ NEW
└── INTEGRATION_WIFI.md ✨ NEW (this file)
```

---

## 🎯 Next Steps

1. **Immediate**: Update main.dart and Flash firmware
2. **Testing**: Verify WiFi connection and data flow
3. **Optional Enhancements**:
   - Add offline mode (cache data locally)
   - Improve connectivity UI
   - Add data export (CSV/PDF)
   - Cloud sync (Firestore)

---

**Version**: 2.0.0-WiFi
**Status**: ✅ Ready to Deploy
