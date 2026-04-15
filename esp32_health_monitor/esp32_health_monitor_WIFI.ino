#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// ===== WiFi & COMMUNICATION =====
const char* ssid = "ESP32_HealthMonitor";      // SSID du point d'accès
const char* password = "12345678";              // Mot de passe WiFi
WebServer server(80);                           // Serveur web sur port 80

IPAddress apIP(192, 168, 4, 1);                // IP du point d'accès
IPAddress apSubnet(255, 255, 255, 0);

// === MLX90614 (Température infrarouge sans contact) ===
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

// === MPU6050 (Capteur de mouvement pour détection chute) ===
MPU6050 mpu(0x69);

// === LED D'ALERTE ===
const int LED_PIN = 12;  // GPIO12 pour la LED d'alerte
bool ledActive = false;

// ===== PARAMÈTRES DE DÉTECTION =====
const int ACC_THRESHOLD = 18000;      // seuil d'accélération pour impact
const int IMMOBILITY_TIME = 5000;     // temps msd'immobilité après impact
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

// Données actuelles (pour API)
StaticJsonDocument<500> currentMeasurement;
unsigned long lastUpdate = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // Initialiser WiFi en mode Point d'Accès (AP)
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(apIP, apIP, apSubnet);
  WiFi.softAP(ssid, password);
  
  Serial.println("\n====== ESP32 Health Monitor - WiFi Mode ======");
  Serial.print("SSID: ");
  Serial.println(ssid);
  Serial.print("IP: ");
  Serial.println(WiFi.softAPIP());
  Serial.println("Port: 80");
  
  // Configuration des routes HTTP
  server.on("/", HTTP_GET, handleRoot);
  server.on("/health", HTTP_GET, handleHealth);
  server.on("/led", HTTP_POST, handleLED);
  server.on("/config", HTTP_POST, handleConfig);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/measure", HTTP_GET, handleMeasure);
  
  server.begin();
  Serial.println("[OK] Serveur web démarré\n");
  
  Wire.begin(32, 33); // SDA=32, SCL=33 pour I2C

  // Initialiser LED d'alerte
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // === Initialisation MLX90614 ===
  if (!mlx.begin()) {
    Serial.println("[ERREUR] MLX90614 non détecté !");
    while (1);
  }
  Serial.println("[OK] MLX90614 initialisé");

  // === Initialisation MPU6050 ===
  mpu.initialize();
  if (!mpu.testConnection()) {
    Serial.println("[ERREUR] MPU6050 non détecté !");
    while (1);
  }
  Serial.println("[OK] MPU6050 initialisé");

  Serial.println("=== System Ready ===\n");
}

// ===== HANDLERS HTTP =====

