/*
 * SYSTÈME DE DÉTECTION DE CHUTE - ESP32
 * 
 * Microcontrôleur: ESP32
 * Capteurs:
 *   - MPU6050: Accéléromètre + Gyroscope (détection chute)
 *   - MLX90614: Capteur thermique sans contact (température)
 * 
 * Communication: WiFi/TCP Socket Server (Port 5000)
 * 
 * Format données transmises:
 * {
 *   "timestamp": 1713282600,
 *   "accel": {"x": 0.1, "y": 0.2, "z": -9.8},
 *   "gyro": {"x": 0.5, "y": -0.2, "z": 0.1},
 *   "temperature": 36.5,
 *   "isFalling": false,
 *   "signal_strength": -50
 * }
 */

#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Adafruit_MLX90614.h>
#include <MPU6050.h>
#include <ArduinoJson.h>

// ========== CONFIGURATION WiFi ==========
const char* SSID = "your_ssid";           // À configurer
const char* PASSWORD = "your_password";   // À configurer
const int TCP_PORT = 5000;

WiFiServer server(TCP_PORT);
WiFiClient serverClient;

// ========== BROCHES GPIO ==========
#define MPU6050_SCL 22              // I2C Clock
#define MPU6050_SDA 21              // I2C Data
#define ALERT_LED_PIN 12            // LED alerte
#define BUTTON_PIN 13               // Bouton test (optionnel)

// ========== OBJETS CAPTEURS ==========
MPU6050 mpu;
Adafruit_MLX90614 mlx;

// ========== VARIABLES GLOBALES ==========
struct SensorData {
  float accelX, accelY, accelZ;      // Accélération (g)
  float gyroX, gyroY, gyroZ;         // Vitesse angulaire (°/s)
  float temperature;                 // Température (°C)
  float accelMagnitude;              // Magnitude accélération
  bool isFalling;                    // Détection chute
  uint32_t timestamp;
};

SensorData currentData;

// Seuils de détection de chute
#define FALL_ACCEL_THRESHOLD 1.5   // g
#define FALL_GYRO_THRESHOLD 100.0  // °/s
#define CALIBRATION_SAMPLES 100

// Buffers ringulaires pour lissage
#define BUFFER_SIZE 20
float accelBuffer[BUFFER_SIZE];
int bufferIndex = 0;

// ========== SETUP ==========
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n=== FALL DETECTION SYSTEM ===");
  
  // Initialiser I2C
  Wire.begin(MPU6050_SDA, MPU6050_SCL);
  
  // Initialiser MPU6050
  if (!mpu.begin(MPU6050_ADDR_0x68)) {
    Serial.println("❌ MPU6050 non trouvé!");
    while (1);
  }
  mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_16);
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_500);
  Serial.println("✅ MPU6050 initialisé");
  
  // Initialiser MLX90614
  if (!mlx.begin()) {
    Serial.println("❌ MLX90614 non trouvé!");
    while (1);
  }
  Serial.println("✅ MLX90614 initialisé");
  
  // GPIO
  pinMode(ALERT_LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  
  // WiFi
  connectToWiFi();
  
  // Démarrer serveur TCP
  server.begin();
  Serial.println("✅ Serveur TCP démarré sur port " + String(TCP_PORT));
  Serial.println("📡 Adresse IP: " + WiFi.localIP().toString());
  
  // Calibrer accélération de repos
  calibrateAcceleration();
}

// ========== LOOP PRINCIPALE ==========
void loop() {
  // Lire capteurs
  readSensors();
  
  // Détecter chute
  detectFall();
  
  // Envoyer données via TCP
  sendTCPData();
  
  // Vérifier commandes TCP
  handleTCPCommands();
  
  delay(100);  // ~10Hz
}

// ========== LECTURE CAPTEURS ==========
void readSensors() {
  // MPU6050
  mpu.getAcceleration(&currentData.accelX, &currentData.accelY, &currentData.accelZ);
  mpu.getRotation(&currentData.gyroX, &currentData.gyroY, &currentData.gyroZ);
  
  // Convertir en unités standards
  currentData.accelX /= 2048.0;  // pour range ±16g
  currentData.accelY /= 2048.0;
  currentData.accelZ /= 2048.0;
  
  currentData.gyroX /= 65.5;     // pour range ±500°/s
  currentData.gyroY /= 65.5;
  currentData.gyroZ /= 65.5;
  
  // Magnitude accélération
  currentData.accelMagnitude = sqrt(
    currentData.accelX * currentData.accelX +
    currentData.accelY * currentData.accelY +
    currentData.accelZ * currentData.accelZ
  );
  
  // MLX90614 - Température
  currentData.temperature = mlx.readObjectTempC();
  
  // Timestamp
  currentData.timestamp = millis() / 1000;
  
  currentData.isFalling = false;  // À mettre à jour par detectFall()
}

