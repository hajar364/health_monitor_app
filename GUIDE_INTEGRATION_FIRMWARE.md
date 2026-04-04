# Guide d'Intégration: Flutter + Firmware ESP32

## 🎯 Objectif

Adapter le code Flutter pour communiquer avec le firmware ESP32 qui sort les données au format:
```
=== Mesures ===
Température: Amb=26.71 °C | Obj=27.91 °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.
```

---

## 📦 Dépendances Requises

Ajouter à `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Communication Bluetooth
  flutter_bluetooth_serial: ^0.4.3
  
  # JSON parsing
  json_serializable: ^6.6.0
  json_annotation: ^4.8.1
  
  # Base de données locale
  sqflite: ^2.0.0
  path: ^1.8.0
  
  # Persistence config
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  build_runner: ^2.3.0
  json_serializable: ^6.6.0
```

**Installation:**
```bash
flutter pub get
```

---

## 🗂️ Structure des Fichiers Créés

```
lib/
├── services/
│   ├── esp32_service.dart              ✅ Service principal (MODIFIÉ)
│   ├── esp32_firmware_adapter.dart     ✨ NOUVEAU - Parser firmware
│   ├── bluetooth_esp32_service.dart    ✨ NOUVEAU - Gestion Bluetooth
│   └── health_service.dart
├── models/
│   └── health_data.dart
└── live_dashboard_updated.dart         (À adapter)
```

---

## 🔄 Flow d'Intégration

### 1. **Réception Bluetooth**
```
ESP32 (Serial)
    ↓
HC-05 Bluetooth Module
    ↓
Flutter (BluetoothESP32Service)
    ↓
ESP32FirmwareAdapter (Parser)
    ↓
HealthData Model
    ↓
StreamController → UI
```

### 2. **Traitement des Données**

```dart
// Dans le firmware, l'ESP32 envoie:
=== Mesures ===
Température: Amb=26.71 °C | Obj=27.91 °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.

// Flutter parse et convertit:
ESP32FirmwareAdapter.parseSerialOutput(serialData)
  ↓
Extrait: temperature=27.91, irValue=0, accelX=0, ...
  ↓
Conversion: accel → G, IR/RED → FC estimée
  ↓
Retourne: HealthData(heartRate=68.5, temperature=27.91, status=normal, reason="NORMAL")
```

---

## 💻 Code d'Exemple: Intégration dans Device Connectivity

### Avant (device_connectivity.dart):
```dart
class DeviceConnectivity extends StatelessWidget {
  // Affichait liste statique
}
```

### Après (device_connectivity.dart):
```dart
import 'package:health_monitor_app/services/bluetooth_esp32_service.dart';

class DeviceConnectivity extends StatefulWidget {
  @override
  State<DeviceConnectivity> createState() => _DeviceConnectivityState();
}

class _DeviceConnectivityState extends State<DeviceConnectivity> {
  BluetoothESP32Service? _bluetoothService;
  List<BluetoothDevice> _availableDevices = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _bluetoothService = BluetoothESP32Service();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await _bluetoothService!.getAvailableDevices();
      setState(() => _availableDevices = devices);
    } catch (e) {
      print('Erreur: $e');
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothService!.connectToESP32(device.address);
      setState(() => _isConnected = true);
      
      // Afficher toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecté à ${device.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivité Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _availableDevices.length,
        itemBuilder: (context, index) {
          final device = _availableDevices[index];
          return ListTile(
            title: Text(device.name ?? 'Appareil'),
            subtitle: Text(device.address),
            trailing: _isConnected 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.bluetooth),
            onTap: () => _connectToDevice(device),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService?.dispose();
    super.dispose();
  }
}
```

---

## 📊 Code d'Exemple: Affichage temps réel

### Dans live_dashboard_updated.dart:

```dart
import 'package:health_monitor_app/services/bluetooth_esp32_service.dart';

class LiveDashboardUpdated extends StatefulWidget {
  @override
  State<LiveDashboardUpdated> createState() => _LiveDashboardUpdatedState();
}

class _LiveDashboardUpdatedState extends State<LiveDashboardUpdated> {
  final BluetoothESP32Service _bluetoothService = BluetoothESP32Service();
  HealthData? _currentData;

  @override
  void initState() {
    super.initState();
    // Écouter les mises à jour données
    _bluetoothService.healthDataStream.listen((data) {
      setState(() => _currentData = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('En attente de données...')
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fréquence cardiaque
        HealthMetricCard(
          title: 'Fréquence Cardiaque',
          value: '${_currentData!.heartRate.toStringAsFixed(1)} BPM',
          unit: 'bpm',
          icon: Icons.favorite,
          status: _currentData!.status,
        ),
        
        // Température
        HealthMetricCard(
          title: 'Température',
          value: '${_currentData!.temperature.toStringAsFixed(2)}°C',
          unit: '°C',
          icon: Icons.thermostat,
          status: _currentData!.status,
        ),
        
        // Accélération
        HealthMetricCard(
          title: 'Activité Physique',
          value: _currentData!.accelMagnitude.toStringAsFixed(2),
          unit: 'g',
          icon: Icons.directions_run,
          status: _currentData!.status,
        ),
        
        // Raison/Explication
        if (_currentData!.reason.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raison:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_currentData!.reason),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}
```

