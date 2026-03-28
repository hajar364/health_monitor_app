# Guide de Montage Sécurisé - Système IoT de Surveillance de Santé

## 📋 Composants Identifiés

| Composant | Qté | Fonction | Tension |
|-----------|-----|----------|---------|
| **ESP32** | 1 | Microcontrôleur principal | 3.3V |
| **Capteur Fréquence Cardiaque (KY-039)** | 1 | Mesure FC via LED optique | 5V → 3.3V |
| **Capteur Température/Humidité (DHT22/AM2302)** | 1 | Mesure temp. & humidité | 5V → 3.3V |
| **Capteur Accélération/Gyro (MPU6050)** | 1 | Détecte mouvements/activité | 5V → 3.3V |
| **LED Rouge** | 1 | Indicateur d'alerte | 5V |
| **Résistances Pull-up** | 3+ | Stabilisation signaux I2C | - |
| **Breadboard** | 1 | Support de connexion | - |
| **Fils Jumper** | ~30 | Connexions électriques | - |
| **Batterie 5V/Power USB** | 1 | Alimentation | 5V |

---

## ⚠️ PRÉCAUTIONS DE SÉCURITÉ ESSENTIELLES

### 1. **Alimentation**
- ✅ Utiliser TOUJOURS une alimentation stabilisée 5V (USB ou batterie)
- ❌ Ne JAMAIS connecter plus de 5V directement à l'ESP32
- ⚠️ Les broches ESP32 sont en **3.3V max** - utiliser des diviseurs de tension

### 2. **Tension des Capteurs**
- Les capteurs demandent du 5V, l'ESP32 nécessite du 3.3V
- Solution : Diviseur de tension (2 résistances) ou convertisseur logique

### 3. **Protection des Broches**
- Ne pas faire de court-circuit
- Limiter le courant avec des résistances (~220Ω pour LED)
- Éviter les connexions simultanées sur les mêmes broches

### 4. **Contacts**
- Vérifier toutes les connexions avant d'alimenter
- Éviter les fils qui se touchent
- Isoler les fils nus avec du ruban isolant

---

## 🔌 SCHÉMA DE CONNEXION DÉTAILLÉ

### **Bloc 1: Alimentation ESP32**
```
USB 5V → ESP32 PIN VIN (ou 5V)
GND → ESP32 PIN GND
```

### **Bloc 2: Capteur Fréquence Cardiaque (KY-039)**
```
KY-039 (+) → 5V (via résistance 220Ω)
KY-039 (-) → GND
KY-039 (Signal) → Diviseur de tension → ESP32 PIN 35 (ADC1_7)
```

**Diviseur de tension pour Signal:**
```
KY-039 Signal (5V) 
    ↓
  [R1 = 10kΩ]
    ↓
  ESP32 PIN 35 ← (Sortie 3.3V max)
    ↓
  [R2 = 20kΩ]
    ↓
   GND
```

### **Bloc 3: Capteur Température DHT22**
```
DHT (+) → 5V (via résistance 10kΩ pull-up)
DHT Data → ESP32 PIN 4
DHT (-) → GND
```

### **Bloc 4: Capteur Accélérométre MPU6050 (I2C)**
```
MPU SDA → ESP32 PIN 21 (I2C SDA)
MPU SCL → ESP32 PIN 22 (I2C SCL)
MPU VCC → 5V (via convertisseur 5V→3.3V ou direct)
MPU GND → GND

⚠️ Ajouter 2 résistances pull-up 10kΩ sur SDA et SCL
```

### **Bloc 5: LED d'Alerte**
```
LED (+) → 5V (via résistance 220Ω)
LED (-) → ESP32 PIN 13
```

---

## 📐 TABLEAU RÉCAPITULATIF DES BROCHES ESP32

| Broche ESP32 | Fonction | Capteur |
|--------------|----------|---------|
| VIN (5V) | Alimentation 5V | - |
| GND | Masse commune | - |
| PIN 35 | Entrée ADC (FC) | KY-039 Signal |
| PIN 4 | GPIO (DHT) | DHT22 Data |
| PIN 21 | I2C SDA | MPU6050 SDA |
| PIN 22 | I2C SCL | MPU6050 SCL |
| PIN 13 | GPIO (LED) | LED Alerte |

---

## 🛠️ ÉTAPES D'ASSEMBLAGE PHYSIQUE

### **Étape 1: Préparation**
```
1. Débrancher TOUS les appareils
2. Placer la breadboard devant vous
3. Grouper les composants par catégorie
4. Préparer les résistances et vérifier leurs valeurs
```

