# 🏥 Guide d'Intégration Finale - Système Intelligent de Surveillance Médicale

## 📋 Vue d'ensemble du Projet

Ce projet intègre une **application Flutter** avec un **firmware ESP32** pour créer un système complet de surveillance médicale en temps réel. Le système détecte et alerte sur:

- 🤒 **Fièvre** (température modérée 38-39.5°C et fièvre élevée >39.5°C)
- ❄️ **Hypothermie** (température <35°C)
- 🚨 **Chutes** (détection par accélération soudaine)
- 📊 **Paramètres vitaux normaux**

---

## 🔧 Architecture du Système

### Composants Matériels
```
ESP32 (Carte de contrôle)
├── MLX90614 (Capteur de température infrarouge sans contact)
│   └── I2C (SDA=GPIO32, SCL=GPIO33)
├── MPU6050 (Capteur de mouvement)
│   └── I2C (SDA=GPIO32, SCL=GPIO33, Adresse: 0x69)
├── LED d'alerte (GPIO12)
└── Bluetooth Serial (HC-05 optionnel ou Bluetooth natif)
```

### Flux de Données
```
Capteurs ESP32
    ↓
    │ (Traitement firmware)
    ↓
JSON via Bluetooth Serial
    ↓
App Flutter
    ├── BluetoothESP32Service (réception)
    ├── ESP32Service (parsing)
    ├── AlertService (gestion alertes)
    └── UI (affichage temps réel)
```

---

## 📱 Configuration de l'Application Flutter

### 1. pubspec.yaml - Dépendances Requises

Assurez-vous que votre `pubspec.yaml` inclut:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Bluetooth
  flutter_bluetooth_serial: ^0.4.0
  
  # JSON
  json_annotation: ^4.8.0
  
  # Audio pour les alertes
  audioplayers: ^5.2.0
  
  # HTTP (optionnel)
  http: ^1.1.0
  
  # Utils
  intl: ^0.19.0
```

### 2. Structure du Dossier lib/

```
lib/
├── main.dart                          # Point d'entrée
├── models/
│   └── health_data.dart              # Modèle de données de santé
├── services/
│   ├── alert_service.dart            # Gestion des alertes (NOUVEAU)
│   ├── bluetooth_esp32_service.dart   # Communication Bluetooth
│   ├── esp32_service.dart            # Parsing des données
│   ├── health_service.dart           # Service santé
│   └── esp32_firmware_adapter.dart   # Adaptateur firmware
├── live_dashboard_updated.dart       # Dashboard temps réel (AMÉLIORÉ)
├── alerts_notifications.dart
├── device_connectivity.dart
├── health_dashboard.dart
├── health_history.dart
└── heart_rate_analysis.dart
```

### 3. Permissions Requises - AndroidManifest.xml

Ajoutez dans `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- Localisation (requise pour scanner Bluetooth sur Android 6+) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Audio -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

---

## 📡 Configuration de l'ESP32

### 1. Bibliothèques Requises

Installez via Arduino IDE Library Manager:

```
Adafruit MLX90614
MPU6050
ArduinoJson (version ≥6.18)
BluetoothSerial (intégré dans ESP32)
```

### 2. Code Firmware Amélioré

Le fichier `esp32_health_monitor.ino` inclut:

✅ **Support Bluetooth Serial:** Envoi de données JSON  
✅ **Détection Fièvre:** Avec confirmation et seuils configurables  
✅ **Détection Chute:** Utilisant accélernométrie  
✅ **Détection Hypothermie:** Très basses températures  
✅ **Gestion LED:** Indication visuelle des alertes  
✅ **Commandes Bluetooth:** LED_ON, LED_OFF, STATUS, MEASURE, etc.

### 3. Adresses I2C des Capteurs

Vérifiez avec le scan I2C:
- **MLX90614**: Généralement `0x5A` (par défaut) ou `0x5B`
- **MPU6050**: Généralement `0x68` (par défaut) ou `0x69`

Pour modifier dans le code:
```cpp
Adafruit_MLX90614 mlx = Adafruit_MLX90614();     // Adresse par défaut
MPU6050 mpu(0x69);                              // Changer 0x69 si nécessaire
```

### 4. Branchement des Capteurs

