# 🏥 Health Monitor - IoT Système de Surveillance de Santé

## 📋 Vue d'ensemble

Système de surveillance de santé IoT complet fondé sur:
- **Capteurs**: Fréquence cardiaque (KY-039), Température/Humidité (DHT22), Accélération (MPU6050)
- **Microcontrôleur**: ESP32 (analyse locale)
- **Application**: Flutter (interface mobile)
- **Architecture**: Distribuée avec interprétabilité des décisions

### ✨ Caractéristiques

✅ Surveillance en temps réel des vitals (FC, température, activité)  
✅ Détection d'anomalies avec explication locale  
✅ Alertes visuelles (LED) et en app  
✅ Communication Bluetooth vers smartphone  
✅ Historique des données  
✅ Interface réactive et intuitive  

---

## 🚀 DÉMARRAGE RAPIDE

### Pour les experts (< 30 min):
→ Voir: **[QUICKSTART.md](QUICKSTART.md)**

### Pour tous (2-4 heures):
→ Voir: **[INDEX_COMPLET.md](INDEX_COMPLET.md)** (navigation complète)

### Guides détaillés disponibles:

| Document | Objectif | Temps |
|----------|----------|-------|
| **[GUIDE_MONTAGE_SECURISE.md](GUIDE_MONTAGE_SECURISE.md)** | Vue d'ensemble complète du projet | 40 min |
| **[MONTAGE_VISUEL_BREADBOARD.md](MONTAGE_VISUEL_BREADBOARD.md)** | Assembler le circuit étape par étape | 45 min |
| **[CONFIGURATION_FINALE.md](CONFIGURATION_FINALE.md)** | Installer Arduino IDE et configurer Flutter | 20 min |
| **[GUIDE_DEPANNAGE_COMPLET.md](GUIDE_DEPANNAGE_COMPLET.md)** | Déboguer les problèmes courants | Variable |

---

## 📦 Composants matériels

```
Électronique:
□ ESP32-DevKit-C (microcontrôleur)
□ Breadboard 830 points
□ Capteur FC KY-039 (LED infrarouge)
□ Capteur DHT22 (température/humidité)
□ Capteur MPU6050 (accélérométre/gyro)
□ LED Rouge 3/5mm
□ Résistances: 2x 10kΩ (pull-up), 1x 20kΩ (diviseur), 1x 220Ω (LED)
□ ~50 fils Jumper mâle-femelle
□ Alimentation USB 5V

Outils:
□ Arduino IDE
□ Multimètre
□ Flutter SDK
```

---

## 🏗️ Architecture du système

```
┌──────────────────────────────────────┐
│         CAPTEURS PHYSIQUES            │
│  KY-039  │  DHT22  │  MPU6050  │ LED │
└────┬─────────┬────────┬────────┬─────┘
     │         │        │        │
     └─────────┼────────┼────────┘
               │        │
       ┌───────V────────V──────────┐
       │   ESP32 MICROCONTRÔLEUR   │
       │  ✓ Acquisition 1Hz        │
       │  ✓ Analyse locale         │
       │  ✓ Détection anomalies    │
       │  ✓ Explication IA         │
       │  ✓ Format JSON            │
       └──────────┬────────────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
   ┌────V────┐ ┌─V────┐ ┌──V───┐
   │Bluetooth│ │ LED  │ │Serial │
   │ HC-05   │ │Alert │ │ USB   │
   └────┬────┘ └──────┘ └───────┘
        │
   ┌────V──────────────┐
   │   FLUTTER APP     │
   │  • Dashboard      │
   │  • Historique     │
   │  • Alertes        │
   │  • Statistiques   │
   └───────────────────┘
```

---

## 📂 Structure du projet

```
health_monitor_app/
├── 📄 README.md (ce fichier)
├── 📄 INDEX_COMPLET.md ← Navigation principale
├── 📄 QUICKSTART.md ← Pour les experts
│
├── 📋 GUIDE_MONTAGE_SECURISE.md
├── 📋 MONTAGE_VISUEL_BREADBOARD.md
├── 📋 CONFIGURATION_FINALE.md
├── 📋 GUIDE_DEPANNAGE_COMPLET.md
│
├── 💾 esp32_health_monitor/
│   └── esp32_health_monitor.ino ← Code Arduino principal
│
├── 📱 lib/ (Dart/Flutter)
│   ├── main.dart
│   ├── models/
│   │   └── health_data.dart (MIS À JOUR)
│   └── services/
│       └── esp32_service.dart (MIS À JOUR)
│
├── android/, ios/, windows/, web/, macos/, linux/
│   └── [Configuration plateforme Flutter]
│
└── pubspec.yaml
```

---

## ⚙️ Configuration