### **Étape 2: Implanter l'ESP32**
```
1. Insérer l'ESP32 au centre de la breadboard (côté gauche)
2. Éviter de chevaucher les rangées
3. Laisser de l'espace pour les capteurs
```

### **Étape 3: Créer les rails de puissance**
```
1. Connecter GND de la breadboard à GND de l'USB (fil noir)
2. Connecter VCC (+5V) de la breadboard à +5V de l'USB (fil rouge)
3. Vérifier avec un multimètre : 5V entre VCC et GND
```

### **Étape 4: Connecter le capteur Fréquence Cardiaque**
```
1. Placer KY-039 à droite de la breadboard
2. KY-039 (-) → rail GND
3. KY-039 (+) → [R 220Ω] → rail VCC
4. KY-039 Signal → [Diviseur de tension] → PIN 35
```

### **Étape 5: Connecter DHT22**
```
1. Placer DHT22 sur la breadboard
2. DHT (-) → rail GND
3. DHT Data → PIN 4 (+ résistance pull-up 10kΩ)
4. DHT (+) → rail VCC
```

### **Étape 6: Connecter MPU6050 (I2C)**
```
1. Placer MPU6050 sur la breadboard
2. MPU GND → rail GND
3. MPU VCC → rail VCC
4. MPU SDA → PIN 21 (+ résistance pull-up 10kΩ)
5. MPU SCL → PIN 22 (+ résistance pull-up 10kΩ)
```

### **Étape 7: Connecter LED d'Alerte**
```
1. LED (+) → [R 220Ω] → rail VCC
2. LED (-) → PIN 13
```

### **Étape 8: Vérification finale**
```
☐ Tous les fils sont bien enfoncés
☐ Pas de fils nus qui se touchent
☐ Résistances dans les bonnes valeurs
☐ Aucun court-circuit visible
☐ Les connexions I2C ont leurs pull-ups
```

---

## 💡 VÉRIFICATION AVANT ALIMENTATION

```bash
CHECKLIST:
☐ Multimètre: 0V entre VCC et GND (circuit ouvert)
☐ Tous les composants correctement placés
☐ Pas de fils qui dépassent
☐ Diviseurs de tension correctement calculés
☐ Aucune broche ESP32 directement en 5V
☐ Les contacts des capteurs sont secs
```

---

## 🔋 SCHÉMA ÉLECTRIQUE COMPLET (ASCII)

```
┌─────────────────────────────────────────────────────────┐
│                     ALIMENTATION USB 5V                  │
└──────────────┬──────────────────────────────┬────────────┘
               │ (+5V)                  (GND) │
               │                               │
        ╔══════V═══════╗                ╔═════V═════╗
        ║   +5V Rail   ║                ║  GND Rail ║
        ╚═══╤═════╤════╝                ╚═════╤═════╝
            │     │                            │
       ┌────┴┐  ┌─┴────┐                  ┌───┴───┐
       │     │  │      │                  │       │
    ┌──R──┐ │┌──R──┐  │    ┌───────────┐ │ ┌───┐ │
    │220Ω │ ││220Ω │  │    │   ESP32   │ │ │DHT│ │
    └──┬──┘ │└──┬──┘  │    │           │ │ │   │ │
       │    │   │     │    │ PIN 35    │ │ └─┬─┘ │
      LED   │   R     │    │ (ADC1_7)  │ │   │   │
       │    │  220Ω   │    │           │ │  Data│
      GND   │   │     │    │ PIN 4     │ │   │   │
             │   └─────┼──→ (GPIO)     │ │   │   │
             │         │    │ PIN 21   │ │   │   │
             │         │    │ (SDA)    │ │   │   │
             │         │    │ PIN 22   │ │   │   │
             │         │    │ (SCL)    │ │   │   │
             │         │    └─┬────────┘ │   │   │
             │    ┌────┴──────┐          │   │   │
             │ ┌──R──┐  ┌──R──┐         │   │   │
             │ │10kΩ │  │10kΩ │         │   │   │
             │ └─┬──┘  └──┬──┘          │   │   │
             └───┼────┼───┤─────────────┘   │   │
                 │    │   │                 │   │
           ┌─────┴────┴───┴──────────┬──────┴───┘
           │                         │
        ┌──R──┐                  ┌───R(Pull-up)
        │10kΩ │                  │10kΩ
        └──┬──┘                  └────┬─────
           │                          │
        ┌──V──────────────────────────V──┐
        │        MPU6050 (I2C)           │
        │  SDA─────────SCL────────VCC    │
        └────────────────────────────────┘
           GND

Legend:
R = Resistor
→ = Signal flow
V = Connection point
```

---

## 📟 CODE ARDUINO/C++ POUR ESP32

Créez ce fichier: `esp32_health_monitor.ino`

