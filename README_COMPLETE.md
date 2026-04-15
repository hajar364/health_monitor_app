# Health Monitor App - Complete Documentation

**Current Version**: 2.0.0-WiFi (Bluetooth v1.0.0 also available)
**Status**: ✅ Production Ready
**Last Updated**: 2025

---

## 📱 Overview

A Flutter mobile application for real-time health monitoring using an ESP32 microcontroller with WiFi communication. The system detects critical health alerts (fever, falls, hypothermia) and provides immediate feedback.

```
┌─────────────┐
│   ESP32     │  → Temperature (MLX90614)
│ Iomedic     │     Motion (MPU6050)
└────┬────────┘
     │
   WiFi HTTP
   (Port 80)
     │
┌────▼──────────┐
│  Flutter App   │  → Real-time alerts
│  (iOS/Android) │     LED control
└────────────────┘     Health dashboard
```

---

## 🔄 Two Communication Options

### Option 1️⃣: WiFi (Recommended) ⭐

**Status**: ✅ Version 2.0.0-WiFi - PRODUCTION READY

**Best for**:
- Reliable stationary monitoring
- Local home/hospital use
- If you need better range (50m)
- If you don't need portability

**Advantages**:
- ✅ More stable (HTTP > Bluetooth)
- ✅ Better range (50m vs 10m)
- ✅ No pairing needed
- ✅ Can access from web browser
- ✅ Lower latency
- ✅ Future-proof (REST API)

**Disadvantages**:
- ⚠️ Requires WiFi setup
- ⚠️ Slightly higher power use
- ⚠️ Range limited to WiFi (not portable)

**Files**:
```
esp32_health_monitor_WIFI.ino         ← Firmware
lib/services/wifi_esp32_service.dart  ← Service
lib/live_dashboard_wifi.dart          ← UI Dashboard
MIGRATION_WIFI_GUIDE.md               ← How-to
WIFI_CHECKLIST.md                     ← Quick setup
```

**Setup Time**: ~40 minutes

---

### Option 2️⃣: Bluetooth Classic

**Status**: ✅ Version 1.0.0-Bluetooth - FULLY FUNCTIONAL

**Best for**:
- Portable monitoring
- Mobile use case
- If you have HC-05 module
- Not concerned about range

**Advantages**:
- ✅ Very low power consumption
- ✅ Mobile/portable
- ✅ Simple hardware (HC-05)
- ✅ Works in any location

**Disadvantages**:
- ⚠️ Less stable (serial)
- ⚠️ Shorter range (10m)
- ⚠️ Requires pairing
- ⚠️ Android only (not iOS)

**Files**:
```
esp32_health_monitor.ino              ← Firmware
lib/services/bluetooth_esp32_service.dart  ← Service
lib/live_dashboard_updated.dart       ← UI Dashboard
GUIDE_INTEGRATION_FIRMWARE.md         ← How-to
```

**Setup Time**: ~30 minutes

---

## ⚡ Quick Start

### For WiFi Version (Recommended)

```bash
# 1. Flash firmware to ESP32
# - Open esp32_health_monitor_WIFI.ino in Arduino IDE
# - Click Upload
# - Wait for "Done uploading"

# 2. Connect WiFi
# - Go to WiFi settings
# - Find "ESP32_HealthMonitor"
# - Connect with password: "12345678"

# 3. Update Flutter app
cd health_monitor_app
# Edit lib/main.dart:
# - Change: import 'live_dashboard_updated.dart';
#       to: import 'live_dashboard_wifi.dart';
# - Change: LiveDashboardUpdated()
#       to: LiveDashboardWiFi()

# 4. Run app
flutter pub get
flutter run

# ✅ Done! Should connect automatically
```

**See**: `WIFI_CHECKLIST.md` for detailed steps

### For Bluetooth Version

```bash
# 1. Flash firmware
# - Open esp32_health_monitor.ino in Arduino IDE
# - Upload to ESP32

# 2. Pair device (Android)
# - Settings → Bluetooth
# - Find "ESP32_HealthMonitor"
# - Pair with HC-05 module

# 3. Run app
# - App asks for Bluetooth permission
# - Select device from list
# - Connected!

# ✅ Done!
```