// ========== DÉTECTION CHUTE ==========
void detectFall() {
  // Ajouter au buffer
  accelBuffer[bufferIndex] = currentData.accelMagnitude;
  bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
  
  // Calculer moyenne lissée
  float avgAccel = 0;
  for (int i = 0; i < BUFFER_SIZE; i++) {
    avgAccel += accelBuffer[i];
  }
  avgAccel /= BUFFER_SIZE;
  
  // Détection simple 3-seuils:
  // 1. Pic accélération > seuil
  // 2. Vitesse angulaire élevée (changement d'orientation)
  // 3. Position au sol (accél stabilisée)
  
  float gyroMag = sqrt(
    currentData.gyroX * currentData.gyroX +
    currentData.gyroY * currentData.gyroY +
    currentData.gyroZ * currentData.gyroZ
  );
  
  bool highAccel = (currentData.accelMagnitude > 1.5 * FALL_ACCEL_THRESHOLD);
  bool highGyro = (gyroMag > FALL_GYRO_THRESHOLD);
  bool closedToG = (avgAccel > 8.5 && avgAccel < 11.0);  // ~9.8g (au sol)
  
  // Chute probable si pic accel + rotation + position sol
  if (highAccel && highGyro && closedToG) {
    currentData.isFalling = true;
    alertFall();
  }
}

// ========== ALERTE CHUTE ==========
void alertFall() {
  Serial.println("🚨 CHUTE DÉTECTÉE!");
  
  // Clignoter LED
  for (int i = 0; i < 5; i++) {
    digitalWrite(ALERT_LED_PIN, HIGH);
    delay(200);
    digitalWrite(ALERT_LED_PIN, LOW);
    delay(200);
  }
  
  // Son (optionnel)
  // tone(BUZZER_PIN, 1000, 500);
}

// ========== CALIBRATION ==========
void calibrateAcceleration() {
  Serial.println("📊 Calibration en cours...");
  
  for (int i = 0; i < CALIBRATION_SAMPLES; i++) {
    readSensors();
    delay(50);
  }
  
  Serial.println("✅ Calibration terminée");
}

// ========== WiFi ==========
void connectToWiFi() {
  Serial.print("🌐 Connexion à WiFi: ");
  Serial.println(SSID);
  
  WiFi.begin(SSID, PASSWORD);
  int attempts = 0;
  
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ Connecté!");
    Serial.print("📍 IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ Erreur WiFi!");
  }
}

// ========== TCP SERVER ==========
void handleTCPCommands() {
  // Accepter nouvelle connexion
  if (server.hasClient()) {
    if (!serverClient) {
      serverClient = server.accept();
      Serial.println("📱 Client connecté");
    }
  }
  
  // Lire commandes
  if (serverClient && serverClient.connected()) {
    if (serverClient.available()) {
      String command = serverClient.readStringUntil('\n');
      command.trim();
      
      if (command == "PING") {
        serverClient.println("PONG");
      } else if (command == "STATUS") {
        serverClient.println("OK");
      } else if (command == "LED_ON") {
        digitalWrite(ALERT_LED_PIN, HIGH);
        serverClient.println("✅ LED ON");
      } else if (command == "LED_OFF") {
        digitalWrite(ALERT_LED_PIN, LOW);
        serverClient.println("✅ LED OFF");
      }
    }
  }
}

// ========== SEND TCP DATA ==========
void sendTCPData() {
  if (serverClient && serverClient.connected()) {
    // Créer JSON
    StaticJsonDocument<256> doc;
    
    doc["timestamp"] = currentData.timestamp;
    doc["accel"]["x"] = currentData.accelX;
    doc["accel"]["y"] = currentData.accelY;
    doc["accel"]["z"] = currentData.accelZ;
    doc["gyro"]["x"] = currentData.gyroX;
    doc["gyro"]["y"] = currentData.gyroY;
    doc["gyro"]["z"] = currentData.gyroZ;
    doc["temperature"] = currentData.temperature;
    doc["isFalling"] = currentData.isFalling;
    doc["signal_strength"] = WiFi.RSSI();
    
    // Envoyer
    serializeJson(doc, serverClient);
    serverClient.println();  // Newline pour délimiter
  }
}

