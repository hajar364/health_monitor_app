#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Adafruit_MLX90614.h>
#include <MPU6050.h>

// ==================== CONFIGURATION WiFi ====================
const char* ssid = "TECNO POP 5";           // ⚠️ VOTRE WiFi
const char* password = "de4bnimdgmaz";      // ⚠️ VOTRE Mot de passe

// IP DYNAMIQUE (pas statique) - ça marche mieux !
WebServer server(80);

// ==================== CAPTEURS ====================
// MLX90614 (capteur infrarouge température) - adresse I2C: 0x5A (par défaut)
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

// MPU6050 (capteur accélération/gyroscope) - adresse I2C: 0x69
MPU6050 mpu(0x69);

// ==================== PARAMÈTRES DE DÉTECTION ====================
const int ACC_THRESHOLD = 25000;    // Seuil d'accélération (G*1000)
const int IMMOBILITY_TIME = 7000;   // Temps d'immobilité après impact (ms)
const int BUFFER_SIZE = 20;         // Taille du filtre moyenne glissante

// ==================== VARIABLES ====================
int axBuffer[BUFFER_SIZE], ayBuffer[BUFFER_SIZE], azBuffer[BUFFER_SIZE];
int indexBuf = 0;
unsigned long impactTime = 0;
bool impactDetecte = false;
bool capteursPrets = false;

// ==================== ENDPOINTS HTTP ====================

// GET /ping - Test de connexion
void handlePing() {
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

// GET /sensors - Lecture en temps réel des capteurs
void handleSensors() {
  if (!capteursPrets) {
    server.send(500, "application/json", "{\"error\":\"Capteurs non prêts\"}");
    return;
  }

  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

  float tempObj = mlx.readObjectTempC();
  float tempAmb = mlx.readAmbientTempC();

  String json = "{";
  json += "\"accelX\":" + String(ax) + ",";
  json += "\"accelY\":" + String(ay) + ",";
  json += "\"accelZ\":" + String(az) + ",";
  json += "\"gyroX\":" + String(gx) + ",";
  json += "\"gyroY\":" + String(gy) + ",";
  json += "\"gyroZ\":" + String(gz) + ",";
  json += "\"tempObj\":" + String(tempObj) + ",";
  json += "\"tempAmb\":" + String(tempAmb);
  json += "}";

  server.send(200, "application/json", json);
}

// GET /status - État du système
void handleStatus() {
  String json = "{";
  json += "\"ip\":\"" + WiFi.localIP().toString() + "\",";
  json += "\"ssid\":\"" + String(ssid) + "\",";
  json += "\"capteursPrets\":" + String(capteursPrets ? "true" : "false") + ",";
  json += "\"chutDetectee\":" + String(impactDetecte ? "true" : "false");
  json += "}";
  
  server.send(200, "application/json", json);
}

// ==================== INITIALISATION CAPTEURS ====================
bool initCapteurs() {
  Serial.println("\n=== Initialisation Capteurs ===");
  
  // Init I2C (SDA=32, SCL=33)
  Wire.begin(32, 33);
  delay(500);

  // === MLX90614 (Température infrarouge) ===
  Serial.print("MLX90614...");
  if (!mlx.begin()) {
    Serial.println(" ❌ NON DÉTECTÉ");
    return false;
  }
  Serial.println(" ✅ OK");

  // === MPU6050 (Accélération + Gyroscope) ===
  Serial.print("MPU6050...");
  mpu.initialize();
  if (!mpu.testConnection()) {
    Serial.println(" ❌ NON DÉTECTÉ");
    return false;
  }
  Serial.println(" ✅ OK");

  // Configuration MPU6050
  mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_16);  // ±16G
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_2000);  // ±2000°/s
  
  Serial.println("✅ TOUS LES CAPTEURS PRÊTS !\n");
  return true;
}

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n\n");
  Serial.println("╔═══════════════════════════════════════╗");
  Serial.println("║   ESP32 HEALTH MONITOR - DÉMARRAGE    ║");
  Serial.println("╚═══════════════════════════════════════╝");

  // Initialiser les capteurs
  capteursPrets = initCapteurs();
  
  if (!capteursPrets) {
    Serial.println("⚠️  ERREUR: Capteurs non détectés. Mode HTTP seulement.");
  }

  // =============== CONNEXION WiFi ===============
  Serial.println("\n=== Connexion WiFi ===");
  Serial.print("SSID: ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  Serial.print("Connexion");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(" ✅");
    Serial.println("✅ WiFi CONNECTÉ !");
    Serial.print("IP ESP32: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(" ❌");
    Serial.println("❌ Erreur WiFi - redémarrage...");
    delay(2000);
    ESP.restart();
  }

  // =============== SERVEUR HTTP ===============
  Serial.println("\n=== Serveur HTTP ===");
  server.on("/", []() {
    String html = "<h1>🏥 ESP32 Health Monitor</h1>";
    html += "<p><strong>IP:</strong> " + WiFi.localIP().toString() + "</p>";
    html += "<p><strong>WiFi:</strong> " + String(ssid) + "</p>";
    html += "<p><strong>Capteurs:</strong> " + String(capteursPrets ? "✅ OK" : "⚠️ Erreur") + "</p>";
    html += "<hr>";
    html += "<h3>Endpoints API:</h3>";
    html += "<ul>";
    html += "<li><code>GET /ping</code> - Test connexion</li>";
    html += "<li><code>GET /sensors</code> - Données capteurs</li>";
    html += "<li><code>GET /status</code> - État système</li>";
    html += "</ul>";
    server.send(200, "text/html", html);
  });
  
  server.on("/ping", handlePing);
  server.on("/sensors", handleSensors);
  server.on("/status", handleStatus);
  
  server.begin();
  Serial.println("✅ Serveur HTTP sur port 80");
  Serial.println("\n📱 Accédez à: http://" + WiFi.localIP().toString());
  Serial.println("   Ping:    http://" + WiFi.localIP().toString() + "/ping");
  Serial.println("   Sensors: http://" + WiFi.localIP().toString() + "/sensors");
  Serial.println("   Status:  http://" + WiFi.localIP().toString() + "/status");
}