void handleRoot() {
  String html = R"(
<!DOCTYPE html>
<html>
<head>
  <title>Health Monitor</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: Arial; margin: 20px; background: #f0f0f0; }
    h1 { color: #135BEC; }
    .metric { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .alert { background: #ffe6e6; color: red; padding: 10px; border-radius: 5px; }
    .success { background: #e6ffe6; color: green; }
    button { padding: 10px 20px; background: #135BEC; color: white; border: none; cursor: pointer; border-radius: 5px; }
    button:hover { background: #0d4bb8; }
  </style>
</head>
<body>
  <h1>🏥 Health Monitor - WiFi</h1>
  <p>Connecté au réseau WiFi de l'ESP32</p>
  
  <div class="metric">
    <h3>📊 Données en Temps Réel</h3>
    <p>Température: <strong id="temp">--</strong>°C</p>
    <p>Accélération: <strong id="accel">--</strong> g</p>
    <p>Statut: <strong id="status">--</strong></p>
    <p>Alerte: <strong id="alert">--</strong></p>
  </div>
  
  <div class="metric">
    <h3>⚙️ Contrôles</h3>
    <button onclick="activateLED()">LED ON</button>
    <button onclick="deactivateLED()">LED OFF</button>
    <button onclick="getMeasure()">Mesure</button>
    <button onclick="getStatus()">Status</button>
  </div>
  
  <script>
    // Auto-refresh toutes les 500ms
    setInterval(() => {
      fetch('/health')
        .then(r => r.json())
        .then(d => {
          document.getElementById('temp').textContent = d.temperature.toFixed(1);
          document.getElementById('accel').textContent = d.accelX.toFixed(2);
          document.getElementById('status').textContent = d.status;
          document.getElementById('alert').textContent = d.alertStatus;
        });
    }, 500);
    
    function activateLED() {
      fetch('/led', { method: 'POST', body: JSON.stringify({action: 'on'}) });
    }
    function deactivateLED() {
      fetch('/led', { method: 'POST', body: JSON.stringify({action: 'off'}) });
    }
    function getMeasure() {
      fetch('/measure').then(r => r.json()).then(d => console.log(d));
    }
    function getStatus() {
      fetch('/status').then(r => r.json()).then(d => console.log(d));
    }
  </script>
</body>
</html>
  )";
  server.send(200, "text/html", html);
}

void handleHealth() {
  String json;
  serializeJson(currentMeasurement, json);
  server.send(200, "application/json", json);
}

void handleLED() {
  if (server.hasArg("plain")) {
    StaticJsonDocument<200> doc;
    deserializeJson(doc, server.arg("plain"));
    
    String action = doc["action"];
    if (action == "on") {
      activateLED();
      server.send(200, "application/json", "{\"status\":\"LED ON\"}");
    } else {
      deactivateLED();
      server.send(200, "application/json", "{\"status\":\"LED OFF\"}");
    }
  } else {
    server.send(400, "application/json", "{\"error\":\"No data\"}");
  }
}

void handleConfig() {
  if (server.hasArg("plain")) {
    StaticJsonDocument<300> doc;
    deserializeJson(doc, server.arg("plain"));
    
    if (doc.containsKey("interval")) {
      measureInterval = doc["interval"];
      Serial.print("[CONFIG] Intervalle = ");
      Serial.print(measureInterval);
      Serial.println("ms");
    }
    if (doc.containsKey("tempFever")) {
      const_cast<float&>(TEMP_FEVER) = doc["tempFever"];
    }
    
    server.send(200, "application/json", "{\"status\":\"Config updated\"}");
  } else {
    server.send(400, "application/json", "{\"error\":\"No data\"}");
  }
}

void handleStatus() {
  StaticJsonDocument<300> doc;
  doc["wifi_ssid"] = ssid;
  doc["wifi_ip"] = WiFi.softAPIP().toString();
  doc["led_active"] = ledActive;
  doc["sensors_ok"] = true;
  doc["uptime"] = millis() / 1000;
  doc["version"] = "1.0.0-WiFi";
  
  String json;
  serializeJson(doc, json);
  server.send(200, "application/json", json);
}

void handleMeasure() {
  String json;
  serializeJson(currentMeasurement, json);
  server.send(200, "application/json", json);
}

// ===== FONCTIONS UTILITAIRES =====

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
  }
}

void deactivateLED() {
  if (ledActive) {
    digitalWrite(LED_PIN, LOW);
    ledActive = false;
    Serial.println("⚫ LED d'alerte DÉSACTIVÉE");
  }
}

void updateMeasurement(float tempObj, float tempAmb, double ax, double ay, double az,
                       bool isFall, bool isFever, bool isHypothermia, const char* status) {
  // Effacer l'ancien JSON
  currentMeasurement.clear();
  
  // Remplir les nouvelles données
  currentMeasurement["temperature"] = tempObj;
  currentMeasurement["temperatureAmbient"] = tempAmb;
  currentMeasurement["accelX"] = ax;
  currentMeasurement["accelY"] = ay;
  currentMeasurement["accelZ"] = az;
  currentMeasurement["fallDetected"] = isFall;
  currentMeasurement["feverDetected"] = isFever;
  currentMeasurement["hypothermiaDetected"] = isHypothermia;
  currentMeasurement["ledActive"] = ledActive;
  currentMeasurement["status"] = status;
  currentMeasurement["timestamp"] = millis();

  // Statut global
  String alertStatus = "NORMAL";
  if (isFall || isFever || isHypothermia) {
    alertStatus = "ALERT";
  }
  currentMeasurement["alertStatus"] = alertStatus;
  
  // Afficher sur Serial
  String jsonStr;
  serializeJson(currentMeasurement, jsonStr);
  Serial.println(jsonStr);
}

void loop() {
  // Traiter les requêtes HTTP
  server.handleClient();
  
  unsigned long now = millis();
  
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
      }
    }

    // Vérifier si immobilierté prolongée = chute confirmée
    if (impactDetecte && (now - impactTime > IMMOBILITY_TIME)) {
      fallDetected = true;
      Serial.println("🚨 CHUTE CONFIRMÉE !");
      activateLED();
      impactDetecte = false;
    }

    // === DÉTECTION FIÈVRE ===
    bool isFever = false;
    bool isHypothermia = false;

    if (tempObj >= TEMP_FEVER && tempObj < TEMP_HIGH_FEVER) {
      if (!feverDetected) {
        feverDetected = true;
        feverStartTime = now;
      }
      if (now - feverStartTime > FEVER_CONFIRMATION_TIME) {
        isFever = true;
        Serial.println("🤒 FIÈVRE MODÉRÉE DÉTECTÉE (38-39.5°C)");
        activateLED();
      }
    } 
    else if (tempObj >= TEMP_HIGH_FEVER) {
      isFever = true;
      Serial.println("🔴 FIÈVRE ÉLEVÉE !! (>39.5°C)");
      activateLED();
    }
    else if (tempObj <= TEMP_LOW) {
      isHypothermia = true;
      Serial.println("❄️ HYPOTHERMIE DÉTECTÉE (<35°C)");
      activateLED();
    }
    else {
      if (temperatureInRange(tempObj, TEMP_NORMAL_MIN, TEMP_NORMAL_MAX)) {
        feverDetected = false;
      }
      if (!fallDetected && !isFever && !isHypothermia) {
        deactivateLED();
      }
    }

    // === ENVOYER DONNÉES À L'API ===
    String statusMsg = "OK";
    if (fallDetected) statusMsg = "CHUTE";
    else if (isFever) statusMsg = "FIEVRE";
    else if (isHypothermia) statusMsg = "HYPOTHERMIE";

    // Convertir accélération en G (16384 LSB/g)
    double ax_g = axFilt / 16384.0;
    double ay_g = ayFilt / 16384.0;
    double az_g = azFilt / 16384.0;
    
    updateMeasurement(tempObj, tempAmb, ax_g, ay_g, az_g,
                      fallDetected, isFever, isHypothermia, statusMsg.c_str());
  }
}

bool temperatureInRange(float temp, float minT, float maxT) {
  return temp >= minT && temp <= maxT;
}