// ========== ENDPOINTS HTTP (optionnel) ==========
void setupHTTPServer() {
  // Pour future implémentation avec WebServer
  // Endpoints: /ping, /sensors, /status
}
MPU6050 mpu;

// ========== STRUCTURE DE DONNÉES SANTÉ ==========
struct HealthMetrics {
  float heartRate;           // BPM
  float temperature;         // °C
  float humidity;            // %
  float accelX, accelY, accelZ; // g
  uint32_t timestamp;        // milliseconds
  bool isAbnormal;           // Détection d'anomalie
  String anomalyReason;      // Explications
};

// ========== VARIABLES GLOBALES ==========
HealthMetrics currentMetrics = {0, 0, 0, 0, 0, 0, 0, false, ""};
HealthMetrics previousMetrics = {0, 0, 0, 0, 0, 0, 0, false, ""};

// Historique pour détection de tendances
float heartRateHistory[10] = {0};  // Derniers 10 relevés (10 secondes)
uint8_t historyIndex = 0;

// Mode de fonctionnement
bool isTestMode = false;
bool ledState = false;

// ========== SETUP - INITIALISATION ==========
void setup() {
  // Initialiser communication série (115200 baud)
  Serial.begin(115200);
  delay(500);
  
  // Afficher header
  printHeader();
  
  Serial.println("\n[INIT] Initialisation des capteurs...");
  
  // Initialiser les broches
  pinMode(ALERT_LED_PIN, OUTPUT);
  pinMode(BUTTON_TEST_PIN, INPUT_PULLUP);
  digitalWrite(ALERT_LED_PIN, LOW);
  
  // Initialiser DHT22
  dht.begin();
  delay(1000);
  Serial.println("[✓] DHT22 initialisé sur GPIO4");
  
  // Initialiser I2C et MPU6050
  Wire.begin(21, 22);  // SDA=GPIO21, SCL=GPIO22
  mpu.initialize();
  
  if (!mpu.testConnection()) {
    Serial.println("[✗] ERREUR: MPU6050 non détecté!");
    Serial.println("[!] Vérifier connexions I2C et pull-ups 10kΩ");
    alertCriticalError();
  } else {
    Serial.println("[✓] MPU6050 initialisé (Adresse: 0x68)");
  }
  
  // Initialiser ADC pour fréquence cardiaque
  pinMode(HEART_RATE_PIN, INPUT);
  Serial.println("[✓] Capteur Fréquence Cardiaque initialisé sur GPIO35");
  
  Serial.println("\n[INIT] === SYSTÈME PRÊT ===");
  Serial.println("Acquisition de données en cours...\n");
  
  delay(2000);
}

// ========== LOOP PRINCIPALE ==========
void loop() {
  // Vérifier bouton de test
  checkTestButton();
  
  // Acquérir données des capteurs
  acquisitionData();
  
  // Analyser les données
  analyzeMetrics();
  
  // Afficher les résultats
  displayMetrics();
  
  // Envoyer vers application mobile (JSON)
  static unsigned long lastJsonSend = 0;
  if (millis() - lastJsonSend > 5000) {  // Tous les 5 secondes
    sendJSONToMobileApp();
    lastJsonSend = millis();
  }
  
  // Bloquer détection d'alertes en cascade
  static unsigned long lastAlertTime = 0;
  if (isAbnormal() && (millis() - lastAlertTime > 1000)) {
    triggerAlert();
    lastAlertTime = millis();
  }
  
  delay(1000);  // Boucle principale: 1 Hz (1 seconde)
}

// ========== FONCTION: ACQUISITION DE DONNÉES ==========
void acquisitionData() {
  // Sauvegarder les métriques précédentes
  previousMetrics = currentMetrics;
  
  // Mesurer fréquence cardiaque
  measureHeartRate();
  
  // Mesurer température et humidité
  measureTemperatureHumidity();
  
  // Mesurer accélération
  measureAcceleration();
  
  // Timestamp
  currentMetrics.timestamp = millis();
}

