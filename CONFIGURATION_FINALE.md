# 🔧 GUIDE DE CONFIGURATION FINALE

## Étape 1️⃣: Installer Arduino IDE et les bibliothèques

### Pour Windows:
```bash
1. Télécharger Arduino IDE depuis: https://www.arduino.cc/en/software
2. Installer ESP32 Board Support:
   - Arduino IDE → Fichier → Préférences
   - URL supplémentaires pour gestionnaires de cartes:
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   - Outils → Gestionnaire de cartes → Chercher "ESP32"
   - Installer "esp32 by Espressif Systems"
```

### Installer les bibliothèques nécessaires:
```bash
Arduino IDE → Sketch → Inclure une bibliothèque → Gérer les bibliothèques

Chercher et installer:
□ DHT by Adafruit (pour DHT22)
□ Adafruit Unified Sensor
□ MPU6050 by electroniccats
□ Wire (inclus par défaut)
```

---

## Étape 2️⃣: Télécharger le code Arduino

1. Copier le fichier `esp32_health_monitor/esp32_health_monitor.ino` du projet
2. Ouvrir dans Arduino IDE
3. Sélectionner la carte: `Outils → Carte → ESP32-DEV KIT-C`
4. Sélectionner le port COM
5. Cliquer "Téléverser" (→)

---

## Étape 3️⃣: Vérifier le bon fonctionnement

### Dans Arduino IDE - Moniteur Série:
```
1. Outils → Moniteur Série
2. Baudrate: 115200
3. Vous devriez voir:
   
╔═══════════════════════════════════════════╗
║   SYSTÈME IoT SURVEILLANCE SANTÉ v1.0    ║
║  Architecture distribuée avec explicabilité  ║
╚═══════════════════════════════════════════╝

[INIT] Initialisation des capteurs...
[✓] DHT22 initialisé sur GPIO4
[✓] MPU6050 initialisé (Adresse: 0x68)
[✓] Capteur Fréquence Cardiaque initialisé sur GPIO35

[INIT] === SYSTÈME PRÊT ===
Acquisition de données en cours...

📊 [FC: 72 BPM | T: 36.8°C | H: 45% | Accel: 1.02g | Alert: 🟢]
📊 [FC: 73 BPM | T: 36.8°C | H: 45% | Accel: 0.98g | Alert: 🟢]
...
```

---

## Étape 4️⃣: Configuration Flutter

### Mettre à jour `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_bluetooth_serial: ^0.4.0  # Pour Bluetooth
  # ... autres dépendances

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Puis dans terminal:
```bash
flutter pub get
```

---

## Étape 5️⃣: Calibrer les seuils d'anomalies

### Dans le code `esp32_health_monitor.ino`:

```cpp
// Modifier ces valeurs selon vos besoins:

#define HEART_RATE_MIN 40          // BPM - Seuil bas
#define HEART_RATE_MAX 120         // BPM - Seuil haut
#define TEMP_NORMAL_MAX 37.5       // °C - Température normale max
#define TEMP_FEVER_MIN 38.0        // °C - Début fièvre
```

---

## 📊 Architecture du système (Diagramme)

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPTEURS PHYSIQUES                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. KY-039                2. DHT22           3. MPU6050      │
│  (Freq Cardiaque)         (Temp/Humid)       (Accel/Gyro)    │
│     Signal → ADC35          GPIO4 → I2C      I2C → GPIO21/22 │
│     5V → Divisor                                              │
│                                                               │
└────────────┬─────────────────────+──────────────┬────────────┘
             │                     │              │
             └─────────────────────┼──────────────┘
                                   │
                        ┌──────────V──────────┐
                        │    ESP32 IoT        │
                        │  Microcontroller    │
                        │   (Montage)         │
                        └──────────┬──────────┘
                                   │
                        ┌──────────V──────────────────────┐
                        │  ACQUISITION & ANALYSE LOCALE   │
                        │  ✓ Lecture capteurs (1Hz)       │
                        │  ✓ Détection anomalies          │
                        │  ✓ Explication IA locale        │
                        │  ✓ Formatting JSON              │
                        └──────────┬──────────────────────┘
                                   │
                   ┌───────────────┼───────────────┐
                   │               │               │
            ┌──────V────────┐  ┌──V──────────┐  ┌─V─────────┐
            │ Bluetooth HC05│  │  LED Alerte │  │Serial USB │
            │  (Wireless)   │  │   (GPIO13)  │  │(Monitoring)
            └──────┬────────┘  └─────────────┘  └───────────┘
                   │
        ┌──────────V──────────┐
        │  📱 APPLICATION     │
        │    FLUTTER          │
        │                     │
        │ • Affichage santé   │
        │ • Historique        │
        │ • Alertes           │
        │ • Explication IA    │
        └─────────────────────┘
