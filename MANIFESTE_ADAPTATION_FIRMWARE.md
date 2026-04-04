# 📋 Manifeste: Adaptation Flutter ↔ Firmware ESP32

**Date:** 28 Mars 2026  
**Objectif:** Adapter le code Flutter pour communiquer avec le firmware MAX30100/MLX90614/MPU6050

---

## 📦 Fichiers Créés (3 nouveaux)

### 1️⃣ `lib/services/esp32_firmware_adapter.dart` ✨ NOUVEAU
**Responsabilité:** Parser la sortie texte du firmware ESP32

```dart
class ESP32FirmwareAdapter {
  // Parse format: "=== Mesures ===\nTempérature: ...\nMAX30100: ...\n..."
  static HealthData parseSerialOutput(String serialData)
  
  // Estime FC à partir du ratio IR/RED du MAX30100
  static double _estimateHeartRateFromPPG(int irValue, int redValue)
  
  // Convertit accélération brute (int16) → G
  static Map<String, double> _convertAccelToG(int ax, int ay, int az)
  
  // Génère explication textuelle des anomalies
  static String _generateReason(...)
}
```

**Entrée:**
```
=== Mesures ===
Température: Amb=26.71 °C | Obj=27.91 °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.
```

**Sortie:**
```dart
HealthData(
  heartRate: 0.0,
  temperature: 27.91,
  accelX: 0.0,
  accelY: 0.0,
  accelZ: 0.0,
  status: HealthStatus.normal,
  reason: "NO_FINGER_DETECTED"
)
```

### 2️⃣ `lib/services/bluetooth_esp32_service.dart` ✨ NOUVEAU
**Responsabilité:** Gestion Bluetooth avec buffer accumulation

```dart
class BluetoothESP32Service {
  // Se connecter à un device HC-05
  Future<void> connectToESP32(String deviceAddress)
  
  // Écouter stream de données
  Stream<HealthData> get healthDataStream
  
  // Envoyer commandes à l'ESP32
  Future<void> sendCommand(String command)
  Future<void> setThreshold(String metric, double min, double max)
  
  // Lister appareils Bluetooth appairés
  Future<List<BluetoothDevice>> getAvailableDevices()
}

// Widget de scanning
class BluetoothScannerWidget extends StatefulWidget { ... }
```

### 3️⃣ `test/services/firmware_adapter_test.dart` ✨ NOUVEAU
**Responsabilité:** Tests unitaires du parser firmware

12 tests couvrant:
- ✅ Parser output normale
- ✅ Détection fièvre
- ✅ Détection mouvement
- ✅ Conversion G
- ✅ Estimation FC
- ✅ Gestion format JSON hérité
- ✅ Données incomplètes
- ✅ Cas extrêmes (hypothermie, tachycardie)

---

## 📝 Fichiers Modifiés (2)

### 1️⃣ `lib/services/esp32_service.dart` ✏️ MODIFIÉ
**Avant:**
```dart
void parseAndProcessData(String jsonString) {
  // Parsait SEULEMENT du JSON
  final json = jsonDecode(jsonString);
  final healthData = HealthData(...);
}
```

**Après:**
```dart
void parseAndProcessData(String rawData) {
  // Détecte automatiquement le format
  if (rawData.startsWith('{')) {
    return _parseJSON(rawData);  // JSON ancien
  } else if (rawData.contains('=== Mesures ===')) {
    return _parseFirmwareFormat(rawData);  // Firmware nouveau
  }
}

HealthData _parseFirmwareFormat(String serialData) {
  return ESP32FirmwareAdapter.parseSerialOutput(serialData);
}
```

**Changements:**
- ✅ Ajout import `esp32_firmware_adapter.dart`
- ✅ Refactorisation `parseAndProcessData()` pour auto-détection
- ✅ Extraction `_parseJSON()` pour compatibilité
- ✅ Nouvelle méthode `_parseFirmwareFormat()`

### 2️⃣ `pubspec.yaml` ✏️ À MODIFIER
**À ajouter:**
```yaml
dependencies:
  flutter_bluetooth_serial: ^0.4.3
```