// ========== FONCTION: MESURER FRÉQUENCE CARDIAQUE ==========
void measureHeartRate() {
  /*
   * KY-039: Capteur optique de fréquence cardiaque
   * Moyenne 10 lectures sur 2 secondes
   * Formule calibration: BPM = (raw / 1024) * 200
   */
  
  int32_t rawSum = 0;
  const uint8_t samples = 100;  // 100 * 20ms = 2 secondes
  
  for (uint8_t i = 0; i < samples; i++) {
    rawSum += analogRead(HEART_RATE_PIN);
    delayMicroseconds(20000);  // 20ms
  }
  
  int16_t rawAverage = rawSum / samples;
  
  // Convertir en BPM (calibration à affiner)
  float bpm = (rawAverage / 1024.0) * 200.0;
  
  // Filtre: éliminer les valeurs aberrantes
  if (bpm >= HEART_RATE_MIN && bpm <= 200) {
    currentMetrics.heartRate = bpm;
    
    // Ajouter à l'historique
    heartRateHistory[historyIndex] = bpm;
    historyIndex = (historyIndex + 1) % 10;
  } else if (bpm == 0) {
    currentMetrics.heartRate = 0;  // Pas de signal
  }
}

// ========== FONCTION: MESURER TEMPÉRATURE/HUMIDITÉ ==========
void measureTemperatureHumidity() {
  /*
   * DHT22: Capteur température + humidité
   * Résolution: 0.1°C et 0.1%
   */
  
  // Lire avec délai (DHT est lent)
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();
  
  // Vérifier si les données sont valides
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("[!] Erreur DHT22 - données invalides");
    currentMetrics.temperature = 0;
    currentMetrics.humidity = 0;
  } else {
    // Valider les ranges
    if (temperature > -10 && temperature < 60 && humidity > 0 && humidity < 100) {
      currentMetrics.temperature = temperature;
      currentMetrics.humidity = humidity;
    }
  }
  
  // Délai minimum entre les lectures DHT
  delay(2000);
}

// ========== FONCTION: MESURER ACCÉLÉRATION ==========
void measureAcceleration() {
  /*
   * MPU6050: Accélérométre 3-axes
   * LSB quand range ±2g: 16384
   */
  
  int16_t ax, ay, az;
  mpu.getAcceleration(&ax, &ay, &az);
  
  // Convertir LSB en g (division par 16384 pour range ±2g)
  currentMetrics.accelX = ax / 16384.0;
  currentMetrics.accelY = ay / 16384.0;
  currentMetrics.accelZ = az / 16384.0;
}

// ========== FONCTION: ANALYSE ET DÉTECTION D'ANOMALIES ==========
void analyzeMetrics() {
  currentMetrics.isAbnormal = false;
  currentMetrics.anomalyReason = "";
  
  // === ANALYSE 1: FRÉQUENCE CARDIAQUE ===
  if (currentMetrics.heartRate > 0) {  // Signal valide
    if (currentMetrics.heartRate < HEART_RATE_MIN) {
      currentMetrics.isAbnormal = true;
      currentMetrics.anomalyReason += "BRADYCARDIE (FC < 40 BPM); ";
    }
    else if (currentMetrics.heartRate > HEART_RATE_MAX) {
      currentMetrics.isAbnormal = true;
      currentMetrics.anomalyReason += "TACHYCARDIE (FC > 120 BPM); ";
    }
    
    // Détection de palpitations (variation rapide)
    if (historyIndex > 2) {
      float fcVariation = abs(currentMetrics.heartRate - heartRateHistory[(historyIndex - 1) % 10]);
      if (fcVariation > 30) {
        currentMetrics.isAbnormal = true;
        currentMetrics.anomalyReason += "PALPITATIONS (Δ " + String(fcVariation, 0) + " BPM); ";
      }
    }
  }
  
  // === ANALYSE 2: TEMPÉRATURE ===
  if (currentMetrics.temperature > TEMP_CRITICAL) {
    currentMetrics.isAbnormal = true;
    currentMetrics.anomalyReason += "FIÈVRE CRITIQUE (" + String(currentMetrics.temperature, 1) + "°C); ";
  }
  else if (currentMetrics.temperature > TEMP_FEVER_MIN) {
    currentMetrics.isAbnormal = true;
    currentMetrics.anomalyReason += "FIÈVRE (" + String(currentMetrics.temperature, 1) + "°C); ";
  }
  else if (currentMetrics.temperature > TEMP_NORMAL_MAX) {
    currentMetrics.isAbnormal = true;
    currentMetrics.anomalyReason += "TEMPÉRATURE ÉLEVÉE (" + String(currentMetrics.temperature, 1) + "°C); ";
  }
  
  // === ANALYSE 3: HUMIDITÉ AMBIANTE ===
  if (currentMetrics.humidity < HUMIDITY_MIN || currentMetrics.humidity > HUMIDITY_MAX) {
    // Note: L'humidité elle-même n'est pas une alerte santé, mais contexte
    // currentMetrics.anomalyReason += "Humidité: " + String(currentMetrics.humidity, 1) + "%; ";
  }
  
  // === ANALYSE 4: ACCÉLÉRATION (Activité) ===
  float magnitude = calculateAccelMagnitude();
  if (magnitude < ACCEL_NORMAL_MIN) {
    // Inactivité prolongée (assis/couché trop longtemps)
    currentMetrics.isAbnormal = true;
    currentMetrics.anomalyReason += "INACTIVITÉ PROLONGÉE; ";
  }
  else if (magnitude > ACCEL_NORMAL_MAX) {
    // Activité excessive
    currentMetrics.isAbnormal = true;
    currentMetrics.anomalyReason += "DÉPASSEMENT DE L'ACTIVITÉ NORMALE; ";
  }
  
  // Contrôler LED d'alerte
  digitalWrite(ALERT_LED_PIN, currentMetrics.isAbnormal ? HIGH : LOW);
}