```

---

## 🧪 TESTS DE VALIDATION

### Test 1️⃣: Capteur Fréquence Cardiaque
```
Serial Monitor:
FC: ???  <- Si 0, il n'y a pas de signal
FC: 65-75 <- Normal au repos
FC: 120+  <- Détecte l'exercice
```

### Test 2️⃣: Capteur Température
```
Placer votre doigt sur le capteur DHT22:
Temp change progressivement (36-37°C)
```

### Test 3️⃣: Capteur Accélération
```
Bouger la breadboard:
Accel: 1.0g <- Normal (statique)
Accel: 2.0g <- Mouvement modéré
Accel: 3.0g+ <- Mouvement rapide
```

### Test 4️⃣: Alerte anormale
```
Appuyer sur BUTTON_TEST_PIN (GPIO14):
Mode TEST activé
→ FC passe à 150 BPM (Tachycardie)
→ Température 38.5°C (Fièvre)
→ 🚨 ALERTE SANTÉ 🚨 s'affiche
→ LED rouge clignote 3 fois
```

---

## 🔌 TABLEAU FINAL DE CÂBLAGE

| Composant | Broche ESP32 | Couleur fil | Fonction |
|-----------|--------------|------------|----------|
| KY-039 (+) | VCC (5V) | Rouge | Alimentation capteur |
| KY-039 (-) | GND | Noir | Masse |
| KY-039 Signal | GPIO35 | Jaune | Entrée ADC |
| DHT22 VCC | VCC (5V) | Rouge | Alimentation capteur |
| DHT22 GND | GND | Noir | Masse |
| DHT22 Data | GPIO4 | Bleu | Signal données |
| MPU SDA | GPIO21 | Orange | I2C Data |
| MPU SCL | GPIO22 | Vert | I2C Clock |
| MPU VCC | VCC (5V) | Rouge | Alimentation |
| MPU GND | GND | Noir | Masse |
| LED (+) | VCC (5V) | Rouge | Alimentation (via 220Ω) |
| LED (-) | GPIO13 | Noir | Masse |

---

## 📋 CHECKLIST AVANT LANCEMENT

```
ASSEMBLAGE PHYSIQUE:
☐ Breadboard bien placée et stable
☐ ESP32 inséré correctement (pas de broche ploiée)
☐ Tous les fils enfoncés jusqu'au bout
☐ Pas de fils nus qui se touchent
☐ Résistances dans les bonnes positions
☐ Diviseur de tension pour KY-039 = 10kΩ + 20kΩ
☐ Pull-ups 10kΩ sur SDA et SCL
☐ LED avec résistance 220Ω
☐ Aucun court-circuit visible

LOGICIEL:
☐ Arduino IDE avec esp32 board installée
☐ Bibliothèques DHT et MPU6050 téléchargées
☐ Code téléversé sur ESP32 sans erreurs
☐ Moniteur série affiche les données
☐ Flutter app compilée et testée

MESURES:
☐ Multimètre: 5V entre VCC et GND
☐ Multimètre: 3.3V sur les signaux I2C
☐ Pas de 5V directement sur les GPIO du ESP32
☐ Tous les capteurs envoient des données dans le moniteur
```

---

## 🆘 DÉPANNAGE RAPIDE

### ESP32 ne démarre pas
```
1. Vérifier l'alimentation USB (LED bleue doit être allumée)
2. Essayer: Arduino IDE → Outils → Effacer la flash
3. Réinstaller le driver CH340 pour Windows
```

### DHT22 affiche "Erreur DHT22"
```
1. Vérifier la connexion GPIO4
2. Ajouter condensateur 100nF entre VCC et GND (stabilise)
3. Mettre pull-up 10kΩ sur la ligne Data
```

### MPU6050 "non détecté"
```
1. Serial print "✗ Erreur: MPU6050 non détecté!"
2. Vérifier: SDA→GPIO21, SCL→GPIO22
3. Ajouter 2 résistances pull-up 10kΩ sur SDA et SCL
4. Scanner I2C: https://github.com/espressif/arduino-esp32/blob/master/libraries/Wire/examples/i2c_scanner/i2c_scanner.ino
```

### KY-039 affiche 0 BPM
```
1. Vérifier que le diviseur de tension est correct
2. Utiliser multimètre pour mesurer tension sur GPIO35
3. Tester avec Arduino IDE: Serial.println(analogRead(35));
4. Calibrer si nécessaire la constante multiplicateur
```

### LED ne clignote pas lors d'alerte
```
1. Vérifier connexion GPIO13
2. Tester manuellement: pinMode(13, OUTPUT); digitalWrite(13, HIGH);
3. Vérifier la polarité de la LED (longue broche = +)
4. Remplacer la résistance 220Ω si brûlée
```

---

## 📞 RESSOURCES UTILES

- **Datasheet ESP32**: https://www.espressif.com/
- **Datasheet DHT22**: https://www.sparkfun.com/datasheets/Sensors/Temperature/DHT22.pdf
- **MPU6050 Guide**: https://www.invensense.com/
- **I2C Scanner**: https://github.com/espressif/arduino-esp32/blob/master/libraries/Wire/examples/i2c_scanner/

---

**Vous êtes prêt! 🚀 Bonne programmation!**
