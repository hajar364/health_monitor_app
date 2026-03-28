# 🏥 Health Monitor - IoT Distributed Health Surveillance System

> Real-time health monitoring with local AI decision explainability

![Status](https://img.shields.io/badge/Status-Development-yellow) ![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue) ![License](https://img.shields.io/badge/License-MIT-green)

---

## 📋 Project Overview

**Health Monitor** is a distributed IoT system that:
- 🚀 Collects real-time health metrics (heart rate, temperature, physical activity)
- 📊 Analyzes data locally on ESP32 microcontroller
- 🔍 Detects anomalies with **explainable AI** (why the alert occurred)
- 📱 Streams data to Flutter mobile application
- ⚡ Provides immediate visual feedback (LED alerts + app notifications)

**Key Philosophy:** Decisions are made locally on the device → transparency in why alerts happen

---

## 📊 Project Status

| Component | Status | Coverage |
|-----------|--------|----------|
| **Flutter UI** | ✅ Complete | 6 pages fully designed & functional |
| **Service Layer** | ✅ Ready | ESP32Service + HealthData models |
| **Hardware Setup** | 📋 Documented | Guides for safe assembly |
| **ESP32 Code** | ✅ Ready | Arduino firmware with anomaly detection |
| **Real-time Data** | ⚠️ Simulated | Tests work, ESP32 not yet connected |
| **Data Persistence** | ❌ Missing | No historical storage yet |
| **Charts/Graphs** | ❌ Missing | UI ready, implementation pending |

**Progress:** ~60% Frontend UI completed | 20% Backend logic ready | 20% Hardware integration docs

---

## 🎯 What's Developed

### ✅ Frontend (Flutter)

**6 Functional Pages:**

1. **Live Dashboard** (`live_dashboard_updated.dart`)
   - Real-time vital signs display
   - Heart rate, temperature, activity level
   - Status indicators (Normal/Warning/Critical)
   - Physician notes

2. **Device Connectivity** (`device_connectivity.dart`)
   - Bluetooth device scanning
   - Connection status display
   - Pairing instructions

3. **Health Dashboard** (`health_dashboard.dart`)
   - Aggregated health overview
   - Color-coded status cards
   - Real-time updates

4. **Health History** (`health_history.dart`)
   - Tabbed interface (Day/Week/Month/Year)
   - Historical trend analysis
   - ⚠️ *Tabs scaffolded, data views TODO*

5. **Heart Rate Analysis** (`heart_rate_analysis.dart`)
   - HR zones (Peak, Cardio, Fat Burn, Out of Zone)
   - Daily trends
   - Medical insights
   - Graph placeholder

6. **Alerts & Notifications** (`alerts_notifications.dart`)
   - Alert history log
   - Critical/Warning/Info severity levels
   - Timestamp tracking

**Navigation:** Single unified bottom navigation bar (6 tabs)

### ⚙️ Services & Models

#### `ESP32Service` ✅ Updated
```dart
✓ Bluetooth data streaming
✓ JSON parsing from ESP32
✓ Test data injection
✓ Connection status tracking
```

#### `HealthData` Model ✅ Extended
```dart
✓ heartRate (double)
✓ temperature (double)
✓ humidity (double)
✓ accelX/Y/Z (acceleration data)
✓ status (HealthStatus enum)
✓ reason (anomaly explanation)
✓ timestamp
```

#### `HealthService` ⚠️ Basic
```dart
⚡ HTTP fetch from ESP32 API
⚠️ Needs integration with real device
```

### 🔧 Hardware Documentation ✅

Complete guides included:
- `GUIDE_MONTAGE_SECURISE.md` - 40+ page setup guide
- `MONTAGE_VISUEL_BREADBOARD.md` - Step-by-step assembly
- `CONFIGURATION_FINALE.md` - Software configuration
- `GUIDE_DEPANNAGE_COMPLET.md` - Troubleshooting

### 💾 Arduino Code ✅

Complete ESP32 firmware:
- `esp32_health_monitor/esp32_health_monitor.ino`
- Real-time sensor acquisition (1Hz loop)
- Local anomaly detection with explanations
- JSON formatting for mobile app
- Configurable thresholds

---

## ❌ What's Missing

### 🔴 High Priority

| Feature | Impact | Effort |
|---------|--------|--------|
| **Real ESP32 Connection** | Core functionality | Medium |
| **Data Persistence** | Can't track history | High |
| **Status Sync** | UI not connected to real data | Low |

### 🟠 Medium Priority

| Feature | Impact | Effort |
|---------|--------|--------|
| **Charts/Graphs** | Trends not visualized | High |
| **Historical Views** | Week/Month/Year empty | Medium |
| **Bluetooth Pairing UI** | Manual only now | Low |

### 🟡 Low Priority

| Feature | Impact | Effort |
|---------|--------|--------|
| **Settings/Calibration** | Thresholds hardcoded | Low |
| **Data Export** | Can't backup data | Medium |
| **Offline Mode** | Always needs connection | Medium |

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────┐
│               MOBILE APP (Flutter)                     │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 6 Pages (Dashboard, History, Alerts, etc)       │  │
│  └──────────┬───────────────────────────────────────┘  │
│             │                                           │
│  ┌──────────V───────────────────────────────────────┐  │
│  │ Service Layer                                    │  │
│  │ - ESP32Service (Bluetooth/JSON parsing)          │  │
│  │ - HealthService (HTTP fetch)                     │  │
│  │ - HealthData model                               │  │
│  └──────────┬───────────────────────────────────────┘  │
└─────────────┼──────────────────────────────────────────┘
              │ Bluetooth/HTTP
              │
    ┌─────────V──────────────┐
    │  ESP32 Microcontroller │
    │  ┌────────────────────┐│
    │  │ Sensor Acquisition ││  (1Hz loop)
    │  ├────────────────────┤│
    │  │ Anomaly Detection  ││  (with explanations)
    │  ├────────────────────┤│
    │  │ JSON Formatting    ││
    │  ├────────────────────┤│
    │  │ Alert Generation   ││
    │  └────────────────────┘│
    └───┬────────────────────┘
        │
    ┌───┴─────────────────────┐
    │    SENSORS              │
    │ • KY-039 (Heart Rate)   │
    │ • DHT22 (Temp/Humidity) │
    │ • MPU6050 (Acceleration)│
    │ • LED Alert             │
    └────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+
- Arduino IDE (for ESP32 firmware)
- Android device for testing

### Installation

1. **Clone & Setup Flutter**
   ```bash
   cd f:\FINAL\health_monitor_app
   flutter pub get
   ```

2. **Compile & Run**
   ```bash
   flutter run -d R58T90QBQMM
   ```

3. **Current State**
   - ✅ UI displays correctly
   - ✅ Navigation works
   - ⚠️ Data is simulated (not from ESP32 yet)
   - ❌ No persistent storage

---

## 📁 Project Structure

```
health_monitor_app/
├── README.md (this file)
├── README_SETUP.md (hardware setup guide)
├── 📄 Documentation/
│   ├── GUIDE_MONTAGE_SECURISE.md
│   ├── MONTAGE_VISUEL_BREADBOARD.md
│   ├── CONFIGURATION_FINALE.md
│   ├── GUIDE_DEPANNAGE_COMPLET.md
│   ├── INDEX_COMPLET.md
│   └── QUICKSTART.md
│
├── 💾 esp32_health_monitor/
│   └── esp32_health_monitor.ino (Arduino firmware)
│
├── 📱 lib/
│   ├── main.dart (app entry, MainNavigation)
│   ├── models/
│   │   └── health_data.dart (data model with status)
│   ├── services/
│   │   ├── esp32_service.dart (Bluetooth/JSON)
│   │   └── health_service.dart (HTTP fetch)
│   ├── [6 page files]
│   │   ├── live_dashboard_updated.dart
│   │   ├── device_connectivity.dart
│   │   ├── health_dashboard.dart
│   │   ├── health_history.dart
│   │   ├── heart_rate_analysis.dart
│   │   └── alerts_notifications.dart
│   └── [platform folders]
│
├── pubspec.yaml
└── [Android/iOS/Web/Desktop configs]
```

---

## 🔄 Data Flow

```
Real Scenario (when ESP32 connected):
Sensors → ESP32 → JSON → Bluetooth → Flutter App → UI
                                     ↓
                              HealthService
                                     ↓
                              Display data
                              Save history
                              Show alerts

Current State (simulated):
Test Data → Flutter Service → Mock JSON → UI
```

---

## 💡 Key Concepts

### Local Anomaly Detection
Each alert includes a **reason** explaining why it was raised:
```
"TACHYCARDIA (FC > 120 BPM)" 
"FEVER (Temperature > 38°C)"
"INACTIVITY PROLONGED"
```

This happens **on-device** (ESP32), not on server → better privacy & latency

### Configurable Thresholds
Modify anomaly detection in ESP32 firmware:
```cpp
#define HEART_RATE_MIN 40
#define HEART_RATE_MAX 120
#define TEMP_FEVER_MIN 38.0
```

### Health Status Enum
```dart
enum HealthStatus { normal, warning, alert }
```

---

## 🧪 Testing Current Build

1. **Run the app:**
   ```bash
   flutter run -d R58T90QBQMM
   ```

2. **Test navigation:**
   - All 6 tabs should be accessible
   - Data displays (simulated values)
   - No crashes

3. **Simulated alerts:**
   - Check `AlertsNotifications` page
   - Demonstrates alert styling

**Note:** Real ESP32 data not connected yet

---

## 🔗 Next Steps (Priority Order)

### Phase 1: Connect Real Data
- [ ] Implement Bluetooth connection in `ESP32Service`
- [ ] Test with real ESP32 device
- [ ] Verify data parsing

### Phase 2: Persistence
- [ ] Add Hive/SQLite for historical data
- [ ] Implement data save in `HealthService`
- [ ] Display history in Week/Month/Year tabs

### Phase 3: Visualization
- [ ] Add charts library (fl_chart)
- [ ] Plot heart rate trends
- [ ] Display temperature history

### Phase 4: Polish
- [ ] Settings page for threshold calibration
- [ ] Data export functionality
- [ ] Offline mode support

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `GUIDE_MONTAGE_SECURISE.md` | Complete system overview & safety |
| `MONTAGE_VISUEL_BREADBOARD.md` | Step-by-step hardware assembly |
| `CONFIGURATION_FINALE.md` | Software setup & calibration |
| `GUIDE_DEPANNAGE_COMPLET.md` | Troubleshooting common issues |
| `INDEX_COMPLET.md` | Navigation guide for all docs |
| `QUICKSTART.md` | 15-minute fast track |

👉 **Start here:** `INDEX_COMPLET.md` for hardware setup

---

## 🛠️ Development Guidelines

### Code Organization
- **Pages** (lib/): UI layer only, stateless when possible
- **Services** (lib/services/): Business logic & API calls
- **Models** (lib/models/): Data structures

### Widget Naming
- Stateless widgets: `PascalCase`
- Private widgets: `_PascalCase`
- Constants: `camelCase`

### Data Flow
```
Sensor → ESP32 → JSON → Service → Model → Widget
```

---

## 🐛 Known Issues

| Issue | Workaround | Priority |
|-------|-----------|----------|
| Real-time updates missing | Simulated data works | 🔴 |
| History tabs empty | Scaffold present | 🟠 |
| No persistence | In-memory only | 🔴 |
| No graphs | UI ready for charts | 🟠 |

---

## 📝 License

MIT License - See LICENSE file

---

## 👥 Contributing

To continue development:

1. **For ESP32 integration:**
   - Review `esp32_health_monitor.ino`
   - Use guides in documentation/
   - Test with real hardware

2. **For Flutter features:**
   - Add to respective page file
   - Update `HealthData` model if needed
   - Test on Android device

3. **For new sensors:**
   - Update Arduino firmware
   - Extend `HealthData` model
   - Add new UI section

---

## 📞 Quick Reference

**Current State:**
- ✅ Interface complete & functional
- ⚠️ Data simulated (not from ESP32)
- ❌ No history persistence
- ❌ No charts yet

**To Add Next:**
1. Connect real Bluetooth ESP32
2. Add SQLite for history
3. Add charts for visualization

**Documentation:**
- Hardware setup: `GUIDE_MONTAGE_SECURISE.md`
- Quick start: `QUICKSTART.md`
- Troubleshooting: `GUIDE_DEPANNAGE_COMPLET.md`

---

## 🎯 Project Goals

✅ Real-time health monitoring  
✅ Local anomaly detection  
✅ User-friendly interface  
⏳ Historical data tracking  
⏳ Advanced analytics  

---

**Last Updated:** March 28, 2026  
**Version:** 0.6.0 (WIP)  
**Maintainer:** Health Monitor Team

---

*Built with Flutter + ESP32 + IoT Best Practices*
