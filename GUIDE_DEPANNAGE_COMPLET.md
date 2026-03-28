# 🛠️ GUIDE COMPLET DE DÉPANNAGE

## INDEX DES PROBLÈMES

1. [ESP32 ne s'allume pas](#esp32-ne-sallume-pas)
2. [Impossible de téléverser le code](#impossible-de-téléverser-le-code)
3. [Moniteur série affiche du charabia](#moniteur-série-affiche-du-charabia)
4. [Erreurs capteurs](#erreurs-capteurs)
5. [Fausses alertes répétées](#fausses-alertes-répétées)
6. [Problèmes Bluetooth/Communication](#problèmes-bluetoothcommunication)

---

## ESP32 ne s'allume pas

### Symptômes:
- ❌ Pas de LED allumée sur l'ESP32
- ❌ Moniteur série reste muet

### Causes possibles et solutions:

#### ✓ Solution 1: Vérifier l'alimentation USB
```bash
ACTION:
1. Brancher le câble USB sur un autre port (essayer tous les ports)
2. Utiliser un câble USB VALIDE (pas juste un câble de charge)
   ← Important! Certains câbles ne transmettent que l'énergie
3. Tester sur un autre ordinateur si possible

TEST:
→ Si une petite LED bleue s'allume sur l'ESP32 → OK
→ Si rien → Le câble ou le port USB est défectueux
```

#### ✓ Solution 2: Réinitialiser l'ESP32
```bash
ACTION dans Arduino IDE:
1. Tools → Erase All Flash Before Sketch Upload
2. Téléverser n'importe quel programme simple (blink par exemple)
3. Si ça fonctionne, réupload votre code

CODE TEST (blink simple):
void setup() { pinMode(13, OUTPUT); }
void loop() { 
  digitalWrite(13, HIGH); delay(500);
  digitalWrite(13, LOW); delay(500);
}
```

#### ✓ Solution 3: Installer le driver USB
```bash
Pour Windows:
1. Télécharger le driver CH340: 
   https://learn.sparkfun.com/tutorials/how-to-install-ch340-drivers
2. Installer le driver
3. Redémarrer Windows
4. Vérifier dans Gestionnaire de périphériques:
   Ports COM → "USB-SERIAL CH340" ou "Silicon Labs CP210x"
   
Si device manager affiche "?" → Driver manquant!
```

---

## Impossible de téléverser le code

### Symptômes:
- ❌ "Failed to connect"
- ❌ "Serial port is not available"
- ❌ "ESP32 not in bootloader mode"

### Solutions:

#### ✓ Solution 1: Sélectionner le bon port COM
```bash
ACTION:
1. Arduino IDE → Tools → Port
2. Vérifier quel port est coché
3. Si rien n'est listé: Redémarrer Arduino IDE

Windows Gestionnaire de périphériques:
1. Touche Windows + R → devmgmt.msc
2. Chercher "Ports (COM & LPT)"
3. Vérifier qu'il y a "COM3", "COM4" ou similaire
```

#### ✓ Solution 2: Réinitialiser en mode bootloader
```bash
ACTION:
1. Dans Arduino IDE, sélectionner:
   Tools → Upload Speed → 115200
2. Brancher USB
3. IMMÉDIATEMENT après: Appuyer sur le bouton "BOOT" de l'ESP32
   pendant 2 secondes
4. Cliquer sur Upload
5. Laisser le doigt relâché
```

#### ✓ Solution 3: Vérifier les droits d'accès
```bash
Pour Windows:
1. Fermer Arduino IDE
2. Clic droit sur Arduino IDE → Lancer en tant qu'administrateur
3. Essayer de téléverser

Pour Mac/Linux:
sudo chmod 666 /dev/ttyUSB*
```

---

## Moniteur série affiche du charabia

### Symptômes:
```
Output: ☃☠✧A❑✆☦☧✧♂♄✄☮
Au lieu de: [INIT] Initialisation...
```

### Cause:
La vitesse de transmission (BAUD RATE) ne correspond pas!

### Solution:

```bash
ACTION:
1. Arduino IDE → Tools → Serial Monitor
2. EN BAS À DROITE: Vérifier la vitesse
3. DOIT ÊTRE: 115200

☐ Vérifier que c'est bien 115200 baud
☐ Fermer et rouvrir le moniteur
☐ Si toujours du charabia: essayer 9600 ou 57600

CODE:
void setup() {
  Serial.begin(115200);  ← Cette valeur DOIT correspondre!
  delay(100);
}
```

---

## Erreurs capteurs

### Erreur 1: "[✗] Erreur: MPU6050 non détecté!"

#### Causes:
1. ❌ Fil I2C déconnecté
2. ❌ Pull-ups I2C manquants
3. ❌ Adresse I2C incorrecte
4. ❌ Capteur MCU6050 défectueux

#### Solutions:

```bash
ACTION 1: Vérifier les fils
- MPU SDA (jaune) → ESP32 GPIO21
- MPU SCL (vert) → ESP32 GPIO22
- MPU GND (noir) → rail GND
- MPU VCC (rouge) → rail +5V

VÉRIFICATION multimètre:
→ Compter le nombre de broches sur le module MPU6050
→ Doit avoir 4 broches: GND, SCL, SDA, VCC
```

```bash
ACTION 2: Ajouter les pull-ups I2C
- Résistance 10kΩ entre SDA et +5V
- Résistance 10kΩ entre SCL et +5V
- Ces résistances DOIVENT être présentes!

DIAGRAMME:
ESP32 GPIO21 ──[ 10kΩ ]──┐
                          │
                         +5V
                          
ESP32 GPIO22 ──[ 10kΩ ]──┐
                          │
                         +5V

Les résistances se connectent AUSSI au MPU6050!
```

```bash
ACTION 3: Vérifier l'adresse I2C
Charger ce sketch:

#include <Wire.h>
void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);
  Serial.println("I2C Scanner:");
  for (byte i = 8; i < 120; i++) {
    Wire.beginTransmission(i);
    if (Wire.endTransmission() == 0) {
      Serial.print("Device found at 0x");
      Serial.println(i, HEX);
    }
  }
}
void loop() { delay(5000); }

→ MPU6050 doit apparaître à l'adresse 0x68 ou 0x69
```

---

### Erreur 2: "[!] Erreur DHT22 - données invalides"

#### Causes:
1. ❌ DHT22 inversé (broche VCC/GND inversée)
2. ❌ Fil Data lâche
3. ❌ Pull-up manquant
4. ❌ DHT22 défectueux

#### Solutions:

```bash
ACTION 1: Vérifier les broches DHT22
DHT22 a 3 broches:
┌─────────────────┐
│ VCC │ Data │ GND │
└─────────────────┘
   ↑     ↑     ↑
  +5V  GPIO4  GND

✓ VCC (longue broche) → +5V
✓ Data (broche du milieu) → GPIO4
✓ GND (courte broche) → GND
```

```bash
ACTION 2: Ajouter la résistance pull-up
Entre la broche Data et +5V:
[ 10kΩ résistance ]

Sans cette résistance, DHT22 ne fonctionnera PAS!
```

```bash
ACTION 3: Tester directement
Charger ce sketch:

#include <DHT.h>
#define DHT_PIN 4
#define DHT_TYPE DHT22

DHT dht(DHT_PIN, DHT_TYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();
}

void loop() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  
  Serial.print("Temp: ");
  Serial.print(t);
  Serial.print(" °C, Humidité: ");
  Serial.print(h);
  Serial.println(" %");
  
  delay(2000);
}

→ Si affiche "nan nan": DHT n'est pas connecté correctement
→ Si affiche des nombres: OK!
```

---

### Erreur 3: "KY-039 affiche 0 BPM"

#### Causes:
1. ❌ Diviseur de tension incorrect
2. ❌ Pas de signal du capteur FC
3. ❌ ADC GPIO35 endommagé

#### Solutions:

```bash
ACTION 1: Vérifier le diviseur de tension
DOIT être: 10kΩ + 20kΩ

        KY-039 Signal (5V)
            │
           [10kΩ]
            │
        ┌───┴────────→ ESP32 GPIO35
        │
       [20kΩ]
        │
       GND

VÉRIFICATION:
- Mesurer avec multimètre entre GPIO35 et GND
- DOIT AFFICHER: 3.0-3.3V uniquement!
- Si 5V: résistances manquantes ⚠️
```

```bash
ACTION 2: Tester le capteur KY-039
Charger ce sketch:

void setup() { Serial.begin(115200); }

void loop() {
  int raw = analogRead(35);
  Serial.println(raw);  // Doit changer avec la lumière
  delay(100);
}

→ Placer votre doigt sur le capteur optique
→ L'affichage doit changer (300-500 → 800-1000)
→ Si constant: capteur cassé ou mal connecté
```

---

## Fausses alertes répétées

### Symptôme:
```
🚨 ALERTE DÉTECTÉE:
Raison: BRADYCARDIE (FC < 40 BPM);
...
🚨 ALERTE DÉTECTÉE:
...
```

### Cause:
Capteur FC qui donne de mauvaises lectures

### Solutions:

```bash
ACTION 1: Calibrer les seuils
Dans esp32_health_monitor.ino, modifier:

#define HEART_RATE_MIN 40  // ← Augmenter à 50 si problèmes
#define HEART_RATE_MAX 120 // ← Diminuer à 100 si trop sensible

Retéléverser le code
```

```bash
ACTION 2: Nettoyer le capteur FC
- Le capteur KY-039 utilise LED infrarouge + capteur optique
- Nettoyer la lentille avec un chiffon sec
- Vérifier que rien ne bloque la lumière
```

```bash
ACTION 3: Ajouter du filtrage
Modifier la fonction measureHeartRate():

// Augmenter le nombre d'échantillons
const uint8_t samples = 200;  // Au lieu de 100

// Cela augmente le temps de moyenne → moins de bruit
```

---

## Problèmes Bluetooth/Communication

### Symptôme 1: "Impossible de détecter l'appareils Bluetooth"

#### Vérifier que Bluetooth est correctement configuré:

```bash
OPTION 1: HC-05 en filaire
1. HC-05 reçoit le JSON via Serial (TX/RX)
2. HC-05 transmet via Bluetooth

Broches:
HC-05 VCC (5V) → ESP32 VIN
HC-05 GND → ESP32 GND
HC-05 RX → ESP32 TX (GPIO1)
HC-05 TX → ESP32 RX (GPIO3)

⚠️ IMPORTANT: Utiliser diviseur de tension pour HC-05 RX!
HC-05 accepte max 3.3V sur RX
```

```cpp
// Code Arduino pour Bluetooth:
void setup() {
  Serial.begin(115200);  // HC-05 écoute ici
}

void loop() {
  // Le JSON s'envoie automatiquement via Serial
  // HC-05 le retransme en Bluetooth
}
```

```bash
OPTION 2: ESP32 Bluetooth interne
1. ESP32 a du Bluetooth intégré (pas besoin HC-05)
2. Configurer avec BluetoothSerial

Code:
#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

void setup() {
  SerialBT.begin("HealthMonitor");  // Nom Bluetooth
}

void loop() {
  // Envoyer JSON via:
  // SerialBT.println(jsonData);
}
```

---

### Symptôme 2: "Reçoit des données mais elles sont coupées"

#### Cause:
Le buffer Bluetooth est petit, les données sont trop longues

#### Solution:

```cpp
// Réduire la taille du JSON:

// ❌ TROP LONG:
String jsonData = "{\"heartRate\":72.5,\"temperature\":36.8,\"humidity\":…}";

// ✓ COMPACT:
String json = "{\"hr\":72.5,\"t\":36.8,\"h\":45,\"abn\":false}";

// Ou envoyer ligne par ligne:
Serial.print("FC:");
Serial.println(heartRate);
Serial.print("T:");
Serial.println(temperature);
```

---

## ⚡ CHECKLIST DE SÉCURITÉ EN CAS DE DOUTE

```
SI L'ESP32 NE FONCTIONNE PLUS:

1. ÉTEINDRE IMMÉDIATEMENT
2. Débrancher l'USB
3. Attendre 30 secondes
4. Vérifier visuellement:
   ☐ Pas de fil brûlé (black marks)
   ☐ Pas d'odeur bizarre
   ☐ Pas de fumée
   ☐ Pas de débris

5. REBRANCHER et essayer
6. Si toujours down:
   → L'ESP32 peut être endommagé
   → Contactez le fournisseur
```

---

## 🆘 DERNIÈRE RESSOURCE

### Si rien ne fonctionne:

1. **Tester chaque capteur individuellement**
   - KY-039 seul d'abord
   - DHT22 seul puis
   - MPU6050 seul

2. **Utiliser les I2C Scanner et ADC tests fournis**

3. **Consulter les datasheet officiels:**
   - ESP32: https://www.espressif.com/
   - MPU6050: https://invensense.tdk.com/
   - DHT22: https://www.sparkfun.com/datasheets/

4. **Forum Arduino:** https://forum.arduino.cc/

---

## 📞 RÉSUMÉ RAPIDE

| Problème | Cause | Vérifier |
|----------|-------|----------|
| Rien ne marche | Pas d'alimentation | Multimètre 5V VCC-GND |
| Charabia série | Baud rate incorrect | Doit être 115200 |
| MPU6050 pas vu | I2C pull-ups manquants | 10kΩ sur SDA et SCL |
| DHT22 invalide | Pas de pull-up | 10kΩ entre Data et VCC |
| KY-039 = 0 BPM | Pas de diviseur | 10kΩ + 20kΩ présents |
| Alertes répétées | Capteur bruyant | Augmenter le filtrage |

**Bon dépannage! 🔧**
