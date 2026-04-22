#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// ============== WiFi Configuration ==============
const char* ssid = "TECNO POP 5";           // À remplacer si besoin
const char* password = "VOTRE_MOT_DE_PASSE"; // À remplacer
WebServer server(80);  // Port 80 (HTTP standard) au lieu de 5000

// ============== Capteurs ==============
Adafruit_MLX90614 mlx = Adafruit_MLX90614();
MPU6050 mpu(0x69);

// ============== Paramètres ==============
const int ACC_THRESHOLD = 18000;        // Seuil d'accélération pour impact
const int IMMOBILITY_TIME = 5000;       // Temps d'immobilité après impact
const int BUFFER_SIZE = 10;             // Filtre moyenne glissante
const unsigned long FALL_RESET_TIME = 30000; // Reset chute après 30s

// ============== Variables ==============
int axBuffer[BUFFER_SIZE], ayBuffer[BUFFER_SIZE], azBuffer[BUFFER_SIZE];
int indexBuf = 0;
unsigned long impactTime = 0;
unsigned long fallConfirmedTime = 0;
bool impactDetecte = false;
bool fallConfirmed = false;

// Variables pour les données
int16_t axCurrent = 0, ayCurrent = 0, azCurrent = 0;
int16_t gxCurrent = 0, gyCurrent = 0, gzCurrent = 0;
float tempObj = 0.0, tempAmb = 0.0;
unsigned long lastMeasureTime = 0;

// ============== WiFi Functions ==============
void setupWiFi() {
  Serial.println("\n");
  Serial.println("=== Configuration WiFi ===");
  Serial.print("Connexion à: ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connecté!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    Serial.println("Port: 80");
  } else {
    Serial.println("\n❌ Erreur WiFi!");
  }
}

