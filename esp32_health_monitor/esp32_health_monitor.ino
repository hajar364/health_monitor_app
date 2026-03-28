/*
 * SYSTÈME IoT DE SURVEILLANCE DE SANTÉ
 * Architecture distribuée avec interprétabilité locale
 * 
 * Microcontrôleur: ESP32
 * Plateforme: Arduino IDE / PlatformIO
 * 
 * Capteurs:
 * - KY-039 (Fréquence Cardiaque)
 * - DHT22 (Température/Humidité)
 * - MPU6050 (Accélération/Gyroscope)
 * 
 * Communication: Bluetooth (HC-05/HC-06 ou ESP32 interne)
 */

#include <Wire.h>
#include <DHT.h>

// ========== IMPORTS CAPTEURS ==========
// Télécharger depuis Arduino IDE: Library Manager
// DHT by Adafruit
// MPU6050 by ElectroMech

#include <MPU6050.h>

// ========== DÉFINITION DES BROCHES ==========
#define DHT_PIN 4                  // GPIO4 - DHT22 Data
#define DHT_TYPE DHT22             // Type de capteur DHT
#define HEART_RATE_PIN 35          // GPIO35 (ADC1_7) - Capteur FC
#define ALERT_LED_PIN 13           // GPIO13 - LED d'alerte
#define BUTTON_TEST_PIN 14         // GPIO14 - Bouton test (optionnel)

// ========== CONFIGURATION SEUILS D'ANOMALIES ==========
#define HEART_RATE_MIN 40          // BPM minimum normal
#define HEART_RATE_MAX 120         // BPM maximum normal
#define HEART_RATE_RESTING_MIN 60  // Au repos: seuil bas
#define HEART_RATE_RESTING_MAX 100 // Au repos: seuil haut

#define TEMP_NORMAL_MAX 37.5       // °C - Température normale max
#define TEMP_FEVER_MIN 38.0        // °C - Début fièvre
#define TEMP_CRITICAL 39.5         // °C - Critique

#define HUMIDITY_MIN 30            // % - Humidité minimale
#define HUMIDITY_MAX 70            // % - Humidité maximale

#define ACCEL_NORMAL_MIN 0.5       // g - Seuil minimum accélération normale
#define ACCEL_NORMAL_MAX 3.0       // g - Seuil maximum accélération normale

// ========== OBJETS CAPTEURS ==========
DHT dht(DHT_PIN, DHT_TYPE);
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