---

## 🔄 Flux d'Intégration Global

```
┌─────────────────────────────────────────────────┐
│           ESP32 Firmware Output                 │
│  (Serial 115200 via HC-05 Bluetooth)            │
└────────────────┬────────────────────────────────┘
                 │
        ┌────────V──────────┐
        │ HC-05 Bluetooth   │ (Modulation RF)
        └────────┬──────────┘
                 │
    ┌────────────V───────────────┐
    │  Android/iOS Bluetooth     │
    │  Radio Receiver            │
    └────────────┬───────────────┘
                 │
    ┌────────────V───────────────────────────────┐
    │  BluetoothESP32Service                      │
    │  ├─ listen() → (Uint8List data)             │
    │  ├─ String.fromCharCodes(data)              │
    │  └─ accumulate buffer (chunks)              │
    └────────────┬───────────────────────────────┘
                 │
    ┌────────────V──────────────────────────────┐
    │  ESP32Service.parseAndProcessData()        │
    │  ├─ Auto-detect format (JSON vs Firmware)  │
    │  ├─ Call ESP32FirmwareAdapter              │
    │  └─ Emit HealthData to StreamController    │
    └────────────┬──────────────────────────────┘
                 │
    ┌────────────V──────────────────────────────┐
    │  ESP32FirmwareAdapter.parseSerialOutput()  │
    │  ├─ Regex extract: Température, MAX30100,  │
    │  │              MPU6050, Alerte            │
    │  ├─ Convert: Raw values → HealthData      │
    │  │         IR/RED → FC, accel → G         │
    │  ├─ Generate reason (FEVER, MOTION, etc)  │
    │  └─ Return HealthData object              │
    └────────────┬──────────────────────────────┘
                 │
    ┌────────────V──────────────────────────────┐
    │  HealthData StreamController               │
    │  └─ Broadcast stream to UI listeners      │
    └────────────┬──────────────────────────────┘
                 │
    ┌────────────V──────────────────────────────┐
    │  Widget StatefulWidget                     │
    │  ├─ StreamBuilder<HealthData>              │
    │  └─ Update UI (60 FPS)                     │
    └──────────────────────────────────────────┘
```

---

## ✨ Nouvelles Capacités

### 1. **Auto-détection Format**
```dart
// Supporte MAINTENANT:
1. JSON ancien: {"heartRate": 72, "temperature": 36.6, ...}
2. Firmware nouveau: "=== Mesures ===\nTempérature: ...\n..."
```

### 2. **Gestion Capteurs Défaillants**
```dart
// Si MAX30100 ne répond pas:
heartRate = 0.0
reason = "NO_FINGER_DETECTED"

// Si MPU6050 ne répond pas:
accelX = accelY = accelZ = 0.0
status = normal (pas alerte juste pour ça)
```

### 3. **Estimation FC Intelligente**
```dart
// Formule empirique basée sur ratio IR/RED:
FC_estimée = 60 + (ratio - 2.0) * 30
// Range: 40-200 BPM (clamped)
```

### 4. **Conversion Unités**
```dart
// Accélération MPU6050 (±2g mode):
raw_value / 16384.0 = G
// Exemple: 16384 raw → 1.0 G
```

### 5. **Messages Explicatifs**
```dart
reason = "FEVER (38.5°C); NO_FINGER_DETECTED"
// Au lieu de "isAbnormal: true" seul
```

---

## 🧪 Stratégie de Tests

### Test 1: Parsing Sans Matériel
```bash
flutter test test/services/firmware_adapter_test.dart
```
✅ Valide toute la logique parsing
✅ 0 matériel requis

### Test 2: Parsing avec Données Réelles
```dart
// Copier/coller la sortie Serial dans test
final sampleData = '''=== Mesures ===
Température: Amb=26.71 °C | Obj=27.91 °C
...''';

final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);
expect(result.temperature, 27.91);
```

