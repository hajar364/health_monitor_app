# 📋 Plan de Migration - Projet Détection de Chute (Fall Detection)

**Date de création:** 16 Avril 2026  
**Statut:** Plan initial  
**Objectif:** Transformer le Health Monitor App en système de détection de chute pour personnes âgées/vulnérables

---

## 📌 Vue d'ensemble du projet

### Objectif Final
Créer une application **Flutter + ESP32** complète pour:
- ✅ Détecter automatiquement les chutes par analyse IMU (MPU6050)
- ✅ Monitorer la température corporelle (MLX90614)
- ✅ Afficher les données en temps réel dans un dashboard médical
- ✅ Déclencher des alertes SOS automatiques
- ✅ Gérer les profils patients
- ✅ Historique et statistiques des alertes
- ✅ Configuration des seuils critiques

---

## 🏗️ Architecture Globale

### Stack Technologique
```
┌─────────────────────────────────────────────────────────┐
│                   Flutter App (Mobile)                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Pages: Dashboard | Alerts | Patients | Settings  │   │
│  │ Services: Connectivity | Data Processing | SOS   │   │
│  │ State Mgmt: State Management (Provider/Riverpod) │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                    ↓ WiFi/TCP Socket
┌─────────────────────────────────────────────────────────┐
│              ESP32 Microcontroller (µC)                  │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Sensors: MPU6050 (IMU) + MLX90614 (Thermal)     │   │
│  │ Libraries: I2C, WiFi, ADC, Interrupt Handlers    │   │
│  │ Processing: Fall Detection Algorithm             │   │
│  │ Server: TCP Socket Server (Port 5000)            │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 📂 Structure de Fichiers Cible

```
lib/
├── main.dart                           # Point d'entrée
├── models/
│   ├── health_data.dart               # (Existant - À adapter)
│   ├── fall_detection_data.dart       # ✅ NOUVEAU: Données IMU
│   ├── patient_profile.dart           # ✅ NOUVEAU: Profil patient
│   ├── alert_event.dart               # ✅ NOUVEAU: Événement alerte
│   └── threshold_settings.dart        # ✅ NOUVEAU: Seuils critiques
├── services/
│   ├── bluetooth_esp32_service.dart   # (Existant - À refactoriser)
│   ├── esp32_firmware_adapter.dart    # (Existant - À adapter)
│   ├── wifi_tcp_service.dart          # ✅ NOUVEAU: Connexion WiFi/TCP
│   ├── fall_detection_service.dart    # ✅ NOUVEAU: Algorithme détection
│   ├── alert_service.dart             # ✅ NOUVEAU: Gestion alertes SOS
│   ├── patient_service.dart           # ✅ NOUVEAU: Données patients
│   └── local_storage_service.dart     # ✅ NOUVEAU: Stockage local (Hive/SQLite)
├── screens/
│   ├── home_screen.dart               # ✅ NOUVEAU: Dashboard principal
│   ├── fall_dashboard.dart            # ✅ NOUVEAU: Vue temps réel
│   ├── alerts_history.dart            # ✅ NOUVEAU: Historique alertes
│   ├── patients_management.dart       # ✅ NOUVEAU: Gestion patients
│   ├── settings_screen.dart           # ✅ NOUVEAU: Configuration seuils
│   ├── device_connectivity.dart       # (Existant - À adapter)
│   └── alert_sos_screen.dart          # ✅ NOUVEAU: Écran alerte SOS
├── widgets/
│   ├── fall_indicator.dart            # ✅ NOUVEAU: Indicateur chute
│   ├── real_time_chart.dart           # ✅ NOUVEAU: Graphiques temps réel
│   ├── patient_card.dart              # ✅ NOUVEAU: Carte patient
│   ├── threshold_slider.dart          # ✅ NOUVEAU: Sélecteur seuil
│   └── alert_notification.dart        # ✅ NOUVEAU: Widget notification
├── providers/                          # ✅ NOUVEAU: State Management (Provider)
│   ├── connectivity_provider.dart
│   ├── sensor_data_provider.dart
│   ├── fall_detection_provider.dart
│   ├── alert_provider.dart
│   ├── patient_provider.dart
│   └── settings_provider.dart
├── utils/
│   ├── constants.dart                 # Constantes (À augmenter)
│   ├── fall_detection_algorithm.dart  # ✅ NOUVEAU: Algo ML/détection
│   └── logger.dart                    # Logging
└── config/
    └── app_config.dart                # Configuration globale

