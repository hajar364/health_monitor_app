# Configuration ESP32 - Paramètres Variables

## Seuils Médicaux (à ajuster selon les besoins)

```cpp
// ===== SEUILS DE TEMPÉRATURE =====
const float TEMP_FEVER = 38.0;        // Fièvre modérée ≥ 38°C ← Ajustable
const float TEMP_HIGH_FEVER = 39.5;   // Fièvre élevée ≥ 39.5°C ← Ajustable
const float TEMP_LOW = 35.0;          // Hypothermie < 35°C ← Ajustable
const float TEMP_NORMAL_MIN = 36.5;   // Plage normale min ← Ajustable
const float TEMP_NORMAL_MAX = 37.5;   // Plage normale max ← Ajustable

// ===== SEUILS ACCÉLÉRATION (CHUTE) =====
const int ACC_THRESHOLD = 18000;      // m/s² pour détecter impact ← Ajustable
const int IMMOBILITY_TIME = 5000;     // ms d'immobilité pour confirmer chute ← Ajustable

// ===== FILTRAGE =====
const int BUFFER_SIZE = 10;           // Taille filtre moyenne ← Ajustable
const int MEASURE_INTERVAL = 500;     // ms entre mesures ← Ajustable

// ===== CONFIRMATION FIÈVRE =====
const unsigned long FEVER_CONFIRMATION_TIME = 10000;  // ms avant alerte ← Ajustable
```

## Commandes Bluetooth Supportées

| Commande | Effet |
|----------|-------|
| `LED_ON` | Allumer LED d'alerte (GPIO12) |
| `LED_OFF` | Éteindre LED d'alerte |
| `MEASURE` | Forcer une mesure immédiate |
| `STATUS` | Demander statut de l'ESP32 |
| `SET_INTERVAL:500` | Changer intervalle mesure (ms) |

## Pins ESP32 Utilisés

```
GPIO32 ← SDA (I2C - Capteurs)
GPIO33 ← SCL (I2C - Capteurs)
GPIO12 ← LED d'alerte
TX  ← Bluetooth Serial (HC-05 RX, optionnel)
RX  ← Bluetooth Serial (HC-05 TX, optionnel)
```

## Format JSON Envoyé

```json
{
  "temperature": 36.5,           // °C - Température corporelle
  "temperatureAmbient": 25.0,    // °C - Température ambiante
  "accelX": 0.05,                // g - Accélération X
  "accelY": 0.1,                 // g - Accélération Y
  "accelZ": 0.95,                // g - Accélération Z
  "fallDetected": false,         // bool - Chute détectée?
  "feverDetected": false,        // bool - Fièvre détectée?
  "hypothermiaDetected": false,  // bool - Hypothermie détectée?
  "ledActive": false,            // bool - LED allumée?
  "status": "OK",                // string - Statut humain
  "alertStatus": "NORMAL",       // string - NORMAL ou ALERT
  "timestamp": 1234567890        // ms - Timestamp millis()
}
```

## Installation Dépendances Arduino IDE

```
Sketch → Include Library → Manage Libraries

Rechercher et installer:
1. Adafruit MLX90614
   - Auteur: Adafruit
   - Version: Latest

2. MPU6050
   - Auteur: Electronic Cats
   - Version: Latest

3. ArduinoJson
   - Auteur: Benoit Blanchon
   - Version: 6.18 ou plus

4. BluetoothSerial
   - Intégré dans ESP32 (pas besoin d'installer)
```

## Calibration

### MLX90614

La calibration usine est généralement correcte, mais si besoin:

```cpp
// Comparer avec un thermomètre de référence
// et ajuster en firmware si écart > 0.5°C
float tempCorrection = 0.0;  // Ajouter correction si besoin
float correctedTemp = mlx.readObjectTempC() + tempCorrection;
```

### MPU6050

Pour calibrer les offsets:

```cpp
// Laisser le MPU6050 immobile
// Exécuter calibration (voir Arduino MPU6050 examples)
// Noter les offsets XYZ
mpu.setXAccelOffset(-1234);  // À adapter
mpu.setYAccelOffset(-5678);
mpu.setZAccelOffset(12345);
```

## Troubleshooting Rapide

| Problème | Cause Probable | Solution |
|----------|---|---|
| Temp affiche 0°C | MLX90614 déconnecté | Vérifier I2C, adresse |
| Accel erratique | MPU6050 mal fixé | Fixer sur surface plane |
| LED ne s'allume pas | GPIO12 occupé | Changer PIN_LED |
| Pas de Bluetooth | Pin TX/RX mal configuré | Vérifier Serial.begin(115200) |
| Fausses alertes | Seuils mal ajustés | Augmenter FEVER_CONFIRMATION_TIME |

---

**Configuration ESP32 - Paramètres de Référence**