---

## 🧪 Test: Mode Simulé

Pour tester **sans ESP32 physique**:

```dart
// À ajouter dans esp32_service.dart
class ESP32Service {
  bool simulateMode = true;  // Basculer false pour mode réel
  
  Future<void> simulateIncomingFirmwareData() async {
    if (!simulateMode) return;
    
    // Simuler la sortie du firmware
    final sampleData = '''=== Mesures ===
Température: Amb=26.71 °C | Obj=37.91 °C
MAX30100: IR=45000 | RED=40000
MPU6050: Accel[X=100 Y=50 Z=16384] Gyro[X=100 Y=50 Z=100]
⚠️ Alerte : LED allumée !''';
    
    await Future.delayed(Duration(seconds: 2));
    parseAndProcessData(sampleData);
  }
}
```

### Test complet:
```dart
void main() {
  testWidgets('Parse firmware output correctly', (WidgetTester tester) async {
    final service = ESP32Service();
    
    final sampleData = '''=== Mesures ===
Température: Amb=26.71 °C | Obj=38.5 °C
MAX30100: IR=45000 | RED=40000
MPU6050: Accel[X=100 Y=50 Z=16384] Gyro[X=100 Y=50 Z=100]
⚠️ Alerte : LED allumée !''';
    
    HealthData? result;
    service.streamBluetoothData().listen((data) {
      result = data;
    });
    
    service.parseAndProcessData(sampleData);
    await Future.delayed(Duration(milliseconds: 500));
    
    expect(result?.temperature, 38.5);
    expect(result?.status, HealthStatus.alert);
  });
}
```

---

## 🔧 Modifications Minimales Requises

### 1. **pubspec.yaml** - Ajouter dépendances
```yaml
flutter_bluetooth_serial: ^0.4.3
```

### 2. **AndroidManifest.xml** - Permissions Bluetooth
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

### 3. **Info.plist** (iOS) - Permissions Bluetooth
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Cette app utilise Bluetooth pour se connecter aux capteurs ESP32</string>
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>
```

---

## 🚀 Étapes d'Implémentation

### Phase 1: Préparation (2h)
- [ ] Créer esp32_firmware_adapter.dart
- [ ] Modifier esp32_service.dart
- [ ] Ajouter dépendances pubspec.yaml
- [ ] Configurer permissions Android/iOS

### Phase 2: Bluetooth (3h)
- [ ] Créer bluetooth_esp32_service.dart
- [ ] Tester connexion à HC-05
- [ ] Valider réception données

### Phase 3: Intégration UI (4h)
- [ ] Adapter device_connectivity.dart
- [ ] Adapter live_dashboard_updated.dart
- [ ] Tester affichage temps réel
- [ ] Implémenter fallback simulation

### Phase 4: Tests (3h)
- [ ] Tests unitaires parsing
- [ ] Tests E2E avec ESP32 physique
- [ ] Gestion erreurs reconnexion
- [ ] Performance latence

**Total: 12h implémentation**

---

## 📝 Checklist Validation

- [ ] **Parsing JSON✅ & Firmware✅** - Deux formats reconnus
- [ ] **Conversion unités** - IR/RED → FC, accel raw → G
- [ ] **Gestion nulls** - MLX OK, MAX30100 défaillant, MPU6050 défaillant
- [ ] **Stream temps réel** - <500ms latence
- [ ] **Reconnexion auto** - Après déconnexion
- [ ] **Fallback simulation** - Pour tests sans matériel

---

## 🐛 Dépannage

### Problème: "MAX30100: IR=0 | RED=0"
**Cause:** MAX30100 non initialisé ou doigt absent
**Solution:** Vérifier câblage I2C, ajouter pull-ups 10kΩ

### Problème: "MPU6050: Accel[X=0 Y=0 Z=0]"
**Cause:** MPU6050 non initialisé
**Solution:** Vérifier I2C, valider adresse 0x69, calibrer gyro

### Problème: Pas de connexion Bluetooth
**Cause:** HC-05 non appairé
**Solution:** Appairer via paramètres Android, puis scanner

### Problème: Latence élevée
**Cause:** Buffer accumulation
**Solution:** Augmenter baud rate à 230400, réduire taille messages

---

## 📚 Ressources

- **Flutter Bluetooth Serial:** https://pub.dev/packages/flutter_bluetooth_serial
- **ESP32 Arduino IDE Setup:** https://randomnerdtutorials.com/esp32-bluetooth-classic-arduino-ide/
- **MPU6050 Library:** https://github.com/jrowberg/i2cdevlib/tree/master/Arduino/MPU6050
- **MAX30100 Library:** https://github.com/sparkfun/SparkFun_MAX3010x_Sensor_Library

---

**Fin du Guide d'Intégration**
