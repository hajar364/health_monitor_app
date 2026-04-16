/*
 * ╔═══════════════════════════════════════════════════════╗
 * ║   SYSTÈME DE DÉTECTION DE CHUTE - FALL DETECTION     ║
 * ║              ESP32 + WiFi/TCP Server                  ║
 * ╚═══════════════════════════════════════════════════════╝
 * 
 * HARDWARE:
 *   - Microcontrôleur: ESP32 DevKit v1
 *   - MPU6050: Accéléromètre + Gyroscope (I2C 0x68)
 *   - MLX90614: Capteur thermique sans contact (I2C 0x5A)
 *   - LED: GPIO12 (alerte visuelle)
 * 
 * COMMUNICATION:
 *   - WiFi: 2.4GHz (WPA2)
 *   - Protocol: TCP Socket Server
 *   - Port: 5000
 *   - Débit: ~10 Hz (données toutes les 100ms)
 *   - Format: JSON
 * 
 * WIRING:
 *   ESP32      MPU6050/MLX90614
 *   ┌─────────────────────────────┐
 *   │ GPIO21 (SDA) ──→ SDA        │
 *   │ GPIO22 (SCL) ──→ SCL        │
 *   │ 3.3V ────────→ VCC        │
 *   │ GND ─────────→ GND        │
 *   │ GPIO12 ──────→ LED        │
 *   └─────────────────────────────┘
 * 
 * INSTALLATION:
 *   1. Arduino IDE → Sketch → Include Library → Manage Libraries
 *   2. Installer: "MPU6050" par InvenSense
 *   3. Installer: "Adafruit MLX90614 Library"
 *   4. Installer: "ArduinoJson" par Benoit Blanchon
 *   5. Outils → Type de carte: ESP32 Dev Module
 *   6. Outils → Port: COM3 (ou votre port)
 * 
 * UPLOAD:
 *   Click: → (Play) pour compiler
 *   Click: → (Upload) pour téléverser
 */

#include <Wire.h>
#include <WiFi.h>
#include <Adafruit_MLX90614.h>
#include <MPU6050.h>
#include <ArduinoJson.h>

// ═════════════════════════════════════════════════════════
// 📡 CONFIGURATION WiFi - À MODIFIER
// ═════════════════════════════════════════════════════════
const char* WIFI_SSID = "your_wifi_ssid";        // ← CHANGER
const char* WIFI_PASSWORD = "your_wifi_password"; // ← CHANGER
const uint16_t TCP_PORT = 5000;                  // Port serveur

WiFiServer server(TCP_PORT);
WiFiClient serverClient;

// ═════════════════════════════════════════════════════════
// 🔌 BROCHES GPIO
// ═════════════════════════════════════════════════════════
#define I2C_SDA 21              // I2C Data Line
#define I2C_SCL 22              // I2C Clock Line
#define ALERT_LED_PIN 12        // LED alerte visuelle
#define BUTTON_PIN 13           // Bouton test (optionnel)

// ═════════════════════════════════════════════════════════
// 🎛️ SEUILS DE DÉTECTION
// ═════════════════════════════════════════════════════════
#define ACCEL_THRESHOLD_G 1.5         // Seuil accélération (g)
#define GYRO_THRESHOLD_DPS 100.0      // Seuil rotation (°/s)
#define TEMP_ALERT_HIGH 38.5          // Température critique haute
#define TEMP_ALERT_LOW 35.0           // Température critique basse
#define BUFFER_SIZE 50                // Taille buffer lissage

// ═════════════════════════════════════════════════════════
// 📊 STRUCTURES DE DONNÉES
// ═════════════════════════════════════════════════════════
struct SensorReading {
  float accelX, accelY, accelZ;      // Accélération (g)
  float gyroX, gyroY, gyroZ;         // Rotation (°/s)
  float accelMagnitude;              // Magnitude accell
  float temperature;                 // Température (°C)
  bool isFalling;                    // Flag chute détectée
  int8_t wifiSignal;                 // RSSI (-50 à -120 dBm)
  uint32_t timestamp;                // Timestamp (ms)
};

SensorReading sensorData;
SensorReading previousData;

// Buffer circulaire pour détection chute
float accelBuffer[BUFFER_SIZE] = {0};
uint8_t bufferIndex = 0;

// Flags état
bool systemReady = false;
bool fallAlertActive = false;
static unsigned long lastFallAlertTime = 0;
const unsigned long FALL_ALERT_COOLDOWN = 2000; // 2 secondes

// ═════════════════════════════════════════════════════════
// 🔧 OBJETS CAPTEURS
// ═════════════════════════════════════════════════════════
MPU6050 mpu(0x68);                 // MPU6050 avec adresse 0x68
Adafruit_MLX90614 mlx = Adafruit_MLX90614(); // MLX90614