// ========== FONCTION: CALCUL MAGNITUDE ACCÉLÉRATION ==========
float calculateAccelMagnitude() {
  return sqrt(
    currentMetrics.accelX * currentMetrics.accelX +
    currentMetrics.accelY * currentMetrics.accelY +
    currentMetrics.accelZ * currentMetrics.accelZ
  );
}

// ========== FONCTION: VÉRIFIER SI ANOMALIE ==========
bool isAbnormal() {
  return currentMetrics.isAbnormal;
}

// ========== FONCTION: DÉCLENCHER ALERTE ==========
void triggerAlert() {
  if (currentMetrics.anomalyReason.length() > 0) {
    Serial.println("\n");
    Serial.println("╔════════════════════════════════════╗");
    Serial.println("║          🚨 ALERTE SANTÉ 🚨          ║");
    Serial.println("╚════════════════════════════════════╝");
    Serial.println("ANOMALIES DÉTECTÉES:");
    Serial.println("  » " + currentMetrics.anomalyReason);
    Serial.println("────────────────────────────────────");
    Serial.println("EXPLICATION LOCAL:");
    Serial.println(explainAnomaly());
    Serial.println("────────────────────────────────────");
    Serial.println("DONNÉES ACTUELLES:");
    Serial.println("  • FC: " + String(currentMetrics.heartRate, 1) + " BPM");
    Serial.println("  • Temp: " + String(currentMetrics.temperature, 1) + "°C");
    Serial.println("  • Activité: " + String(calculateAccelMagnitude(), 2) + " g");
    Serial.println("────────────────────────────────────\n");
    
    // Contrôler LED (clignotement rapide)
    for (uint8_t i = 0; i < 3; i++) {
      digitalWrite(ALERT_LED_PIN, HIGH);
      delay(200);
      digitalWrite(ALERT_LED_PIN, LOW);
      delay(200);
    }
  }
}

// ========== FONCTION: EXPLIQUER L'ANOMALIE (IA LOCALE) ==========
String explainAnomaly() {
  String explanation = "";
  
  // Bradycardie
  if (currentMetrics.heartRate < HEART_RATE_MIN && currentMetrics.heartRate > 0) {
    explanation += "BRADYCARDIE: Une frequence cardiaque basse peut indiquer un probleme "
                   "cardiaque ou l'utilisation de certains medicaments. "
                   "Actions: Consulter un medecin si persistant.\n";
  }
  
  // Tachycardie
  if (currentMetrics.heartRate > HEART_RATE_MAX) {
    explanation += "TACHYCARDIE: Une FC elevee peut etre due au stress, l'exercice, ou la fievre. "
                   "Actions: Se reposer et verifier la temperature.\n";
  }
  
  // Fièvre
  if (currentMetrics.temperature > TEMP_FEVER_MIN) {
    explanation += "FIEVRE: Elevation de la temperature corporelle au-dessus de 38°C. "
                   "Peut indiquer une infection. "
                   "Actions: Boire beaucoup, prendre du paracetamol, consulter si > 39°C.\n";
  }
  
  // Inactivité
  if (calculateAccelMagnitude() < ACCEL_NORMAL_MIN) {
    explanation += "INACTIVITE: Vous ne bougez pas depuis longtemps. "
                   "Actions: Levez-vous et faites une petite promenade.\n";
  }
  
  return explanation.isEmpty() ? "Anomalie non documentee" : explanation;
}