### 1. Hardware (Breadboard)
Voir: **[MONTAGE_VISUEL_BREADBOARD.md](MONTAGE_VISUEL_BREADBOARD.md)**

### 2. Arduino IDE
```bash
✓ Installer Arduino IDE
✓ Ajouter ESP32 Board Support
✓ Installer librairies: DHT, MPU6050
✓ Téléverser esp32_health_monitor.ino
✓ Vérifier Serial Monitor (115200 baud)
```

### 3. Flutter
```bash
flutter pub get
flutter run -d R58T90QBQMM  # Pour l'appareil Android spécifique
```

---

## 🧪 Tests

### Test 1: Capteur FC
```
Serial Monitor doit afficher:
FC: 65-75 BPM (au repos)
FC: 100+ BPM (en bougeant)
```

### Test 2: Alerte
Appuyer sur GPIO14:
```
Résultat attendu:
→ LED clignote 3 fois
→ Message d'alerte dans Serial
→ App Flutter affiche l'alerte
```

### Test 3: App Flutter
```
→ Doit afficher les données en temps réel
→ Interface réactive (< 1 sec de latence)
→ Historique se peuple
```

---

## 🔧 Calibration

### Ajuster les seuils d'anomalies

Dans `esp32_health_monitor.ino`:

```cpp
// Seuils FC (BPM)
#define HEART_RATE_MIN 40       // ← Augmenter si trop d'alertes
#define HEART_RATE_MAX 120

// Seuils Température (°C)
#define TEMP_NORMAL_MAX 37.5
#define TEMP_FEVER_MIN 38.0

// Seuils Accélération (g)
#define ACCEL_NORMAL_MIN 0.5
#define ACCEL_NORMAL_MAX 3.0
```

---

## 🆘 Dépannage

| Problème | Solution |
|----------|----------|
| Rien ne marche | Vérifier multimètre 5V entre VCC et GND |
| ESP32 ne détecte pas MPU6050 | Ajouter pull-ups 10kΩ sur I2C |
| DHT22 invalide | Vérifier pull-up sur broche Data |
| KY-039 = 0 BPM | Vérifier diviseur de tension (10k + 20k) |
| Serial Monitor charabia | Changer baudrate à 115200 |

👉 **Consulter: [GUIDE_DEPANNAGE_COMPLET.md](GUIDE_DEPANNAGE_COMPLET.md)**

---

## 📊 Données & JSON

Format des données envoyées par ESP32:

```json
{
  "heartRate": 72.5,
  "temperature": 36.8,
  "humidity": 45.0,
  "accelX": 0.05,
  "accelY": -0.1,
  "accelZ": 1.02,
  "isAbnormal": false,
  "reason": "Santé stable",
  "timestamp": 1648392000000
}
```

---

## 📡 Communication

### Modes supportés:

1. **Bluetooth HC-05** ← Recommandé pour mobile
2. **Serial USB** ← Pour debug/développement
3. **WiFi ESP32 interne** ← Mode avancé

---

## 🎓 Concepts clés

### Détection d'anomalies en 3 étapes:

1. **Acquisition** (1 Hz)
   ```
   ESP32 lit tous les capteurs
   ```

2. **Analyse** (Immédiate)
   ```
   Compare aux seuils définis
   Détecte écarts
   ```

3. **Explication** (Locale)
   ```
   Génère message explicatif
   Déclenche alerte
   Envoie à l'app
   ```

---

## 📚 Ressources

- [ESP32 Official](https://www.espressif.com/)
- [Arduino IDE](https://www.arduino.cc/en/software)
- [Flutter Docs](https://flutter.dev/docs)
- [MPU6050 Datasheet](https://invensense.tdk.com/)
- [DHT22 Datasheet](https://www.sparkfun.com/datasheets/Sensors/Temperature/DHT22.pdf)

---

## 📝 Licence

Projet éducatif - Libre d'utilisation

---

## ✅ Checklist avant de commencer

- [ ] Tous les composants en main
- [ ] Arduino IDE installé
- [ ] Bibliothèques téléchargées (DHT, MPU6050)
- [ ] Flutter SDK prêt
- [ ] Multimètre disponible
- [ ] 2-4 heures libres
- [ ] Zone de travail propre et organisée

---

## 🚀 PRÊT?

**Commencez par**: [INDEX_COMPLET.md](INDEX_COMPLET.md)

**Questions?** Consultez: [GUIDE_DEPANNAGE_COMPLET.md](GUIDE_DEPANNAGE_COMPLET.md)

**Impatient?** Voir: [QUICKSTART.md](QUICKSTART.md)

---

**Bon développement! 🎉**

*Système créé pour la surveillance de santé avec IA locale*  
*© 2026 - v1.0*