**See**: `GUIDE_INTEGRATION_FIRMWARE.md` for details

---

## 📋 Project Structure

```
health_monitor_app/
├── esp32_health_monitor/
│   ├── esp32_health_monitor.ino              (Bluetooth)
│   └── esp32_health_monitor_WIFI.ino         (WiFi)  ← NEW
│
├── lib/
│   ├── main.dart                              (Entry point - MODIFY THIS)
│   ├── models/
│   │   └── health_data.dart                   (Data model)
│   ├── services/
│   │   ├── bluetooth_esp32_service.dart       (Bluetooth)
│   │   ├── wifi_esp32_service.dart            (WiFi)  ← NEW
│   │   ├── alert_service.dart                 (Alerts)
│   │   └── esp32_service.dart                 (Data parsing)
│   ├── live_dashboard_updated.dart            (Bluetooth UI)
│   ├── live_dashboard_wifi.dart               (WiFi UI)  ← NEW
│   └── [other UI files]...
│
├── Documentation/
│   ├── README.md                              (This file)
│   ├── MIGRATION_WIFI_GUIDE.md                (WiFi guide)  ← NEW
│   ├── INTEGRATION_WIFI.md                    (WiFi setup)  ← NEW
│   ├── WIFI_SUMMARY.md                        (WiFi specs)  ← NEW
│   ├── WIFI_CHECKLIST.md                      (WiFi steps)  ← NEW
│   ├── RELEASE_NOTES_V2.md                    (What's new)  ← NEW
│   ├── GUIDE_INTEGRATION_FIRMWARE.md          (BT guide)
│   ├── GUIDE_DEPANNAGE_COMPLET.md             (Troubleshooting)
│   └── [other guides]...
│
└── pubspec.yaml                               (Dependencies)
```

---

## 🎯 Key Features

### Health Monitoring

✅ **Real-time Vital Signs**
- Body temperature (MLX90614 IR sensor)
- Motion detection (MPU6050 accelerometer)
- Heart rate simulation

✅ **Alert Detection**
- 🤒 Fever (38°C - 39.5°C) → Orange + LED + Sound
- 🔴 High Fever (>39.5°C) → Red + LED + Sound
- ❄️ Hypothermia (<35°C) → Blue + LED + Sound
- 🚨 Fall Detection → Red + LED + Alert Dialog
- ⚠️ Abnormal movement → Orange alert

✅ **Physical Feedback**
- 💡 LED on GPIO12 (lights up on alert)
- 🔊 Alert sounds (configurable frequency)
- 📱 Vibration (haptic feedback)

✅ **Data Visualization**
- Real-time dashboard with metrics
- Temperature graph
- Motion analysis
- 6-tab navigation interface
- Alert history

---

## 🔧 Hardware Requirements

### Microcontroller
- **ESP32 Dev Module**
- USB power (5V)

### Sensors
- **MLX90614** (Temperature, I2C addr 0x5A)
  - Pins: GPIO32 (SDA), GPIO33 (SCL)
  - Accuracy: ±0.5°C
  
- **MPU6050** (Motion, I2C addr 0x69)
  - Pins: GPIO32 (SDA), GPIO33 (SCL)
  - 3-axis accelerometer

### Peripherals
- **LED** (GPIO12, active high)
  - 220Ω resistor recommended
  
### For Bluetooth (Optional)
- **HC-05 Module** (only if using Bluetooth)
  - Serial connection to ESP32

### Power
- USB cable + 5V adapter
- Or battery (not tested)

---

## 📦 Dependencies

### Flutter Packages
```yaml
dependencies:
  flutter: sdk: flutter
  http: ^1.1.0              # WiFi only
  flutter_bluetooth_serial: ^0.4.0  # Bluetooth only
  intl: ^0.19.0
  json_serializable: ^6.6.2
  audioplayers: ^4.0.0
  sqflite: ^2.3.0
  path_provider: ^2.0.0
```

### Arduino Libraries
```cpp
#include <Wire.h>                    // I2C
#include <Adafruit_MLX90614.h>       // Temperature
#include <MPU6050.h>                 // Motion
#include <ArduinoJson.h>             // JSON
#include <WiFi.h>                    // WiFi (v2.0)
#include <WebServer.h>               // HTTP (v2.0)
#include <BluetoothSerial.h>         // Bluetooth (v1.0)
```