```cpp
#include <Wire.h>
#include <DHT.h>
#include <MPU6050.h>

// ========== CONFIGURATION BROCHES ==========
#define DHT_PIN 4
#define HEART_RATE_PIN 35
#define ALERT_LED_PIN 13

#define DHT_TYPE DHT22

// ========== INITIALISATION CAPTEURS ==========
DHT dht(DHT_PIN, DHT_TYPE);
MPU6050 mpu;

// ========== VARIABLES GLOBALES ==========
float heartRate = 0;
float temperature = 0;
float humidity = 0;
float accelX = 0, accelY = 0, accelZ = 0;
bool isAbnormal = false;

// ========== SETUP ==========
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n=== Démarrage Système IoT Santé ===");
  
  // Initialiser DHT22
  dht.begin();
  Serial.println("✓ DHT22 initialisé");
  
  // Initialiser MPU6050
  Wire.begin(21, 22); // SDA=21, SCL=22
  mpu.initialize();
  
  if (!mpu.testConnection()) {
    Serial.println("✗ Erreur: MPU6050 non détecté!");
  } else {
    Serial.println("✓ MPU6050 initialisé");
  }
  
  // Configurer LED d'alerte
  pinMode(ALERT_LED_PIN, OUTPUT);
  digitalWrite(ALERT_LED_PIN, LOW);
  
  // Configurer ADC pour fréquence cardiaque
  pinMode(HEART_RATE_PIN, INPUT);
  
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.println("Système prêt - Acquisition en cours...\n");
}

// ========== FONCTION: MESURER FRÉQUENCE CARDIAQUE ==========
void measureHeartRate() {
  // Moyenne sur 100 lectures (2 secondes)
  int rawValue = 0;
  for (int i = 0; i < 100; i++) {
    rawValue += analogRead(HEART_RATE_PIN);
    delay(20);
  }
  rawValue /= 100;
  
  // Convertir en BPM (calibration à ajuster selon votre capteur)
  // Formule empirique: BPM = (rawValue / 1024) * 200
  heartRate = (rawValue / 1024.0) * 200.0;
  
  // Filtre: éliminer les valeurs aberrantes
  if (heartRate < 30 || heartRate > 200) {
    heartRate = 0;
  }
}

// ========== FONCTION: MESURER TEMPÉRATURE/HUMIDITÉ ==========
void measureTemperatureHumidity() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  
  if (!isnan(h) && !isnan(t)) {
    humidity = h;
    temperature = t;
  } else {
    Serial.println("⚠️  Erreur DHT22 - données invalides");
  }
}

// ========== FONCTION: MESURER ACCÉLÉRATION ==========
void measureAcceleration() {
  int16_t ax, ay, az;
  mpu.getAcceleration(&ax, &ay, &az);
  
  // Convertir en g (1g ≈ 16384 LSB)
  accelX = ax / 16384.0;
  accelY = ay / 16384.0;
  accelZ = az / 16384.0;
}

// ========== FONCTION: DÉTECTION D'ANOMALIES ==========
void detectAnomalies() {
  isAbnormal = false;
  String reason = "";
  
  // Critère 1: Fréquence cardiaque anormale
  if (heartRate > 0 && (heartRate < 40 || heartRate > 120)) {
    isAbnormal = true;
    reason += "FC anormale (" + String(heartRate, 1) + " BPM) | ";
  }
  
  // Critère 2: Température élevée
  if (temperature > 37.5) {
    isAbnormal = true;
    reason += "Température élevée (" + String(temperature, 1) + "°C) | ";
  }
  
  // Critère 3: Inactivité prolongée (toutes les accélérations proches de 0)
  float totalAccel = sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ);
  if (totalAccel < 0.5 && totalAccel > 0.8) {
    isAbnormal = true;
    reason += "Activité anormale | ";
  }
  
  // Contrôler LED d'alerte
  digitalWrite(ALERT_LED_PIN, isAbnormal ? HIGH : LOW);
  
  if (isAbnormal) {
    Serial.println("\n🚨 ALERTE DÉTECTÉE:");
    Serial.println("Raison: " + reason);
  }
}

// ========== FONCTION: AFFICHER DONNÉES ==========
void displayData() {
  Serial.print("\r📊 | FC: ");
  Serial.print(heartRate, 1);
  Serial.print(" BPM | Temp: ");
  Serial.print(temperature, 1);
  Serial.print("°C | Hum: ");
  Serial.print(humidity, 1);
  Serial.print("% | Accel: ");
  Serial.print(sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ), 2);
  Serial.print(" g | Alerte: ");
  Serial.print(isAbnormal ? "🔴 OUI" : "🟢 NON");
}

// ========== FONCTION: ENVOYER VERS APPLICATION MOBILE ==========
void sendToMobileApp() {
  // Format JSON pour la communication avec Flutter
  String jsonData = "{\"heartRate\":";
  jsonData += heartRate;
  jsonData += ",\"temperature\":";
  jsonData += temperature;
  jsonData += ",\"humidity\":";
  jsonData += humidity;
  jsonData += ",\"accelX\":";
  jsonData += accelX;
  jsonData += ",\"accelY\":";
  jsonData += accelY;
  jsonData += ",\"accelZ\":";
  jsonData += accelZ;
  jsonData += ",\"isAbnormal\":";
  jsonData += (isAbnormal ? "true" : "false");
  jsonData += ",\"reason\":\"";
  
  if (heartRate > 120 || heartRate < 40) jsonData += "FC anormale;";
  if (temperature > 37.5) jsonData += "Temperature élevée;";
  
  jsonData += "\"}";
  
  Serial.println("\n📤 Envoi JSON: " + jsonData);
}

// ========== LOOP PRINCIPAL ==========
void loop() {
  // Acquisition toutes les secondes
  measureHeartRate();
  measureTemperatureHumidity();
  measureAcceleration();
  
  // Analyse
  detectAnomalies();
  
  // Affichage
  displayData();
  
  // Envoi vers app mobile (toutes les 5 secondes)
  static unsigned long lastSend = 0;
  if (millis() - lastSend > 5000) {
    sendToMobileApp();
    lastSend = millis();
  }
  
  delay(1000); // Attendre 1 seconde avant la prochaine boucle
}
```