```
ESP32 Pinout:
┌─────────────────────────┐
│   GPIO32 (SDA) ────┐   │
│   GPIO33 (SCL) ────┼───┼─── I2C Sensors
│   GPIO12 (LED) ────┼───┤
│   GND ──────────────┘   │
│   3.3V ─────────────────┤─── Alimentation capteurs
└─────────────────────────┘

I2C:
MLX90614 ─── SDA (GPIO32)
           └─ SCL (GPIO33)
           └─ GND
           └─ VCC (3.3V)

MPU6050 ──── SDA (GPIO32)
          └─ SCL (GPIO33)
          └─ GND
          └─ VCC (3.3V)
          └─ INT (optionnel, GPIO35)

LED (GPIO12)───[R=220Ω]───GND
           └────VCC (3.3V) via le GPIO
```

---

## 🔌 Flux de Communication

### Format des Données JSON (Firmware → Flutter)

Le ESP32 envoie via Bluetooth Serial:

```json
{
  "temperature": 36.5,
  "temperatureAmbient": 25.0,
  "accelX": 0.05,
  "accelY": 0.1,
  "accelZ": 0.95,
  "fallDetected": false,
  "feverDetected": false,
  "hypothermiaDetected": false,
  "ledActive": false,
  "status": "OK",
  "alertStatus": "NORMAL",
  "timestamp": 1234567890
}
```

### Seuils de Détection (ESP32)

| Métrique | Seuil | Type |
|----------|-------|------|
| Température - Hypothermie | < 35°C | CRITIQUE ❄️ |
| Température - Fièvre modérée | 38-39.5°C | ALERTE 🤒 |
| Température - Fièvre élevée | ≥ 39.5°C | CRITIQUE 🔴 |
| Accélément - Chute | > 18000 m/s² | CRITIQUE 🚨 |
| Immobilité post-impact | > 5s | Confirmation chute |

---

## 🚀 Guide de Démarrage Rapide

### Étape 1: Préparer l'ESP32

1. **Uploader le firmware:**
   ```
   Arduino IDE → Outils → Sélectionner ESP32 board
   Fichier → Ouvrir → esp32_health_monitor.ino
   Vérifier → Téléverser
   ```

2. **Vérifier le Bluetooth:**
   - Serial Monitor (115200 baud)
   - Vérifier messages "[OK] MLX90614 initialisé"
   - Vérifier messages "[OK] MPU6050 initialisé"

3. **Tester les capteurs:**
   - Approcher main du MLX90614 → Température devrait augmenter
   - Déplacer/pencher MPU6050 → Accélération devrait changer

### Étape 2: Configuration Flutter

1. **Installer les dépendances:**
   ```bash
   flutter pub get
   ```

2. **Configurer les permissions Android:**
   - Vérifier `android/app/src/main/AndroidManifest.xml`
   - Accepter les permissions lors du premier lancement

3. **Compiler et exécuter:**
   ```bash
   flutter run
   ```

### Étape 3: Connexion

1. **Appareiller l'ESP32 sur Android:**
   - Paramètres → Bluetooth
   - Chercher "ESP32_HealthMonitor"
   - Appareiller (code: 1234 par défaut)

2. **Lancer l'app:**
   - L'app cherche automatiquement l'ESP32
   - Connexion établie quand icône Bluetooth affiche "Connecté"

3. **Vérifier la réception:**
   - Dashboard devrait afficher:
     - ✅ Température corporelle
     - ✅ Accélération
     - ✅ État LED
     - ✅ Messages de statut

---

## 🚨 Test des Alertes

### Test Fièvre

```
Scénario: Approcher la main près du MLX90614
Température → 38.5°C
Résultat → 🤒 Alerte fièvre modérée
         → 🔔 Son d'alerte
         → 💻 Dashboard affiche en orange
```

### Test Hypothermie

```
Scénario: Refroidir le capteur (glaçon proche)
Température → 34.0°C
Résultat → ❄️ Alerte hypothermie
         → 🔔 Son d'alerte
         → 💻 Dashboard affiche en bleu
```

### Test Chute

```
Scénario: Déplacer rapidement l'ESP32 (simulation chute)
Accélération → > 18000 m/s²
Immobilité > 5s
Résultat → 🚨 Alerte chute
         → 🔴 LED s'allume
         → 🔔 Son d'alerte urgent
```

---