// ═════════════════════════════════════════════════════════
// ⚡ SETUP - INITIALISATION
// ═════════════════════════════════════════════════════════
void setup() {
  // Initialiser UART (debug)
  Serial.begin(115200);
  delay(1000);
  
  // Header
  printSystemHeader();
  
  // Initialiser GPIO
  pinMode(ALERT_LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  digitalWrite(ALERT_LED_PIN, LOW);
  
  // Initialiser I2C
  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(400000); // 400 kHz I2C clock
  delay(500);
  
  // Initialiser MPU6050
  Serial.println("[INIT] Détection MPU6050...");
  mpu.initialize();
  
  if (!mpu.testConnection()) {
    Serial.println("❌ ERREUR: MPU6050 non trouvé à 0x68");
    Serial.println("   Vérifier: GPIO21(SDA), GPIO22(SCL), VCC, GND");
    blinkLedError();
  }
  
  mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_16);  // ±16g
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_500);   // ±500°/s
  Serial.println("✅ MPU6050 OK (I2C 0x68)");
  
  // Initialiser MLX90614
  Serial.println("[INIT] Détection MLX90614...");
  if (!mlx.begin()) {
    Serial.println("❌ ERREUR: MLX90614 non trouvé à 0x5A");
    Serial.println("   Vérifier: GPIO21(SDA), GPIO22(SCL), VCC, GND");
    blinkLedError();
  }
  Serial.println("✅ MLX90614 OK (I2C 0x5A)");
  
  // Calibration MPU
  Serial.println("[INIT] Calibration MPU6050...");
  calibrateMPU6050();
  
  // Initialiser WiFi
  Serial.println("[INIT] Connexion WiFi...");
  connectToWiFi();
  
  // Démarrer serveur TCP
  server.begin();
  Serial.print("📡 TCP Server démarré: ");
  Serial.print(WiFi.localIP());
  Serial.print(":");
  Serial.println(TCP_PORT);
  
  systemReady = true;
  Serial.println("\n✅ ═══ SYSTÈME PRÊT ═══\n");
  
  // LED confirmation
  digitalWrite(ALERT_LED_PIN, HIGH);
  delay(500);
  digitalWrite(ALERT_LED_PIN, LOW);
}

// ═════════════════════════════════════════════════════════
// 🔄 LOOP PRINCIPALE
// ═════════════════════════════════════════════════════════
void loop() {
  if (!systemReady) {
    delay(1000);
    return;
  }
  
  // Vérifier WiFi
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }
  
  // Lire capteurs
  readAllSensors();
  
  // Analyser pour chute
  detectFall();
  
  // Gérer connexions TCP
  handleTCPServer();
  
  // Envoyer données JSON
  sendSensorDataJSON();
  
  // Affiche debug série (1 Hz)
  static unsigned long lastDebugPrint = 0;
  if (millis() - lastDebugPrint > 1000) {
    printDebugData();
    lastDebugPrint = millis();
  }
  
  // Vérifier bouton test
  if (digitalRead(BUTTON_PIN) == LOW) {
    delay(50);
    if (digitalRead(BUTTON_PIN) == LOW) {
      simulateFall();
      delay(500);
    }
  }
  
  delay(100); // ~10 Hz lecture capteurs
}

// ═════════════════════════════════════════════════════════
// 📖 LIRE CAPTEURS
// ═════════════════════════════════════════════════════════
void readAllSensors() {
  // Sauvegarder données précédentes
  previousData = sensorData;
  
  // MPU6050: Accélération
  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  
  // Convertir en unités physiques
  // MPU6050 ±16g range: LSB = 2048
  sensorData.accelX = ax / 2048.0;
  sensorData.accelY = ay / 2048.0;
  sensorData.accelZ = az / 2048.0;
  
  // MPU6050 ±500°/s: LSB = 65.5
  sensorData.gyroX = gx / 65.5;
  sensorData.gyroY = gy / 65.5;
  sensorData.gyroZ = gz / 65.5;
  
  // Magnitude accélération
  sensorData.accelMagnitude = sqrt(
    sensorData.accelX * sensorData.accelX +
    sensorData.accelY * sensorData.accelY +
    sensorData.accelZ * sensorData.accelZ
  );
  
  // MLX90614: Température
  sensorData.temperature = mlx.readObjectTempC();
  
  // WiFi signal
  sensorData.wifiSignal = WiFi.RSSI();
  
  // Timestamp
  sensorData.timestamp = millis();
  
  sensorData.isFalling = false; // À mettre à jour par detectFall()
}