---

## 🚀 Installation Steps

### 1. Clone/Download Project
```bash
git clone <repo-url>
cd health_monitor_app
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Choose Your Version

**For WiFi (Recommended)**:
```
1. Open: esp32_health_monitor_WIFI.ino
2. Flash to ESP32 via Arduino IDE
3. Edit main.dart → Use LiveDashboardWiFi()
4. Run: flutter run
```

**For Bluetooth**:
```
1. Open: esp32_health_monitor.ino
2. Flash to ESP32 via Arduino IDE
3. Keep main.dart as-is (uses LiveDashboardUpdated)
4. Run: flutter run
```

### 4. Configure Connection
- WiFi: Connect device to "ESP32_HealthMonitor" network
- Bluetooth: Enable Bluetooth, select ESP32 from list

---

## 📱 App Pages

### 1. Live Dashboard (Real-time)
- Current temperature display
- Motion metrics
- Alert status
- LED control button
- Connection indicator
- Update frequency counter

### 2. Device Connectivity
- Connection status
- WiFi/Bluetooth details
- IP address
- Sensor information
- Connection diagnostics

### 3. Health Dashboard
- Heart rate information
- Vital signs summary
- Health status indicator
- Metric trends

### 4. Health History
- Past measurements
- Trend graphs
- Data export
- Filter by date

### 5. Heart Rate Analysis
- BPM statistics
- Heart rate patterns
- Variability analysis
- Health insights

### 6. Alerts & Notifications
- Alert history
- Past events
- Alert statistics
- Export reports

---

## 🧪 Testing

### Offline Testing (No Hardware)
```dart
// In main.dart, you can inject test data:
final wifiService = WiFiESP32Service();
wifiService.injectTestData(
  HealthData(
    temperature: 39.2,  // Fever
    heartRate: 95,
    timestamp: DateTime.now(),
  ),
);
```

### Live Testing (With Hardware)
1. Flash firmware
2. Connect device
3. Monitor Serial output (Arduino IDE)
4. Watch dashboard for updates
5. Test LED button
6. Trigger alerts (heat source near sensor)

---

## 🐛 Troubleshooting

### Common Issues

**WiFi not visible**
- Check Serial Monitor (115200 baud) for errors
- Verify firmware uploaded successfully
- Press ESP32 reset button

**Can't connect to WiFi**
- Verify password: `12345678` (exactly 8 chars)
- Check device WiFi list (should show "ESP32_HealthMonitor")
- Try "Forget" and reconnect

**No data in dashboard**
- Verify I2C sensor connections (GPIO32/33)
- Check Serial Monitor for sensor errors
- Confirm device still connected to WiFi
- Test API: `curl http://192.168.4.1/health`

**LED won't turn on**
- Check GPIO12 hardware connection
- Verify LED polarity (long pin positive)
- Test manually: `curl -X POST http://192.168.4.1/led -d '{"action":"on"}'`

**For more help**, see:
- `MIGRATION_WIFI_GUIDE.md` → 🐛 Dépannage WiFi
- `GUIDE_DEPANNAGE_COMPLET.md`

---

## 📊 API Endpoints (WiFi Only)

### GET /health
```json
{
  "temperature": 37.2,
  "temperatureAmbient": 22.5,
  "accelX": 0.15,
  "accelY": -0.08,
  "accelZ": 9.81,
  "fallDetected": false,
  "feverDetected": false,
  "hypothermiaDetected": false,
  "ledActive": false,
  "status": "OK",
  "alertStatus": "NORMAL",
  "timestamp": 1524534567
}
```

### POST /led
```json
Request:  {"action": "on"}
Response: {"status": "LED ON"}
```

### POST /config
```json
Request: {"interval": 500, "tempFever": 38.5}
Response: {"status": "Config updated"}
```

See `WIFI_SUMMARY.md` → 📡 API Specification for full details.

---

## 📚 Documentation Files