esp32_health_monitor/
└── esp32_health_monitor.ino           # (À refactoriser complètement)
    ├── Sensors Setup (MPU6050 + MLX90614)
    ├── WiFi Connection
    ├── TCP Server
    ├── Data Transmission
    └── SOS Trigger Logic

assets/
├── images/
│   ├── fall_alert_icon.png
│   ├── medical_dashboard.png
│   └── patient_icon.png
└── sounds/
    └── sos_alert_sound.wav            # ✅ NOUVEAU: Son alerte
```

---

## 🚀 Plan de Travail Détaillé

### **PHASE 1: PRÉPARATION & CONFIGURATION (1-2 jours)**

#### 1.1 Analyse & Nettoyage du Code Existant
- [ ] Analyser les fichiers existants (device_connectivity.dart, main.dart, etc.)
- [ ] Identifier les dépendances inutiles
- [ ] Créer une branche de développement `fall-detection-dev`
- [ ] Documenter l'architecture actuelle

#### 1.2 Dépendances Flutter à Ajouter
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.0           # ou riverpod
  
  # Connectivity
  connectivity_plus: ^5.0.0  # Vérification Wi-Fi
  
  # Sensors & Data
  fl_chart: ^0.65.0          # Graphiques temps réel
  
  # Storage Local
  hive: ^2.2.0               # Base de données locale
  hive_flutter: ^1.1.0
  
  # Notifications
  flutter_local_notifications: ^15.0.0  # Alertes locales
  
  # Appel d'urgence
  phone_caller: ^1.0.0       # Appels d'urgence
  
  # Utils
  intl: ^0.19.0              # Formats date/heure
  uuid: ^4.0.0               # UUID générés
```

#### 1.3 Configuration ESP32 Arduino
- [ ] Mettre à jour l'IDE Arduino pour ESP32
- [ ] Installer les bibliothèques:
  - `MPU6050_tockn` pour gyroscope/accéléromètre
  - `Adafruit MLX90614` pour capteur thermique
  - `WiFi.h` native ESP32
  - `BluetoothSerial` ou WiFi Server

---

### **PHASE 2: MODÈLES DE DONNÉES (2-3 jours)**

#### 2.1 Créer Models/Data Classes

**2.1.1 - `fall_detection_data.dart`** - Données IMU
```dart
// Données brutes du capteur
class IMUSensorData {
  final DateTime timestamp;
  final double accelX, accelY, accelZ;  // Accélération (g)
  final double gyroX, gyroY, gyroZ;     // Vitesse angulaire (°/s)
  final double magnitude;               // Magnitude d'accélération
}

// Détection de chute
class FallEvent {
  final DateTime timestamp;
  final String severity;  // "LOW", "MEDIUM", "HIGH"
  final double confidence;  // 0-100%
  final String reason;      // Description
  final bool isConfirmed;
}
```

**2.1.2 - `patient_profile.dart`** - Profil Patient
```dart
class PatientProfile {
  final String id;
  final String name;
  final int age;
  final double height, weight;
  final String emergencyContact;
  final String emergencyPhone;
  final List<String> medicalConditions;
  final DateTime registeredDate;
}
```

**2.1.3 - `alert_event.dart`** - Événement Alerte
```dart
class AlertEvent {
  final String id;
  final DateTime timestamp;
  final String alertType;  // "FALL", "TEMP_HIGH", "TEMP_LOW"
  final String severity;
  final PatientProfile? patient;
  final bool isResolved;
  final String? resolution;  // "False Alarm", "Treated", etc.
}
```