// ═════════════════════════════════════════════════════════
// 🚨 DÉTECTION CHUTE (3-étapes)
// ═════════════════════════════════════════════════════════
void detectFall() {
  /*
   * Algorithme 3-seuils:
   * 1. Pic accélération > 1.5g (détection mouvement rapide)
   * 2. Magnitude gyro > 100°/s (détection rotation/changement orientation)
   * 3. Position stable proche 9.8g (confirmation au sol)
   */
  
  // Ajouter au buffer
  accelBuffer[bufferIndex] = sensorData.accelMagnitude;
  bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
  
  // Calculer moyenne lissée
  float avgAccel = 0;
  for (uint8_t i = 0; i < BUFFER_SIZE; i++) {
    avgAccel += accelBuffer[i];
  }
  avgAccel /= BUFFER_SIZE;
  
  // Magnitude rotation
  float gyroMag = sqrt(
    sensorData.gyroX * sensorData.gyroX +
    sensorData.gyroY * sensorData.gyroY +
    sensorData.gyroZ * sensorData.gyroZ
  );
  
  // Critères de chute
  bool criterion1 = (sensorData.accelMagnitude > ACCEL_THRESHOLD_G * 1.5); // Pic
  bool criterion2 = (gyroMag > GYRO_THRESHOLD_DPS);                         // Rotation
  bool criterion3 = (avgAccel > 8.5 && avgAccel < 11.0);                    // Sol (~9.8g)
  
  // Détection chute: TOUS les critères
  if (criterion1 && criterion2 && criterion3) {
    sensorData.isFalling = true;
    
    // Éviter alertes en cascade
    if (millis() - lastFallAlertTime > FALL_ALERT_COOLDOWN) {
      triggerFallAlert();
      lastFallAlertTime = millis();
    }
  }
}

// ═════════════════════════════════════════════════════════
// 🔔 ALERTE CHUTE
// ═════════════════════════════════════════════════════════
void triggerFallAlert() {
  Serial.println("\n🚨🚨🚨 CHUTE DÉTECTÉE! 🚨🚨🚨\n");
  
  // Clignoter LED (5 bips)
  for (uint8_t i = 0; i < 5; i++) {
    digitalWrite(ALERT_LED_PIN, HIGH);
    delay(300);
    digitalWrite(ALERT_LED_PIN, LOW);
    delay(300);
  }
  
  fallAlertActive = true;
  
  // Notifier via TCP
  if (serverClient && serverClient.connected()) {
    serverClient.println("{\"alert\":\"FALL_DETECTED\"}");
  }
}

// ═════════════════════════════════════════════════════════
// 📡 TCP SERVER
// ═════════════════════════════════════════════════════════
void handleTCPServer() {
  // Accepter nouvelle connexion
  if (server.hasClient()) {
    if (!serverClient || !serverClient.connected()) {
      serverClient = server.accept();
      Serial.println("📱 Client TCP connecté");
    }
  }
  
  // Lire commandes
  if (serverClient && serverClient.connected()) {
    while (serverClient.available()) {
      String command = serverClient.readStringUntil('\n');
      command.trim();
      
      if (command == "PING") {
        serverClient.println("PONG");
      } else if (command == "STATUS") {
        serverClient.println("OK");
      } else if (command == "LED_ON") {
        digitalWrite(ALERT_LED_PIN, HIGH);
        serverClient.println("LED_ON");
      } else if (command == "LED_OFF") {
        digitalWrite(ALERT_LED_PIN, LOW);
        serverClient.println("LED_OFF");
      } else if (command == "FALL_TEST") {
        simulateFall();
        serverClient.println("FALL_SIMULATED");
      }
    }
  }
}

// ═════════════════════════════════════════════════════════
// 📊 ENVOYER DONNÉES JSON via TCP
// ═════════════════════════════════════════════════════════
void sendSensorDataJSON() {
  if (!serverClient || !serverClient.connected()) {
    return;
  }
  
  // Créer JSON
  StaticJsonDocument<256> doc;
  
  doc["timestamp"] = sensorData.timestamp;
  
  // Accélération
  JsonObject accel = doc.createNestedObject("accel");
  accel["x"] = round(sensorData.accelX * 100) / 100.0;
  accel["y"] = round(sensorData.accelY * 100) / 100.0;
  accel["z"] = round(sensorData.accelZ * 100) / 100.0;
  
  // Gyroscope
  JsonObject gyro = doc.createNestedObject("gyro");
  gyro["x"] = round(sensorData.gyroX * 10) / 10.0;
  gyro["y"] = round(sensorData.gyroY * 10) / 10.0;
  gyro["z"] = round(sensorData.gyroZ * 10) / 10.0;
  
  // Autres
  doc["temperature"] = round(sensorData.temperature * 10) / 10.0;
  doc["isFalling"] = sensorData.isFalling;
  doc["signal_strength"] = sensorData.wifiSignal;
  
  // Envoyer
  serializeJson(doc, serverClient);
  serverClient.println();
}