---

## 📱 INTÉGRATION AVEC L'APPLICATION FLUTTER

Mettez à jour le fichier `lib/services/esp32_service.dart`:

```dart
// À intégrer dans votre service ESP32
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ESP32Service {
  BluetoothConnection? _connection;
  
  // Connecter au capteur via Bluetooth
  Future<bool> connectToESP32(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      print('✓ Connecté à ESP32: $address');
      return true;
    } catch (e) {
      print('✗ Erreur connexion: $e');
      return false;
    }
  }
  
  // Écouter les données du capteur
  Stream<HealthData> getHealthDataStream() async* {
    _connection?.input?.listen((Uint8List data) {
      try {
        String jsonString = String.fromCharCodes(data);
        Map<String, dynamic> json = jsonDecode(jsonString);
        
        HealthData healthData = HealthData(
          heartRate: json['heartRate']?.toDouble() ?? 0,
          temperature: json['temperature']?.toDouble() ?? 0,
          humidity: json['humidity']?.toDouble() ?? 0,
          timestamp: DateTime.now(),
          status: json['isAbnormal'] ? 'ALERT' : 'NORMAL',
          reason: json['reason'] ?? '',
        );
        
        yield healthData;
      } catch (e) {
        print('Erreur parsing JSON: $e');
      }
    });
  }
}
```

---

## ✅ CHECKLIST DE SÉCURITÉ FINALE

```
AVANT DE BRANCHER:
☐ Toutes les connexions vérifiées
☐ Pas de fils nus
☐ Diviseurs de tension correctement placés
☐ Résistances pull-up sur I2C
☐ LED avec résistance 220Ω
☐ Pas de court-circuit

APRÈS LE PREMIER DÉMARRAGE:
☐ Vérifier les lectures des capteurs en Serial Monitor
☐ Tester la LED d'alerte
☐ Calibrer si nécessaire les seuils d'anomalie
☐ Tester la communication Bluetooth

MAINTENANCE:
☐ Nettoyer les contacts mensuellement
☐ Vérifier les connexions tous les 3 mois
☐ Remplacer les piles/batterie quand voltage < 4.5V
```

---

## 🔧 DÉPANNAGE COURANT

| Problème | Cause probable | Solution |
|----------|-----------------|----------|
| ESP32 ne s'allume pas | Pas d'alimentation | Vérifier USB/batterie |
| Capteurs ne répondent pas | Connexion I2C faible | Ajouter pull-ups 10kΩ |
| LED allumée en permanence | Faux positifs détection | Ajuster seuils anomalie |
| Données incohérentes | Bruit électromagnétique | Ajouter condensateurs 100nF |
| Déconnexion Bluetooth | Portée insuffisante | Placer HC-05 plus près |

---

## 📞 Support

Pour des questions:
1. Consulter le datasheet de chaque composant
2. Vérifier avec multimètre
3. Réduire les connexions complexes à une simple boucle d'essai
4. Tester chaque capteur individuellement

**⚠️ IMPORTANT**: Veuillez consulter un électronicien si vous n'êtes pas sûr de vos connexions!