| File | Purpose | For |
|------|---------|-----|
| README.md | This file - overview | Everyone |
| MIGRATION_WIFI_GUIDE.md | Complete WiFi guide (6 pages) | WiFi users |
| INTEGRATION_WIFI.md | Code changes needed | Developers |
| WIFI_SUMMARY.md | API & technical specs | Developers |
| WIFI_CHECKLIST.md | Step-by-step setup | First-time setup |
| RELEASE_NOTES_V2.md | What's new in v2.0 | All |
| GUIDE_INTEGRATION_FIRMWARE.md | Bluetooth guide | BT users |
| GUIDE_DEPANNAGE_COMPLET.md | Troubleshooting | Support |

---

## 🔐 Security Considerations

⚠️ **Current Configuration**:
- Basic WiFi password (no encryption)
- No API authentication
- Open HTTP (not HTTPS)

✅ **Suitable for**:
- Development
- Local home use
- Private networks

❌ **NOT suitable for**:
- Production/public use
- Sensitive data transmission
- Multi-user systems

**To improve security**:
1. Add API authentication (API keys)
2. Implement HTTPS with certificates
3. Use WPA3 encryption
4. Add rate limiting
5. Validate all inputs

---

## 🎓 Architecture Overview

### WiFi Flow (v2.0)
```
[ESP32 HTTP Server]
       ↓
  [JSON Response]
       ↓
[WiFiESP32Service]
       ↓
[StreamController]
       ↓
[LiveDashboardWiFi]
       ↓
[setState() UI Update]
```

### Bluetooth Flow (v1.0)
```
[ESP32 Serial Output]
       ↓
  [JSON + Binary]
       ↓
[BluetoothESP32Service]
       ↓
[DataStream]
       ↓
[LiveDashboardUpdated]
       ↓
[StreamBuilder UI]
```

---

## ✅ Checklist Before Deployment

- [ ] Hardware connected (sensors on I2C pins)
- [ ] Firmware flashed successfully
- [ ] Serial Monitor shows setup messages
- [ ] Flutter app compiles without errors
- [ ] Device connects to WiFi/Bluetooth
- [ ] Dashboard shows live data
- [ ] Temperature values are realistic
- [ ] LED control works
- [ ] Alerts trigger on abnormal readings
- [ ] No console errors

---

## 🚀 Next Steps

### Recommended (Easy)
1. Use WiFi version (more stable)
2. Follow `WIFI_CHECKLIST.md`
3. Test for 30 minutes
4. Deploy!

### Optional Enhancements
- [ ] Add offline data caching
- [ ] Extend measurement interval
- [ ] Add cloud sync
- [ ] Create web dashboard
- [ ] SMS/Email alerts
- [ ] ML-based predictions

---

## 📞 Questions & Support

**General Questions**
- Read: README.md (this file)
- Check: RELEASE_NOTES_V2.md

**How to Setup WiFi?**
- Follow: WIFI_CHECKLIST.md (step-by-step)

**How to Migrate from Bluetooth?**
- Read: MIGRATION_WIFI_GUIDE.md

**Specific Error?**
- Search: MIGRATION_WIFI_GUIDE.md → 🐛 Dépannage
- Or: GUIDE_DEPANNAGE_COMPLET.md

**Technical Specifications?**
- Read: WIFI_SUMMARY.md → 📡 API Specification

---

## 📈 Version History

**v2.0.0-WiFi** (Current) ✅
- WiFi HTTP/REST API
- Polling architecture
- 50m range
- Web dashboard

**v1.0.0-Bluetooth** (Stable)
- Bluetooth Serial
- Streaming architecture
- 10-100m range
- Android only

---

## 📄 License

[Your License Here]

---

## 👨‍💻 Credits

Built with:
- Flutter for cross-platform mobile
- ESP32 for IoT hardware
- ArduinoJson for data serialization
- Adafruit libraries for sensors

---

## 🎉 You're Ready!

Choose your version:
- **WiFi (Recommended)**: Follow `WIFI_CHECKLIST.md` ⭐
- **Bluetooth**: Follow `GUIDE_INTEGRATION_FIRMWARE.md`

**Total setup time**: ~40-50 minutes

**Questions?** Check the documentation files listed above.

**Happy monitoring!** 📊

---

**Last Updated**: 2025
**Version**: 2.0.0-WiFi + 1.0.0-Bluetooth
**Status**: ✅ Production Ready