// ═════════════════════════════════════════════════════════
// 🎬 SIMUALER CHUTE (TEST)
// ═════════════════════════════════════════════════════════
void simulateFall() {
  Serial.println("🧪 Simulation chute activée!");
  
  // Modf fake data
  sensorData.accelX = 2.0;
  sensorData.accelY = 2.5;
  sensorData.accelZ = -8.0;
  sensorData.gyroX = 150.0;
  sensorData.gyroY = -120.0;
  sensorData.accelMagnitude = 10.5;
  
  triggerFallAlert();
  
  // Envoyer alerte JSON
  if (serverClient && serverClient.connected()) {
    serverClient.println("{\"event\":\"FALL_SIMULATED\",\"confidence\":87.3}");
  }
}

// ═════════════════════════════════════════════════════════
// 🌐 WiFi
// ═════════════════════════════════════════════════════════
void connectToWiFi() {
  Serial.print("Connexion à: ");
  Serial.println(WIFI_SSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  uint8_t attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connecté!");
    Serial.print("📍 IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ Erreur WiFi!");
  }
}

// ═════════════════════════════════════════════════════════
// 🔧 CALIBRATION
// ═════════════════════════════════════════════════════════
void calibrateMPU6050() {
  // Offset (lecture moyenne sur 100 échantillons au repos)
  int16_t ax_offset = 0, ay_offset = 0, az_offset = 0;
  
  for (uint8_t i = 0; i < 100; i++) {
    int16_t ax, ay, az, gx, gy, gz;
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
    ax_offset += ax;
    ay_offset += ay;
    az_offset += az;
    delay(10);
  }
  
  ax_offset /= 100;
  ay_offset /= 100;
  az_offset /= 100;
  
  // Ajuster Z pour la gravité
  az_offset -= 2048; // Enlever 1g de gravitée
  
  mpu.setXAccelOffset(ax_offset);
  mpu.setYAccelOffset(ay_offset);
  mpu.setZAccelOffset(az_offset);
  
  Serial.println("✅ Calibration MPU6050 terminée");
}

// ═════════════════════════════════════════════════════════
// 🖨️ DEBUG PRINT
// ═════════════════════════════════════════════════════════
void printDebugData() {
  Serial.println("┌─────────────────────────────────┐");
  Serial.print("│ ");
  Serial.print(sensorData.timestamp);
  Serial.println(" ms         ");
  Serial.println("├─────────────────────────────────┤");
  
  Serial.print("│ 📍 Accel: X=");
  Serial.print(sensorData.accelX, 2);
  Serial.print(" Y=");
  Serial.print(sensorData.accelY, 2);
  Serial.print(" Z=");
  Serial.print(sensorData.accelZ, 2);
  Serial.println(" g");
  
  Serial.print("│ 🔄 Gyro:  X=");
  Serial.print(sensorData.gyroX, 1);
  Serial.print(" Y=");
  Serial.print(sensorData.gyroY, 1);
  Serial.print(" Z=");
  Serial.print(sensorData.gyroZ, 1);
  Serial.println(" °/s");
  
  Serial.print("│ 🌡️  Temp: ");
  Serial.print(sensorData.temperature, 1);
  Serial.println(" °C       ");
  
  Serial.print("│ 📡 RSSI:  ");
  Serial.print(sensorData.wifiSignal);
  Serial.println(" dBm      ");
  
  if (sensorData.isFalling) {
    Serial.println("│ 🚨 STATUS: CHUTE DÉTECTÉE !!!");
  } else {
    Serial.println("│ ✅ STATUS: Normal");
  }
  
  Serial.println("└─────────────────────────────────┘");
}

// ═════════════════════════════════════════════════════════
// 🎯 AUXILIAIRES
// ═════════════════════════════════════════════════════════
void printSystemHeader() {
  Serial.println("\n╔═══════════════════════════════════════╗");
  Serial.println("║  FALL DETECTION SYSTEM - ESP32      ║");
  Serial.println("║  v1.0 | WiFi/TCP Server            ║");
  Serial.println("╚═══════════════════════════════════════╝\n");
}

void blinkLedError() {
  Serial.println("🔴 ERREUR SYSTÈME - Clignotement LED");
  while (1) {
    digitalWrite(ALERT_LED_PIN, HIGH);
    delay(100);
    digitalWrite(ALERT_LED_PIN, LOW);
    delay(100);
  }
}

// ═════════════════════════════════════════════════════════
// EOF
// ═════════════════════════════════════════════════════════
