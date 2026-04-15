#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// ===== WiFi & COMMUNICATION =====
const char* ssid = "ESP32_HealthMonitor";      // SSID du point d'accès
const char* password = "12345678";              // Mot de passe minimum 8 caractères
WebServer server(80);                           // Serveur web sur port 80

IPAddress apIP(192, 168, 4, 1);                // IP du point d'accès
IPAddress apSubnet(255, 255, 255, 0);
bool wifiConnected = false;

// === MLX90614 (Température infrarouge sans contact) ===
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

// === MPU6050 (Capteur de mouvement pour détection chute) ===
MPU6050 mpu(0x69);

// === LED D'ALERTE ===
const int LED_PIN = 12;  // GPIO12 pour la LED d'alerte
bool ledActive = false;

// ===== PARAMÈTRES DE DÉTECTION =====
const int ACC_THRESHOLD = 18000;      // seuil d'accélération pour impact (g)
const int IMMOBILITY_TIME = 5000;     // temps ms d'immobilité après impact
const int BUFFER_SIZE = 10;           // taille du filtre moyenne glissante

// Seuils d'alerte (médicaux)
const float TEMP_FEVER = 38.0;        // Seuil fièvre modérée (°C)
const float TEMP_HIGH_FEVER = 39.5;   // Seuil fièvre élevée (°C)
const float TEMP_LOW = 35.0;          // Hypothermie (°C)
const float TEMP_NORMAL_MIN = 36.5;   // Température normale min
const float TEMP_NORMAL_MAX = 37.5;   // Température normale max

// ===== VARIABLES D'ÉTAT =====
int axBuffer[BUFFER_SIZE], ayBuffer[BUFFER_SIZE], azBuffer[BUFFER_SIZE];
int indexBuf = 0;
unsigned long impactTime = 0;
bool impactDetecte = false;
bool fallDetected = false;
unsigned long lastMeasureTime = 0;
unsigned long measureInterval = 500;  // Mesure toutes les 500ms

// Variables pour tracking des anomalies
bool feverDetected = false;
unsigned long feverStartTime = 0;
const unsigned long FEVER_CONFIRMATION_TIME = 10000;  // Confirmer fièvre après 10s

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32_HealthMonitor");  // Commence le Bluetooth Classic
  Wire.begin(32, 33); // SDA=32, SCL=33 pour I2C

  // Initialiser LED d'alerte
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // === Initialisation MLX90614 ===
  if (!mlx.begin()) {
    Serial.println("[ERREUR] MLX90614 non détecté !");
    SerialBT.println("[ERREUR] MLX90614 non détecté !");
    while (1);
  }
  Serial.println("[OK] MLX90614 initialisé");
  SerialBT.println("[OK] MLX90614 initialisé");

  // === Initialisation MPU6050 ===
  mpu.initialize();
  if (!mpu.testConnection()) {
    Serial.println("[ERREUR] MPU6050 non détecté !");
    SerialBT.println("[ERREUR] MPU6050 non détecté !");
    while (1);
  }
  Serial.println("[OK] MPU6050 initialisé");
  SerialBT.println("[OK] MPU6050 initialisé");

  Serial.println("=== ESP32 Health Monitor - PRÊT ===");
  SerialBT.println("=== ESP32 Health Monitor - PRÊT ===");
}

// === FONCTIONS UTILITAIRES ===

int moyenne(int buffer[]) {
  long sum = 0;
  for (int i = 0; i < BUFFER_SIZE; i++) sum += buffer[i];
  return sum / BUFFER_SIZE;
}

void activateLED() {
  if (!ledActive) {
    digitalWrite(LED_PIN, HIGH);
    ledActive = true;
    Serial.println("🔴 LED d'alerte ACTIVÉE");
    SerialBT.println("🔴 LED d'alerte ACTIVÉE");
  }
}

void deactivateLED() {
  if (ledActive) {
    digitalWrite(LED_PIN, LOW);
    ledActive = false;
    Serial.println("⚫ LED d'alerte DÉSACTIVÉE");
    SerialBT.println("⚫ LED d'alerte DÉSACTIVÉE");
  }
}

void sendJSONData(float tempObj, float tempAmb, int16_t ax, int16_t ay, int16_t az,
                   bool isFall, bool isFever, bool isHypothermia, const char* status) {
  StaticJsonDocument<500> doc;
  
  doc["temperature"] = tempObj;
  doc["temperatureAmbient"] = tempAmb;
  doc["accelX"] = ax / 16384.0;  // Convertir en g
  doc["accelY"] = ay / 16384.0;
  doc["accelZ"] = az / 16384.0;
  doc["fallDetected"] = isFall;
  doc["feverDetected"] = isFever;
  doc["hypothermiaDetected"] = isHypothermia;
  doc["ledActive"] = ledActive;
  doc["status"] = status;
  doc["timestamp"] = millis();

  // Calculer le statut global
  String alertStatus = "NORMAL";
  if (isFall || isFever || isHypothermia) {
    alertStatus = "ALERT";
  }
  doc["alertStatus"] = alertStatus;

  // Sérialiser et envoyer
  String jsonString;
  serializeJson(doc, jsonString);
  
  Serial.println(jsonString);
  SerialBT.println(jsonString);
}