### Test 3: Intégration Bluetooth
```dart
// Nécessite HC-05 appairé
final service = BluetoothESP32Service();
await service.connectToESP32('98:D3:31:B1:11:22');

service.healthDataStream.listen((data) {
  print('Reçu: ${data.temperature}°C');
});
```

---

## 🎯 Étapes d'Implémentation

### ✅ Déjà Fait
- [x] Créer esp32_firmware_adapter.dart avec parsing complet
- [x] Modifier esp32_service.dart pour auto-détection
- [x] Créer bluetooth_esp32_service.dart avec gestion Bluetooth
- [x] Créer 12 tests unitaires
- [x] Créer guide d'intégration complet

### ⏭️ À Faire (Next)
- [ ] Ajouter dépendance `flutter_bluetooth_serial` à pubspec.yaml
- [ ] Configurer permissions Android (AndroidManifest.xml)
- [ ] Configurer permissions iOS (Info.plist)
- [ ] Adapter device_connectivity.dart pour utiliser BluetoothScannerWidget
- [ ] Adapter live_dashboard_updated.dart pour écouter healthDataStream
- [ ] Tester avec ESP32 réel + HC-05
- [ ] Implémenter fallback simulation (sans matériel)
- [ ] Ajouter persistance BD (SQLite) pour historique

---

## 📊 Statistiques Code

| Fichier | Lignes | Type |
|---------|--------|------|
| esp32_firmware_adapter.dart | 180 | ✨ Nouveau |
| bluetooth_esp32_service.dart | 220 | ✨ Nouveau |
| esp32_service.dart | +50 | ✏️ Modifié |
| firmware_adapter_test.dart | 350 | ✨ Nouveau |
| **TOTAL** | **800** | |

---

## 🔐 Considérations Sécurité

### Bluetooth
- ✅ Validation adresse device avant connexion
- ✅ Gestion exceptions connexion perdue
- ✅ Nettoyage ressources en dispose()

### Parsing
- ✅ Validation regex pour chaque champ
- ✅ Fallback valeurs par défaut si invalide
- ✅ Pas de crashes sur données malformées

### Données
- ✅ Validation plages (ex: température 30-50°C)
- ✅ Clamp FC: 40-200 BPM
- ✅ Vérification null partout

---

## 🐛 Points d'Attention

### ⚠️ Problème: MAX30100 et MPU6050 = 0
**Output firmware montre:**
```
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=0]
```

**Cause possible:**
- Capteurs non détectés lors de setup()
- Câblage I2C défaillant
- Adress I2C incorrecte (0x69 pour MPU6050)
- Pull-ups manquants (10kΩ sur SDA/SCL)

**Solution:**
- Vérifier Serial debug: "MAX30100 OK" / "MAX30100 non détecté !"
- Utiliser I2C Scanner sketch Arduino pour vérifier adresses

### ⚠️ Buffering Bluetooth
Les données peuvent arriver en chunks:
```
Chunk 1: "=== Mesures ===\nTempérature: Amb=26.71 °C | Obj=27"
Chunk 2: ".91 °C\nMAX30100: IR=0 | RED=0\nMPU6050: ..."
Chunk 3: "Accel[X=0 Y=0 Z=0]\nOK : LED éteinte."
```

**Solution:** BluetoothESP32Service accumule dans un buffer et valide les blocs complets.

---

## 📚 Références

- Firmware ESP32: `/workspace/esp32_health_monitor.ino`
- Proposition BD: `PROPOSITION_BASE_DE_DONNEES.md`
- Chapitre Flutter: `CHAPITRE_4_FLUTTER_IOT.md`
- Guide complet: `GUIDE_INTEGRATION_FIRMWARE.md`

---

## ✅ Checklist Livraison

- [x] Code implémenté et formaté
- [x] Tests écrits et validés
- [x] Documentation complète
- [x] Guide d'intégration détaillé
- [x] Exemples d'utilisation fournis
- [ ] Intégration widget (à faire pour device_connectivity.dart)
- [ ] Test avec matériel réel (à valider)
- [ ] Persistance BD (prochaine phase)

---

**Fin du Manifeste**
