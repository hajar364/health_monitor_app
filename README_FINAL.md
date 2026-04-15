# 🏥 Health Monitor Pro - Système Intelligent de Surveillance Médicale

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white) ![Bluetooth](https://img.shields.io/badge/Bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white)

**Système de surveillance médicale en temps réel basé sur IoT** pour la détection et l'alerte des situations critiques de santé.

---

## 🎯 Caractéristiques Principales

### 📊 Surveillance Temps Réel
- 🌡️ **Température corporelle** sans contact (capteur infrarouge MLX90614)
- 📈 **Accélération et mouvement** (capteur MPU6050)
- 🔔 **Alertes visuelles et sonores** en cas d'anomalie
- 🔴 **LED d'alerte** physique sur l'ESP32

### 🚨 Détection Critique
| Situation | Seuil | Réaction |
|-----------|-------|----------|
| 🤒 Fièvre modérée | 38-39.5°C | Alerte orange + son |
| 🔴 Fièvre élevée | ≥ 39.5°C | Alerte critique + LED |
| ❄️ Hypothermie | < 35°C | Alerte critique + LED |
| 🚨 Chute détectée | Accél >18000 m/s² | Alerte urgente + 3 bips |

### 💻 Interface Mobile Complète
- **6 onglets** de navigation
- **Dashboard temps réel** avec mise à jour continue
- **Historique** des mesures
- **Graphiques** et tendances
- **Journal d'alertes** avec timestamps

### 🔌 Intégration Hardware
```
┌─────────────────────────────────────┐
│          Téléphone Android          │
│     📱 Application Flutter 📱       │
│  [Live] [Connect] [Dashboard]       │
│  [History] [Heart] [Alerts]         │
└────────────┬──────────────────────┘
             │
             │ Bluetooth Serial
             │ (Données JSON)
             │
     ┌───────▼──────────────┐
     │    ESP32 Microcontroller   │
     │                      │
     ├──────────────────────┤
     │ MLX90614    MPU6050  │
     │ (Temp IR) (Accel)   │
     │                      │
     │ 🔴 LED d'alerte     │
     └──────────────────────┘
```

---

## 📦 Architecture

### Composants Logiciels

```
health_monitor_app/
├── esp32_health_monitor/
│   └── esp32_health_monitor.ino      # Firmware complet avec alertes
│
├── lib/
│   ├── main.dart                     # Point d'entrée + navigation
│   ├── models/
│   │   └── health_data.dart          # Modèle données (AlertType, HealthStatus)
│   ├── services/
│   │   ├── bluetooth_esp32_service.dart     # Communication Bluetooth
│   │   ├── esp32_service.dart               # Parsing JSON
│   │   └── alert_service.dart               # Gestion alertes (SON, VIBRATION, UI)
│   └── views/
│       ├── live_dashboard_updated.dart      # Dashboard temps réel
│       ├── device_connectivity.dart         # Gestion connexion
│       ├── health_dashboard.dart            # Graphiques
│       ├── health_history.dart              # Historique
│       ├── heart_rate_analysis.dart         # Analyse FC
│       └── alerts_notifications.dart        # Journal alertes
│
├── pubspec.yaml                     # Dépendances (flutter_bluetooth_serial, etc)
└── android/                         # Permissions Bluetooth
```

### Composants Hardware

```
ESP32 Dev Module
├─ I2C (SDA=GPIO32, SCL=GPIO33)
│  ├─ MLX90614 (Temp infrarouge, 0x5A)
│  └─ MPU6050 (Accélérométrie, 0x69)
├─ GPIO12 (LED d'alerte)
└─ Bluetooth Natif (pour communication Bluetooth Serial)
```

---

## 🚀 Installation

### Prérequis
- **Android 6.0+** avec Bluetooth
- **ESP32 Dev Module** + capteurs
- **Arduino IDE** avec pack ESP32
- **Flutter 3.0+** avec Dart

### Installation Rapide (5 min)

**Étape 1: ESP32**
```bash
# Dans Arduino IDE
1. Ouvrir: esp32_health_monitor/esp32_health_monitor.ino
2. Tools → Board → ESP32 Dev Module
3. Tools → Port → Sélectionner port COM
4. Sketch → Téléverser (Ctrl+U)
5. Vérifier Serial Monitor (115200 baud) → messages [OK]
```

**Étape 2: Appareillage Bluetooth**
```bash
Pour appareiller l'ESP32 sur Android:
1. Paramètres → Bluetooth → Activer
2. Rechercher "ESP32_HealthMonitor"
3. Appareiller (code initial: 1234)
```

**Étape 3: Flutter**
```bash
cd health_monitor_app
flutter pub get
flutter run
# L'app se connecte automatiquement à l'ESP32
```

**Pour plus de détails:** Voir `QUICKSTART_FR.md`

---

## 📊 Pages de l'Application

### 1️⃣ **Live Dashboard**
*Affichage temps réel de tous les paramètres*

```
┌──────────────────────────────┐
│ ❤️ Fréquence Cardiaque       │
│ 78 BPM | NORMAL              │
├──────────────────────────────┤
│ 🌡️ Température Corporelle   │
│ 36.8°C | NORMAL              │
├──────────────────────────────┤
│ 📈 Accélération              │
│ 0.5 g | NORMALE              │
├──────────────────────────────┤
│ 💡 LED d'alerte              │
│ Inactif                      │
└──────────────────────────────┘
```

### 2️⃣ **Device Connectivity**
*Gestion de la connexion Bluetooth*
- État de connexion
- Liste appareils disponibles
- Boutons Connect/Disconnect
- Test de connexion

### 3️⃣ **Health Dashboard**
*Graphiques et tendances*
- Courbes de température
- Statistiques FC
- Movennes jour/semaine

### 4️⃣ **Health History**
*Historique chronologique*
- Liste de toutes les mesures
- Filtrage par date/type
- Export données CSV

### 5️⃣ **Heart Rate Analysis**
*Analyse détaillée FC*
- Tendances temporelles
- Statistiques (min/max/moyenne)
- Recommandations médicales

### 6️⃣ **Alerts & Notifications**
*Historique des alertes*
- Toutes les alertes avec timestamp
- Détails mesures critiques
- Actions rapides (appel urgence)

---

## 🔄 Flux de Fonctionnement

### Cycle Complet (0.5 secondes)

```
1. ESP32 (acquisition capteurs)
   ↓
2. Calculs (filtrage, détection)
   ↓
3. Envoi JSON via Bluetooth Serial
   ↓
4. App Flutter (réception et parsing)
   ↓
5. Mise à jour UI temps réel
   ↓
6. Vérification alertes
   ├─→ Si normal: affichage vert
   ├─→ Si alerte: son + LED + dialogue
   └─→ Si critique: dialogue forcé + urgence
```

### Format Données JSON

```json
{
  "temperature": 36.8,
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

---

## 🧪 Tests et Validation

### Test 1: Température Normal
```
✓ Approcher main du MLX90614
✓ Affiche 36-37°C
✓ Couleur verte
✓ Son off
```

### Test 2: Fièvre Modérée
```
✓ Approcher main très proche
✓ Affiche 38-39°C
✓ Couleur orange
✓ Son d'alerte 🔔
```

### Test 3: Fièvre Élevée
```
✓ Glaçon (simulation)
✓ Affiche >39.5°C
✓ Couleur rouge
✓ LED s'allume 🔴
✓ Son urgent
✓ Dialogue critique
```

### Test 4: Chute
```
✓ Secouer ESP32 rapidement
✓ +5s immobilité
✓ Affiche chute détectée 🚨
✓ LED clignotante 🔴
✓ 3 bips urgents
✓ Dialogue avec bouton "Appeler aide"
```

**Pour les tests complets:** Voir `GUIDE_INTEGRATION_FINALE.md`

---

## ⚙️ Configuration Avancée

### Ajuster les Seuils (ESP32)

Éditer `esp32_health_monitor.ino`:

```cpp
// Seuils de température médicaux
const float TEMP_FEVER = 38.0;        // Fièvre starts
const float TEMP_HIGH_FEVER = 39.5;   // Fièvre élevée
const float TEMP_LOW = 35.0;          // Hypothermie

// Paramètres de chute
const int ACC_THRESHOLD = 18000;      // Seuil accélération
const int IMMOBILITY_TIME = 5000;     // ms confirmation

// Filtrage
const int BUFFER_SIZE = 10;           // Fenêtre moyenne
const int MEASURE_INTERVAL = 500;     // ms entre mesures
```

### Activation Modes Debug

```cpp
// Dans esp32_health_monitor.ino
#define DEBUG_MOTION    // Print accel raw
#define DEBUG_TEMP      // Print temp raw
#define DEBUG_ALERTS    // Print alert decisions
```

---

## 📚 Documentation

| Document | Contenu |
|----------|---------|
| **QUICKSTART_FR.md** | Démarrage en 5 minutes |
| **GUIDE_INTEGRATION_FINALE.md** | Documentation complète (60 pages) |
| **ESP32_CONFIGURATION.md** | Paramètres et seuils ajustables |
| **README.md** | Ce fichier |

---

## 🐛 Dépannage Courant

### ❌ "Pas de données"
```
→ Vérifier Serial Monitor de l'ESP32 (115200 baud)
→ Vérifier capteurs I2C répondent
→ Vérifier appareillage Bluetooth fait
```

### ❌ "App se referme au démarrage"
```
→ flutter clean
→ flutter pub get
→ flutter run
```

### ❌ "LED ne s'allume jamais"
```
→ Approcher main du MLX90614 (>38°C)
→ Ou secouer ESP32 5+ secondes
→ Vérifier LED physiquement en place
```

### ❌ "Alertes trop sensibles"
```
→ Augmenter TEMP_FEVER à 38.5 ou 39°C
→ Augmenter FEVER_CONFIRMATION_TIME à 15000 ms
→ Redémarrer ESP32 après modif
```

---

## 🔐 Sécurité et Confidentialité

✅ **Stockage Local**: Toutes les données restent sur le téléphone  
✅ **Chiffrement Bluetooth**: Communication BT chiffrée nativement  
✅ **Pas de serveur requis**: Fonctionnement 100% local  
⚠️ **Pour transmission réseau**: Implémenter HTTPS/TLS  

---

## 📈 Roadmap (Futures Versions)

- [ ] **v2.0**: Backend serveur avec MongoDB
- [ ] **v2.0**: Notifications push vers soignants
- [ ] **v2.0**: Export PDF du rapport médical
- [ ] **v2.1**: App Web (complément Flutter)
- [ ] **v2.1**: API REST pour intégrations tiers
- [ ] **v3.0**: Detection IA pour patterns anomalies
- [ ] **v3.0**: Support multi-patients synchronisés

---

## 👥 Contribution

Les contributions sont les bienvenues! Pour contribuer:

1. Fork le repository
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📞 Support et Contact

Pour les questions ou bugs:
- Créer une issue sur GitHub
- Consulter la FAQ dans `GUIDE_INTEGRATION_FINALE.md`
- Revérifier la section dépannage

---

## 📄 Licence

Ce projet est sous licence **MIT**. Voir le fichier `LICENSE` pour plus de détails.

---

## 🙏 Remerciements

- **Adafruit** pour les excellentes librairies MLX90614 et MPU6050
- **Flutter Team** pour l'excellent framework mobile
- **Espressif Systems** pour l'ESP32 et l'Arduino IDE support
- **Communauté open-source** pour les ressources et tutoriels

---

## 📋 Checklist Installation

- [ ] Faire un clone/download du repository
- [ ] Installer Arduino IDE + pack ESP32
- [ ] Installer Flutter 3.0+
- [ ] Appareiller ESP32 sur Android
- [ ] Téléverser le firmware ESP32
- [ ] Exécuter `flutter pub get`
- [ ] Lancer `flutter run`
- [ ] Tester une mesure simple (approcher main)
- [ ] Tester une alerte (fièvre/chute)
- [ ] Profiter! 🎉

---

**Version**: 1.0.0 (Stable)  
**Date**: Avril 2026  
**Auteur**: Développement IoT/Santé  

🏥 **Health Monitor Pro - Surveiller la santé en temps réel** 🏥

*Pour commencer: Lire `QUICKSTART_FR.md` (5 min)*