// ============== Server Endpoints ==============
void handlePing() {
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleStatus() {
  DynamicJsonDocument doc(256);
  doc["connected"] = true;
  doc["wifi_signal"] = WiFi.RSSI();
  doc["ip"] = WiFi.localIP().toString();
  doc["fall_detected"] = fallConfirmed;
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleSensors() {
  // Lecture capteurs
  mpu.getMotion6(&axCurrent, &ayCurrent, &azCurrent, &gxCurrent, &gyCurrent, &gzCurrent);
  
  // Ajout au buffer
  axBuffer[indexBuf] = axCurrent;
  ayBuffer[indexBuf] = ayCurrent;
  azBuffer[indexBuf] = azCurrent;
  indexBuf = (indexBuf + 1) % BUFFER_SIZE;
  
  int axFilt = moyenne(axBuffer);
  int ayFilt = moyenne(ayBuffer);
  int azFilt = moyenne(azBuffer);
  
  // Lecture température
  tempObj = mlx.readObjectTempC();
  tempAmb = mlx.readAmbientTempC();
  
  // Construction JSON
  DynamicJsonDocument doc(512);
  doc["timestamp"] = millis();
  doc["accelX"] = axFilt;
  doc["accelY"] = ayFilt;
  doc["accelZ"] = azFilt;
  doc["gyroX"] = gxCurrent;
  doc["gyroY"] = gyCurrent;
  doc["gyroZ"] = gzCurrent;
  doc["magnitude"] = sqrt(axFilt*axFilt + ayFilt*ayFilt + azFilt*azFilt);
  doc["temperature"] = tempObj;
  doc["ambientTemp"] = tempAmb;
  doc["fallDetected"] = fallConfirmed;
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleCommand() {
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    DynamicJsonDocument doc(256);
    deserializeJson(doc, body);
    
    String cmd = doc["cmd"];
    Serial.print("Commande reçue: ");
    Serial.println(cmd);
    
    if (cmd == "reset_fall") {
      fallConfirmed = false;
      impactDetecte = false;
      Serial.println("✅ Chute réinitialisée");
      server.send(200, "application/json", "{\"status\":\"ok\"}");
    } else {
      server.send(400, "application/json", "{\"status\":\"unknown_command\"}");
    }
  }
}

void handleHealth() {
  // Endpoint compatible avec ESP32Service Flutter
  DynamicJsonDocument doc(512);
  doc["heartRate"] = 0; // Non disponible dans ce code
  doc["temperature"] = tempObj;
  doc["humidity"] = 0; // Non disponible
  doc["accelX"] = axCurrent;
  doc["accelY"] = ayCurrent;
  doc["accelZ"] = azCurrent;
  doc["isAbnormal"] = fallConfirmed;
  doc["reason"] = fallConfirmed ? "Chute détectée" : "Santé stable";
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleNotFound() {
  server.send(404, "application/json", "{\"error\":\"endpoint not found\"}");
}

// ============== Capteurs Functions ==============
int moyenne(int buffer[]) {
  long sum = 0;
  for (int i = 0; i < BUFFER_SIZE; i++) sum += buffer[i];
  return sum / BUFFER_SIZE;
}

void detectFall() {
  // Lecture MPU6050
  mpu.getMotion6(&axCurrent, &ayCurrent, &azCurrent, &gxCurrent, &gyCurrent, &gzCurrent);
  
  // Ajout au buffer
  axBuffer[indexBuf] = axCurrent;
  ayBuffer[indexBuf] = ayCurrent;
  azBuffer[indexBuf] = azCurrent;
  indexBuf = (indexBuf + 1) % BUFFER_SIZE;
  
  int axFilt = moyenne(axBuffer);
  int ayFilt = moyenne(ayBuffer);
  int azFilt = moyenne(azBuffer);
  
  // Lecture MLX90614
  tempObj = mlx.readObjectTempC();
  tempAmb = mlx.readAmbientTempC();
  
  // Détection impact
  if (abs(axFilt) > ACC_THRESHOLD || abs(ayFilt) > ACC_THRESHOLD || abs(azFilt) > ACC_THRESHOLD) {
    impactTime = millis();
    impactDetecte = true;
    Serial.println("⚠️ Impact détecté !");
  }
  
  // Vérification immobilité post-impact
  if (impactDetecte && (millis() - impactTime > IMMOBILITY_TIME)) {
    fallConfirmed = true;
    fallConfirmedTime = millis();
    Serial.println("⚠️ Chute confirmée !");
    Serial.print("Température corporelle: ");
    Serial.print(tempObj);
    Serial.println(" °C");
    
    if (tempObj >= 35 && tempObj <= 37) {
      Serial.println("✅ Présence humaine confirmée.");
    } else {
      Serial.println("ℹ️ Pas de présence humaine détectée (vérifier l'orientation du capteur MLX90614).");
    }
    
    impactDetecte = false;
  }
  
  // Réinitialiser la chute après 30s
  if (fallConfirmed && (millis() - fallConfirmedTime > FALL_RESET_TIME)) {
    fallConfirmed = false;
    Serial.println("🔄 Chute réinitialisée automatiquement");
  }
}

// ============== SETUP ==============
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n=== DÉMARRAGE ESP32 Health Monitor ===\n");
  
  // Init I2C
  Wire.begin(32, 33); // SDA=32, SCL=33
  
  // Init MLX90614
  if (!mlx.begin()) {
    Serial.println("❌ Erreur: MLX90614 non détecté!");
    while (1);
  }
  Serial.println("✅ MLX90614 initialisé.");
  
  // Init MPU6050
  mpu.initialize();
  if (!mpu.testConnection()) {
    Serial.println("❌ Erreur: MPU6050 non détecté!");
    while (1);
  }
  Serial.println("✅ MPU6050 initialisé.");
  
  // Init WiFi
  setupWiFi();
  
  // Setup serveur HTTP
  server.on("/ping", HTTP_GET, handlePing);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/sensors", HTTP_GET, handleSensors);
  server.on("/command", HTTP_POST, handleCommand);
  server.on("/api/health", HTTP_GET, handleHealth);
  server.onNotFound(handleNotFound);
  
  server.begin();
  Serial.println("✅ Serveur HTTP démarré sur port 80");
  Serial.println("\n=== Prêt à recevoir des données ===\n");
}

// ============== LOOP ==============
void loop() {
  server.handleClient();
  
  // Mise à jour du WiFi
  if (WiFi.status() != WL_CONNECTED) {
    setupWiFi();
  }
  
  // Détection de chute
  detectFall();
  
  // Affichage normal
  Serial.print("Temp ambiante: ");
  Serial.print(tempAmb);
  Serial.print(" °C | Temp corps: ");
  Serial.print(tempObj);
  Serial.print(" °C | Chute: ");
  Serial.println(fallConfirmed ? "OUI ⚠️" : "non");
  
  delay(500);
}