void loop() {
  unsigned long now = millis();
  
  // Vérifier les commandes Bluetooth reçues
  if (SerialBT.available()) {
    String command = SerialBT.readStringUntil('\n');
    command.trim();
    handleCommand(command);
  }

  // Effectuer les mesures à intervalle régulier
  if (now - lastMeasureTime >= measureInterval) {
    lastMeasureTime = now;
    
    // === Lecture MPU6050 ===
    int16_t ax, ay, az, gx, gy, gz;
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    // Filtrage par moyenne glissante
    axBuffer[indexBuf] = ax;
    ayBuffer[indexBuf] = ay;
    azBuffer[indexBuf] = az;
    indexBuf = (indexBuf + 1) % BUFFER_SIZE;

    int axFilt = moyenne(axBuffer);
    int ayFilt = moyenne(ayBuffer);
    int azFilt = moyenne(azBuffer);

    // === Lecture MLX90614 ===
    float tempObj = mlx.readObjectTempC();
    float tempAmb = mlx.readAmbientTempC();

    // === DÉTECTION CHUTE ===
    fallDetected = false;
    if (abs(axFilt) > ACC_THRESHOLD || abs(ayFilt) > ACC_THRESHOLD || abs(azFilt) > ACC_THRESHOLD) {
      if (!impactDetecte) {
        impactTime = now;
        impactDetecte = true;
        Serial.println("⚠️ Impact détecté !");
        SerialBT.println("⚠️ Impact détecté !");
      }
    }

    // Vérifier si immobiliité prolongée = chute confirmée
    if (impactDetecte && (now - impactTime > IMMOBILITY_TIME)) {
      fallDetected = true;
      Serial.println("🚨 CHUTE CONFIRMÉE !");
      SerialBT.println("🚨 CHUTE CONFIRMÉE !");
      activateLED();
      impactDetecte = false;
    }

    // === DÉTECTION FIÈVRE ===
    bool isFever = false;
    bool isHypothermia = false;

    if (tempObj >= TEMP_FEVER && tempObj < TEMP_HIGH_FEVER) {
      // Fièvre modérée
      if (!feverDetected) {
        feverDetected = true;
        feverStartTime = now;
      }
      if (now - feverStartTime > FEVER_CONFIRMATION_TIME) {
        isFever = true;
        Serial.println("🤒 FIÈVRE MODÉRÉE DÉTECTÉE (38-39.5°C)");
        SerialBT.println("🤒 FIÈVRE MODÉRÉE DÉTECTÉE (38-39.5°C)");
        activateLED();
      }
    } 
    else if (tempObj >= TEMP_HIGH_FEVER) {
      // Fièvre élevée
      isFever = true;
      Serial.println("🔴 FIÈVRE ÉLEVÉE !! (>39.5°C)");
      SerialBT.println("🔴 FIÈVRE ÉLEVÉE !! (>39.5°C)");
      activateLED();
    }
    else if (tempObj <= TEMP_LOW) {
      // Hypothermie
      isHypothermia = true;
      Serial.println("❄️ HYPOTHERMIE DÉTECTÉE (<35°C)");
      SerialBT.println("❄️ HYPOTHERMIE DÉTECTÉE (<35°C)");
      activateLED();
    }
    else {
      // Température normale
      if (temperatureInRange(tempObj, TEMP_NORMAL_MIN, TEMP_NORMAL_MAX)) {
        feverDetected = false;
      }
      // Désactiver LED si tout revient normal
      if (!fallDetected && !isFever && !isHypothermia) {
        deactivateLED();
      }
    }

    // === ENVOYER DONNÉES AU FLUTTER APP ===
    String statusMsg = "OK";
    if (fallDetected) statusMsg = "CHUTE";
    else if (isFever) statusMsg = "FIEVRE";
    else if (isHypothermia) statusMsg = "HYPOTHERMIE";

    sendJSONData(tempObj, tempAmb, axFilt, ayFilt, azFilt, 
                 fallDetected, isFever, isHypothermia, statusMsg.c_str());
  }
}

bool temperatureInRange(float temp, float minT, float maxT) {
  return temp >= minT && temp <= maxT;
}

void handleCommand(String cmd) {
  Serial.print("[CMD] ");
  Serial.println(cmd);
  
  if (cmd == "LED_ON") {
    activateLED();
    SerialBT.println("ACK: LED activée");
  }
  else if (cmd == "LED_OFF") {
    deactivateLED();
    SerialBT.println("ACK: LED désactivée");
  }
  else if (cmd == "MEASURE") {
    Serial.println("Mesure immédiate demandée");
    SerialBT.println("ACK: Mesure envoyée");
  }
  else if (cmd == "STATUS") {
    String status = "LED=" + String(ledActive ? "ON" : "OFF") + 
                    "|CONN=BT|SENSORS=OK";
    SerialBT.println("STATUS:" + status);
  }
  else if (cmd.startsWith("SET_INTERVAL:")) {
    int interval = cmd.substring(13).toInt();
    if (interval > 100) {
      measureInterval = interval;
      SerialBT.println("ACK: Intervalle = " + String(interval) + "ms");
    }
  }
  else {
    SerialBT.println("ERR: Commande inconnue");
  }
}