// ========== FONCTION: AFFICHER LES MÉTRIQUES ==========
void displayMetrics() {
  // Format: Affichage compact sur une ligne avec mise à jour continue
  Serial.print("\r📊 [");
  
  // Fréquence cardiaque
  Serial.print("FC: ");
  if (currentMetrics.heartRate == 0) {
    Serial.print("N/A");
  } else {
    Serial.print((int)currentMetrics.heartRate);
    Serial.print(" BPM");
  }
  
  Serial.print(" | T: ");
  Serial.print(currentMetrics.temperature, 1);
  Serial.print("°C");
  
  Serial.print(" | H: ");
  Serial.print((int)currentMetrics.humidity);
  Serial.print("%");
  
  Serial.print(" | Accel: ");
  Serial.print(calculateAccelMagnitude(), 2);
  Serial.print("g");
  
  Serial.print(" | Alert: ");
  Serial.print(currentMetrics.isAbnormal ? "🔴" : "🟢");
  Serial.print("]");
  
  Serial.flush();
}

// ========== FONCTION: ENVOYER DONNÉES EN JSON ==========
void sendJSONToMobileApp() {
  /*
   * Format JSON pour communication avec app Flutter
   * Bluetooth transmettra cette chaîne texte
   */
  
  String jsonData = "{";
  jsonData += "\"heartRate\":" + String(currentMetrics.heartRate, 1) + ",";
  jsonData += "\"temperature\":" + String(currentMetrics.temperature, 1) + ",";
  jsonData += "\"humidity\":" + String(currentMetrics.humidity, 1) + ",";
  jsonData += "\"accelX\":" + String(currentMetrics.accelX, 3) + ",";
  jsonData += "\"accelY\":" + String(currentMetrics.accelY, 3) + ",";
  jsonData += "\"accelZ\":" + String(currentMetrics.accelZ, 3) + ",";
  jsonData += "\"isAbnormal\":" + String(currentMetrics.isAbnormal ? "true" : "false") + ",";
  jsonData += "\"reason\":\"" + currentMetrics.anomalyReason + "\",";
  jsonData += "\"timestamp\":" + String(currentMetrics.timestamp);
  jsonData += "}\n";
  
  // Envoyer sur port série (sera capturé par Bluetooth HC-05)
  Serial.print(jsonData);
}

// ========== FONCTION: VÉRIFIER BOUTON DE TEST ==========
void checkTestButton() {
  if (digitalRead(BUTTON_TEST_PIN) == LOW) {
    delay(50);  // Anti-rebond
    if (digitalRead(BUTTON_TEST_PIN) == LOW) {
      isTestMode = !isTestMode;
      
      if (isTestMode) {
        Serial.println("\n[TEST MODE] Activé - Injection de données de test\n");
        // Injecter valeurs de test
        currentMetrics.heartRate = 150;  // Tachycardie
        currentMetrics.temperature = 38.5;  // Fièvre
      } else {
        Serial.println("\n[TEST MODE] Désactivé\n");
      }
      
      while (digitalRead(BUTTON_TEST_PIN) == LOW) delay(10);
      delay(50);
    }
  }
}

// ========== FONCTION: ALERTE ERREUR CRITIQUE ==========
void alertCriticalError() {
  for (uint8_t i = 0; i < 10; i++) {
    digitalWrite(ALERT_LED_PIN, HIGH);
    delay(100);
    digitalWrite(ALERT_LED_PIN, LOW);
    delay(100);
  }
  // Freeze (redémarrage necessaire)
  while (1) {
    delay(1000);
  }
}

// ========== FONCTION: AFFICHER HEADER ==========
void printHeader() {
  Serial.println("\n");
  Serial.println("╔═══════════════════════════════════════════╗");
  Serial.println("║   SYSTÈME IoT SURVEILLANCE SANTÉ v1.0    ║");
  Serial.println("║  Architecture distribuée avec explicabilité  ║");
  Serial.println("╚═══════════════════════════════════════════╝");
}