**2.1.4 - `threshold_settings.dart`** - Seuils Critiques
```dart
class ThresholdSettings {
  double fallDetectionSensitivity;    // 0.5 - 2.0
  double accelerationThreshold;        // en g (9.8 = 1g)
  double temperatureHighAlert;        // °C
  double temperatureLowAlert;         // °C
  int fallConfirmationDelay;          // ms
  int sosActivationTime;              // Si chute non confirmée (ms)
}
```

---

### **PHASE 3: SERVICES BACKEND FLUTTER (3-4 jours)**

#### 3.1 Service WiFi/TCP
**`wifi_tcp_service.dart`** - Connexion ESP32
```dart
class WifiTcpService {
  // Connexion TCP au serveur ESP32
  Future<void> connectToESP32(String ipAddress, int port);
  
  // Écoute les données en temps réel
  Stream<IMUSensorData> getSensorDataStream();
  Stream<TemperatureData> getTemperatureStream();
  
  // Envoyer commandes
  Future<void> sendCommand(String command);
  
  // Déconnexion
  Future<void> disconnect();
}
```

#### 3.2 Service Détection de Chute
**`fall_detection_service.dart`** - Algorithme ML
```dart
class FallDetectionService {
  // Algorithme principal
  FallEvent? analyzeSensorData(List<IMUSensorData> dataBuffer);
  
  // Détection multi-seuils:
  // 1. Magnitude d'accélération > seuil
  // 2. Orientation rapide (gyroscope)
  // 3. Confirmation par orientation au sol (accel < seuil pendant N ms)
  
  Future<void> confirmFall(FallEvent fall);
  Future<void> cancelFall(FallEvent fall);
}
```

#### 3.3 Service Alerte SOS
**`alert_service.dart`** - Gestion Alertes
```dart
class AlertService {
  // Déclencher alerte
  Future<void> triggerSOSAlert(AlertEvent event);
  
  // Notification locale
  Future<void> showNotification(AlertEvent event);
  
  // Appel d'urgence
  Future<void> emergencyCall(String phoneNumber);
  
  // Historique
  Future<List<AlertEvent>> getAlertHistory();
  Future<void> saveAlertToDatabase(AlertEvent event);
}
```

#### 3.4 Service Patients
**`patient_service.dart`** - Gestion Profils
```dart
class PatientService {
  Future<void> addPatient(PatientProfile patient);
  Future<void> updatePatient(PatientProfile patient);
  Future<PatientProfile> getPatient(String id);
  Future<List<PatientProfile>> getAllPatients();
  Future<void> deletePatient(String id);
}
```

#### 3.5 Service Stockage Local
**`local_storage_service.dart`** - Hive/SQLite
```dart
class LocalStorageService {
  // Données patients
  Future<void> savePatient(PatientProfile patient);
  
  // Historique alertes
  Future<void> saveAlert(AlertEvent alert);
  Future<List<AlertEvent>> getAlerts({required DateTime from, DateTime? to});
  
  // Paramètres seuils
  Future<void> saveThresholds(ThresholdSettings settings);
  Future<ThresholdSettings> getThresholds();
}
```

---

### **PHASE 4: STATE MANAGEMENT (2-3 jours)**

#### 4.1 Providers (Utiliser Provider ou Riverpod)
```dart
// connectivity_provider.dart
final esp32ConnectionProvider = StateNotifierProvider(/* ... */);

// sensor_data_provider.dart
final sensorDataStreamProvider = StreamProvider(/* ... */);

// fall_detection_provider.dart
final fallDetectionProvider = StateNotifierProvider(/* ... */);

// alert_provider.dart
final alertHistoryProvider = FutureProvider(/* ... */);

// patient_provider.dart
final patientListProvider = FutureProvider(/* ... */);

// settings_provider.dart
final thresholdSettingsProvider = StateNotifierProvider(/* ... */);
```