// ==================== LOOP PRINCIPALE ====================
void loop() {
  server.handleClient();

  if (!capteursPrets) {
    delay(100);
    return;
  }

  // ========== LECTURE MPU6050 ==========
  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

  // Ajout au buffer pour filtrage
  axBuffer[indexBuf] = ax;
  ayBuffer[indexBuf] = ay;
  azBuffer[indexBuf] = az;
  indexBuf = (indexBuf + 1) % BUFFER_SIZE;

  int axFilt = moyenne(axBuffer);
  int ayFilt = moyenne(ayBuffer);
  int azFilt = moyenne(azBuffer);

  // ========== LECTURE MLX90614 ==========
  float tempObj = mlx.readObjectTempC();
  float tempAmb = mlx.readAmbientTempC();

  // ========== DÉTECTION D'IMPACT ==========
  if (abs(axFilt) > ACC_THRESHOLD || abs(ayFilt) > ACC_THRESHOLD || abs(azFilt) > ACC_THRESHOLD) {
    impactTime = millis();
    impactDetecte = true;
    Serial.println("⚠️ IMPACT DÉTECTÉ !");
  }

  // ========== VÉRIFICATION IMMOBILITÉ POST-IMPACT ==========
  if (impactDetecte && (millis() - impactTime > IMMOBILITY_TIME)) {
    Serial.println("\n🚨 CHUTE CONFIRMÉE ! 🚨");
    Serial.print("Température corporelle: ");
    Serial.print(tempObj);
    Serial.println(" °C");

    if (tempObj >= 35 && tempObj <= 37.5) {
      Serial.println("✅ Présence humaine CONFIRMÉE");
    } else {
      Serial.println("⚠️ Température anormale - vérifier capteur");
    }
    Serial.println();

    impactDetecte = false;
  }

  // ========== AFFICHAGE MONITORING ==========
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 2000) {
    Serial.print("📊 ");
    Serial.print("Ax=");
    Serial.print(axFilt);
    Serial.print(" Ay=");
    Serial.print(ayFilt);
    Serial.print(" Az=");
    Serial.print(azFilt);
    Serial.print(" | Tamb=");
    Serial.print(tempAmb);
    Serial.print("°C Tobj=");
    Serial.print(tempObj);
    Serial.println("°C");
    lastPrint = millis();
  }

  delay(100);
}

// ==================== FONCTION MOYENNE ====================
int moyenne(int buffer[]) {
  long sum = 0;
  for (int i = 0; i < BUFFER_SIZE; i++) sum += buffer[i];
  return sum / BUFFER_SIZE;
}
