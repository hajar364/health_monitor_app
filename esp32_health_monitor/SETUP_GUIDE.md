# Phase 6 - Firmware ESP32 Setup Guide

## 📋 Table des Matières
1. [Pré-requis](#pré-requis)
2. [Montage Hardware](#montage-hardware)
3. [Installation Arduino IDE](#installation-arduino-ide)
4. [Configuration WiFi](#configuration-wifi)
5. [Compilation & Upload](#compilation--upload)
6. [Tests](#tests)
7. [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requis

**Hardware:**
- ✅ ESP32 Development Board
- ✅ MPU6050 (Accéléromètre + Gyroscope)
- ✅ MLX90614 (Capteur thermique)
- ✅ Breadboard + Jumpers
- ✅ USB Cable pour ESP32

**Software:**
- Arduino IDE 2.x ou PlatformIO
- Drivers CH340 (USB to Serial)
- Python 3.8+ (optionnel pour platformio)

---

## 🔌 Montage Hardware

### Schéma de Connexion I2C

```
ESP32          MPU6050 + MLX90614
===================================
GPIO21 (SDA) ──→ SDA
GPIO22 (SCL) ──→ SCL
3.3V        ──→ VCC
GND         ──→ GND
```

### Broches GPIO
| Composant | Pin ESP32 | Description |
|-----------|-----------|-------------|
| MPU6050/MLX90614 (SDA) | GPIO21 | I2C Data |
| MPU6050/MLX90614 (SCL) | GPIO22 | I2C Clock |
| LED Alerte | GPIO12 | Output (alerte chute) |
| Bouton Test | GPIO13 | Input (test simulation) |
| GND | GND | Ground commun |
| 3.3V | 3V3 | Power commun |

### Adresses I2C
- **MPU6050**: 0x68 (par défaut)
- **MLX90614**: 0x5A (par défaut)

---

## 💻 Installation Arduino IDE

### 1. Installer Arduino IDE 2.x
https://www.arduino.cc/en/software

### 2. Ajouter support ESP32
**File → Preferences → Additional Board Manager URLs**

Ajoute: `https://dl.espressif.com/dl/package_esp32_index.json`

### 3. Installer ESP32 Board Manager
**Tools → Board → Board Manager**
- Recherche "esp32"
- Clique "Install" (version 2.0+)

### 4. Sélectionner Board
**Tools → Board → ESP32 Dev Module**

---

## 📡 Configuration WiFi

### Éditer le fichier `.ino`

Ouvre `esp32_health_monitor.ino` ligne 35-36:

```cpp
const char* SSID = "ton_reseau_wifi";      // ← Remplace
const char* PASSWORD = "ton_mot_de_passe"; // ← Remplace
```

**Exemple:**
```cpp
const char* SSID = "Orange-123";
const char* PASSWORD = "abc123xyz456";
```

---

## 🚀 Compilation & Upload

### Arduino IDE

**Étape 1: Sélectionner Port COM**
- Branche ESP32 en USB
- **Tools → Port → COM3** (ou le tien)

**Étape 2: Compiler**
- **Sketch → Verify/Compile** (Ctrl+Alt+R)
- Attends la fin (vert = OK)

**Étape 3: Upload**
- **Sketch → Upload** (Ctrl+U)
- Attends "Leaving... Hard resetting via RTS pin"

**Sortie Expected:**
```
Leaving...
Hard resetting via RTS pin...
```

### PlatformIO (Alternative)

```bash
cd esp32_health_monitor

# Compiler
pio run

# Upload
pio run -t upload

# Monitorer logs
pio device monitor --baud 115200
```

---

## 🧪 Tests

### 1. Vérifier Connexion Série

**Arduino IDE → Tools → Serial Monitor**
- Sélectionne **115200 baud**
- Devrait afficher:

```
=== FALL DETECTION SYSTEM ===
✅ MPU6050 initialisé
✅ MLX90614 initialisé
🌐 Connexion WiFi: Orange-123
✅ Connecté!
📍 IP: 192.168.1.100
✅ Serveur TCP démarré sur port 5000
```

### 2. Tester I2C

Si erreur MPU6050/MLX90614:
```
❌ MPU6050 non trouvé!
❌ MLX90614 non trouvé!
```

**Vérifier:**
1. Broches SDA/SCL correctes (21/22)
2. Voltage (3.3V)
3. Connexions solides

### 3. Tester WiFi

Le terminal affichera:
```
🔛 Bridging...
📡 WiFi connecté! 
📍 IP: 192.168.1.XX
✅ Serveur TCP démarré
```

### 4. Tester Commandes TCP

**À partir d'un autre PC:**

```bash
# SSH vers le ESP32
telnet 192.168.1.100 5000

# Teste commandes
PING
STATUS
LED_ON
LED_OFF
```

---

## 📊 Données Transmises

Format JSON reçu toutes les 100ms (~10Hz):

```json
{
  "timestamp": 1713282600,
  "accel": {
    "x": 0.12,
    "y": -0.05,
    "z": 9.81
  },
  "gyro": {
    "x": 2.1,
    "y": -1.3,
    "z": 0.8
  },
  "temperature": 36.5,
  "isFalling": false,
  "signal_strength": -52
}
```

---

## 🚨 Troubleshooting

### "COM port not found"
- Branche ESP32 en USB
- Arduino IDE → Tools → Port (refresh si besoin)
- Installe driver CH340 si "Unknown USB Device"

### "Upload timeout"
- Nettoie le boot: maintiens BOOT + RST 2 sec
- Change USB cable (charge vs data)
- Reduced upload speed: Tools → Upload Speed → 115200

### "MPU6050 not found"
- Vérifie broches SDA (21) / SCL (22)
- I2C pull-up resistors? (10kΩ recommandé)
- Adresse I2C: `i2cscanner` sketch

### "WiFi connection failed"
- Vérifie SSID/PASSWORD corrects
- WiFi 2.4GHz uniquement (pas 5GHz)
- Distance WiFi OK?

### "No data from sensors"
- Vérifie I2C connection
- Serial Monitor montre les capteurs initialisés?
- Restart ESP32 (RST button)

---

## 📲 Intégration avec Flutter App

**URL de connexion:**
```
IP: 192.168.1.100
Port: 5000
```

**Flutter Settings:**
- Onglet 4 (Settings)
- WiFi IP/Port
- Connect

**Expected:**
```
✅ Connecté
📡 Receiving data...
```

---

## 🔋 Puissance

**Consommation approx:**
- Idle: ~40mA
- WiFi actif: ~80-120mA
- Chute détectée + LED: ~150mA

**Battery (si mobile):**
- Batterie 5000mAh = ~40-50 heures runtime

---

## 📝 Notes Finales

- ✅ Port TCP 5000 ouvert (changer si besoin)
- ✅ JSON 256 bytes par message
- ✅ Interval 100ms = 10Hz (ajustable ligne 185)
- ✅ LED clignote si chute détectée
- ✅ Serial logging pour debug