---

### **PHASE 5: UI/SCREENS (4-5 jours)**

#### 5.1 Screen 1: Dashboard Principal
**`fall_dashboard.dart`**
- [ ] Indicateur connexion ESP32
- [ ] Affichage temps réel: Accélération, Temp, Orientation
- [ ] Graphiques en temps réel (fl_chart)
- [ ] Bouton démonstration chute
- [ ] Statut patient actuel

#### 5.2 Screen 2: Historique Alertes
**`alerts_history.dart`**
- [ ] Liste chronologique des alertes
- [ ] Filtres: Type (chute, temp), Date, Sévérité
- [ ] Détails alerte: Données capteurs, Réponse, Résolution
- [ ] Export données (CSV)

#### 5.3 Screen 3: Gestion Patients
**`patients_management.dart`**
- [ ] Liste des patients enregistrés
- [ ] Ajouter/Éditer/Supprimer patient
- [ ] Fiches patient détaillées
- [ ] Contact d'urgence

#### 5.4 Screen 4: Configuration
**`settings_screen.dart`**
- [ ] IP/Port ESP32
- [ ] Seuils critiques (sliders)
- [ ] Sensibilité détection chute
- [ ] Volume/Type notification
- [ ] Données à importer/exporter

#### 5.5 Screen 5: Connexion Dispositif
**Adapter `device_connectivity.dart`**
- [ ] Scan WiFi automatique
- [ ] Connexion ESP32 par IP/Port
- [ ] État connexion
- [ ] Diagnostique (ping, latence)

#### 5.6 Screen Alerte SOS
**`alert_sos_screen.dart`** - Écran Full Screen
- [ ] GRAND bouton "Annuler Alerte"
- [ ] Informations patient
- [ ] Contact d'urgence à appeler
- [ ] Compte à rebours avant appel auto (60s)
- [ ] Activation vibration + son

---

### **PHASE 6: FIRMWARE ESP32 (3-4 jours)**

#### 6.1 Refactoriser `esp32_health_monitor.ino`

**Structure attendue:**
```cpp
// Configuration capteurs
#include <MPU6050_tockn.h>
#include <Adafruit_MLX90614.h>
#include <WiFi.h>

// WiFi Setup
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
const int PORT = 5000;

// Capteurs
MPU6050 mpu6050(Wire);
Adafruit_MLX90614 mlx;

// Fall Detection Algorithm
bool detectFall(float accelMagnitude, float gyroMagnitude) {
  // Logique: 
  // 1. accelMag > THRESHOLD_G (1.5-2.0g)
  // 2. gyroMag > THRESHOLD_GYRO
  // 3. Orientation stabilisée à 0g après (au sol)
  return /* conditions */;
}

// WiFi Server
WiFiServer server(5000);

void setup() {
  Serial.begin(115200);
  
  // Initialiser capteurs
  mpu6050.begin();
  mlx.begin();
  
  // Connexion WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) { delay(500); }
  
  server.begin();
}

void loop() {
  // Lire capteurs
  mpu6050.update();
  float accelMag = sqrt(pow(mpu6050.getAccX(),2) + 
                        pow(mpu6050.getAccY(),2) + 
                        pow(mpu6050.getAccZ(),2));
  
  float temp = mlx.readObjectTempC();
  
  // Détecter chute
  if (detectFall(accelMag, /* gyro */)) {
    sendAlert();
  }
  
  // Envoyer données via TCP
  sendSensorData(accelMag, temp);
  
  delay(100);  // 10 Hz
}
```

#### 6.2 Format des Données Transmises
```json
{
  "timestamp": 1713282600,
  "accel": {"x": 0.1, "y": 0.2, "z": -9.8},
  "gyro": {"x": 0.5, "y": -0.2, "z": 0.1},
  "temperature": 36.5,
  "isFalling": false,
  "signal_strength": -50
}
```

---