## 📊 Pages Flutter - Fonctionnalités

### 1. Live Dashboard (Onglet 1)
- Affichage temps réel de tous les paramètres
- Alertes visuelles pour anomalies
- Dialogue critique pour chutes/fièvre élevée
- Boutons: Mesure imédiate, Statut

### 2. Device Connectivity (Onglet 2)
- État de connexion Bluetooth
- Liste des appareils disponibles
- Boutons: Connecter, Déconnecter, Rafraîchir

### 3. Health Dashboard (Onglet 3)
- Graphiques et tendances
- Historique des mesures
- Statistiques par jour/semaine

### 4. Health History (Onglet 4)
- Liste chronologique des mesures
- Export des données
- Recherche et filtrage

### 5. Heart Rate Analysis (Onglet 5)
- Analyse de la fréquence cardiaque
- Tendances temporelles
- Recommandations

### 6. Alerts & Notifications (Onglet 6)
- Liste de toutes les alertes reçues
- Timestamp et description
- Actions rapides (appel urgence, etc.)

---

## 🐛 Dépannage

### ❌ "Connexion refusée"
```
Solution:
1. Vérifier que Bluetooth est activé sur Android
2. Vérifier permissions dans Paramètres → Applications → Permission
3. Redémarrer l'app
4. Redémarrer l'ESP32
```

### ❌ "Pas de données reçues"
```
Solution:
1. Vérifier Serial Monitor ESP32 (115200 baud)
2. Vérifier capteurs I2C répondent
3. Commander STATUS via Bluetooth
4. Vérifier les seuils de température (37°C normal)
```

### ❌ "LED ne s'allume pas"
```
Solution:
1. Vérifier GPIO12 n'est pas utilisé ailleurs
2. Vérifier alimentation LED
3. Tester: LED_ON via Bluetooth
4. Vérifier la LED avec un voltmètre
```

### ⚠️ "Alertes continues sans raison"
```
Solution:
1. Éloigner la main du capteur
2. Vérifier la température ambiante
3. Reset via bouton Reset de l'ESP32
4. Vérifier calibration MLX90614
```

---

## 📈 Données Sauvegardées

L'app save automatiquement localement:

```
~/health_monitor_app/data/
├── health_history.json      # Historique des mesures
├── alerts_log.json         # Journal des alertes
└── device_settings.json    # Configuration du device
```

---

## 🔒 Sécurité et Confidentialité

- ✅ Données stockées localement sur le téléphone
- ✅ Communication Bluetooth chiffrée (BT natif)
- ✅ Pas de transmission réseau par défaut
- ⚠️ Pour transmettre vers serveur: implémenter chiffrement HTTPS

---

## 📚 Fichiers Modifiés/Créés

| Fichier | Type | Description |
|---------|------|-------------|
| `esp32_health_monitor.ino` | Firmware | ✅ Amélioré - JSON BT, alertes |
| `lib/models/health_data.dart` | Model | ✅ Enrichi - AlertType, props |
| `lib/services/esp32_service.dart` | Service | ✅ Refondu - Parsing JSON |
| `lib/services/bluetooth_esp32_service.dart` | Service | ✅ Amélioré - Gestion buffer |
| `lib/services/alert_service.dart` | Service | ✨ NOUVEAU - Alertes complètes |
| `lib/live_dashboard_updated.dart` | UI | ✅ Refondu - Temps réel + alertes |

---

## 🎯 Prochaines Étapes Recommandées

1. **Test complet** sur appareils réels
2. **Calibrage** des seuils selon besoins patients
3. **Implémentation** serveur backend si transmission requise
4. **Certification** médicale si utilisation hospitalière
5. **Notification** push vers urgences
6. **Interface** soignant/médecin avancée

---

## 📞 Support et Documentation

Pour plus d'informations:
- 📖 ESP32: https://docs.espressif.com/
- 🔧 Adafruit MLX90614: https://learn.adafruit.com/mlx90614
- 💙 Adafruit MPU6050: https://learn.adafruit.com/mpu6050
- 🐦 Flutter: https://flutter.dev/docs
- 📱 flutter_bluetooth_serial: https://pub.dev/packages/flutter_bluetooth_serial

---

**Système de Surveillance Médicale - Version Finale ✅**  
*Dernière mise à jour: Avril 2026*