### **PHASE 7: INTÉGRATION & TESTS (3-4 jours)**

#### 7.1 Tests Unitaires
- [ ] Tests service détection chute
- [ ] Tests service stockage
- [ ] Tests parsing données JSON

#### 7.2 Tests Intégration
- [ ] Connexion Flutter ↔ ESP32
- [ ] Réception donnée en temps réel
- [ ] Alerte SOS déclenchée correctement
- [ ] Sauvegarde historique

#### 7.3 Tests sur Appareil Réel
- [ ] Tester sur vrai ESP32 + capteurs
- [ ] Scenario détection chute simulée
- [ ] Alertes et notifications
- [ ] Stockage données

---

### **PHASE 8: OPTIMISATION & DÉPLOIEMENT (2-3 jours)**

#### 8.1 Performance
- [ ] Optimiser boucle détection chute (temps réel)
- [ ] Réduire consommation batterie ESP32
- [ ] Cache local des données
- [ ] Compression transmission

#### 8.2 Sécurité
- [ ] Authentification WiFi (WPA2)
- [ ] Chiffrement données sensibles (patient)
- [ ] Validation données capteurs

#### 8.3 Documentation
- [ ] README complet
- [ ] Guide installation
- [ ] Manuel utilisateur
- [ ] API documentation

---

## 📊 Ressources & Références

### Algorithme Détection Chute (Recherche)
```
Thresholds typiques pour MPU6050:
- Accélération pic de chute: 1.5-2.5g
- Durée pic: 100-200ms
- Confirmation au sol: accél < 1.1g pendant 500ms
- Sensibilité: Réglable 0.5-2.0
```

### Bibliothèques Recommandées
| Bibliothèque | Usage |
|---|---|
| **fl_chart** | Graphiques temps réel |
| **provider** | State Management |
| **hive** | Base données locale |
| **flutter_local_notifications** | Notifications SOS |
| **phone_caller** | Appels d'urgence |

### Ressources Capteurs
- [MPU6050 Datasheet](https://invensense.tdk.com/wp-content/uploads/2015/02/MPU-6000-Datasheet1.pdf)
- [MLX90614 Datasheet](https://www.melexis.com/en/product/MLX90614)
- [ESP32 Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/hw-reference/esp32_datasheet.pdf)

---

## ⏱️ Timeline Estimée

| Phase | Durée | Cumul |
|---|---|---|
| 1. Préparation | 1-2j | 1-2j |
| 2. Modèles | 2-3j | 3-5j |
| 3. Services | 3-4j | 6-9j |
| 4. State Mgmt | 2-3j | 8-12j |
| 5. UI/Screens | 4-5j | 12-17j |
| 6. Firmware ESP32 | 3-4j | 15-21j |
| 7. Tests | 3-4j | 18-25j |
| 8. Optimisation | 2-3j | 20-28j |

**Total estimé: 3-4 semaines** (travail à temps plein)

---

## 🎯 Checklist de Validation Finale

- [ ] Application démarre sans erreur
- [ ] Connexion WiFi ESP32 fonctionnelle
- [ ] Données capteurs affichées en temps réel
- [ ] Détection chute activée et testée
- [ ] Alerte SOS déclenchée correctement
- [ ] Historique alertes persiste
- [ ] Gestion patients complète
- [ ] Seuils modifiables et sauvegardés
- [ ] Documentation projet complète
- [ ] Build APK Android fonctionnel

---

## 📝 Notes Importantes

✅ **Keep:** Architecture service-based (réutilisable)  
✅ **Keep:** State Management (scalabilité)  
❌ **Remove:** Bluetooth (utiliser WiFi TCP)  
❌ **Refactor:** ESP32 firmware (complètement nouveau)  
✅ **Add:** Algorithme détection chute (cœur du projet)  
✅ **Add:** Gestion d'urgence (SOS, appels)  

---

**Version:** 1.0  
**Dernière mise à jour:** 16 Avril 2026
