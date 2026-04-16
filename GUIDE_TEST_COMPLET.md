# 🧪 Guide de Test Complet - Fall Detection System

**Tester l'application Flutter avec le montage ESP32 réel**

---

## ⏱️ Durée estimée: 30-45 minutes

---

## 📋 Pré-requis

### Hardware nécessaire:
- ✅ ESP32 (avec USB-C ou micro-USB)
- ✅ MPU6050 (accéléromètre 3D)
- ✅ MLX90614 (thermomètre IR)
- ✅ Câbles dupont (au moins 10)
- ✅ Résistances pull-up I2C (optionnel, souvent intégrées)
- ✅ Téléphone Android (TECNO BD2d ou autre)
- ✅ Ordinateur avec Arduino IDE installé

### Software:
- ✅ Arduino IDE
- ✅ Flutter app compilée sur le téléphone
- ✅ Python 3.8+ (optionnel, pour tests TCP)
- ✅ Câble USB pour l'ESP32

---

## 🔌 ÉTAPE 1: Montage Physique (5 minutes)

### 1.1 Connecter l'ESP32 à MPU6050 et MLX90614

```
┌────────────────────────────────────────────────────────┐
│                    ESP32 (DevKit)                       │
├────────────────────────────────────────────────────────┤
│  3.3V ────────┬──→ MPU6050 VCC                         │
│               └──→ MLX90614 VCC                        │
│                                                        │
│  GND  ────────┬──→ MPU6050 GND                         │
│               └──→ MLX90614 GND                        │
│                                                        │
│  GPIO21 ──────┬──→ MPU6050 SDA                         │
│  (SDA)        └──→ MLX90614 SDA                        │
│                                                        │
│  GPIO22 ──────┬──→ MPU6050 SCL                         │
│  (SCL)        └──→ MLX90614 SCL                        │
│                                                        │
│  GPIO12 ──────→ LED Bleue (pour visual feedback)       │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### 1.2 Vérifier les connexions

```
✅ Chaque câble bien enfoncé dans le breadboard
✅ Pas de court-circuit (GND ≠ VCC)
✅ LED connectée via résistance 220Ω (optionnel)
✅ Tous les cavaliers I2C bien en place
```

---

## 📥 ÉTAPE 2: Uploader le Firmware ESP32 (10 minutes)

### 2.1 Ouvrir Arduino IDE

1. **Lancer Arduino IDE**
2. **Fichier → Ouvrir** → Naviguez vers:
   ```
   C:\Users\hajar_or4e1ft\health_monitor_app\esp32_health_monitor\esp32_health_monitor.ino
   ```

### 2.2 Configurer Arduino IDE pour ESP32

1. **Outils → Type de carte**
   - Chercher: "ESP32"
   - Sélectionner: **ESP32 Dev Module** (ou votre modèle)

2. **Outils → Port**
   - Sélectionner le port COM (ex: COM3, COM4)
   - ⚠️ Si pas de port visible: installer le driver CH340G/CP2102

3. **Outils → Vitesse de téléchargement**
   - Définir à **921600** (plus rapide)

### 2.3 Configurer WiFi dans le code

**⚠️ IMPORTANT:** Avant de compiler, modifiez les credentials WiFi:

1. Dans Arduino IDE, trouver: (environ ligne 35-36)
   ```cpp
   const char* ssid = "YOUR_SSID";
   const char* password = "YOUR_PASSWORD";
   ```

2. Remplacer par votre WiFi:
   ```cpp
   const char* ssid = "MaBox";           // ← Votre SSID
   const char* password = "Motdepasse123";  // ← Votre mot de passe
   ```

3. **Ctrl+S** pour sauvegarder

### 2.4 Compiler et Uploader

1. **Sketch → Compiler** (Ctrl+R)
   - Attendre: "Compilation terminée"

2. **Sketch → Mettre en ligne** (Ctrl+U)
   - Voir les messages:
   ```
   Connecting........_____
   Uploading: .......................
   ✅ Uploading done.
   ```

### 2.5 Vérifier le démarrage

1. **Outils → Moniteur série** (Ctrl+Shift+M)
2. Définir vitesse: **115200 baud**
3. Appuyer sur **RESET** sur l'ESP32
4. Vous devez voir:
   ```
   ESP32 Health Monitor Starting...
   ✅ I2C initialized
   ✅ MPU6050 found at 0x68
   ✅ MLX90614 found at 0x5A
   Connecting to WiFi: MaBox
   ✅ Connected to WiFi
   WiFi IP: 192.168.1.XXX
   ✅ TCP Server started on port 5000
   Waiting for connections...
   ```

5. **Noté l'IP:** Vous la verrez dans le moniteur (ex: `192.168.1.100`)

👍 **Si vous voyez "TCP Server started" → L'ESP32 est prêt!**

---

## 📱 ÉTAPE 3: Configurer l'Application Flutter (5 minutes)

### 3.1 Ouvrir le téléphone

1. **Lancez** l'app "Fall Detection"
2. **Allez à** l'onglet ⚙️ **Settings**

### 3.2 Configurer la connexion WiFi

Vous verrez cet écran:
```
📡 WiFi Configuration

IP Address: [192.168.1.100 ········]
Port:       [5000]

[CONNECTER]
```

1. **IP Address**: Remplacez par l'IP du moniteur série (ex: `192.168.1.125`)
2. **Port**: Laisser `5000` (défaut)
3. **Appuyer** `[CONNECTER]`

### 3.3 Vérifier la connexion

**Dans l'app:**
- Si ✅ **"État: Connecté"** → Bravo! La connexion fonctionne!
- Si ❌ **"État: Hors ligne"** → Vérifier:
  - Les deux appareils sur le même WiFi
  - L'IP correcte dans Settings
  - Que l'ESP32 a bien démarré le server

**Dans le moniteur série (ESP32):**
- Vous verrez:
  ```
  ✅ Client connected from: 192.168.1.XXX
  Sending sensor data...
  ```

---

## 🧪 ÉTAPE 4: Tester les Capteurs (10 minutes)

### 4.1 Voir les données en temps réel

1. **Allez à** l'onglet 🏠 **Dashboard**
2. Vous devrez voir:

```
DONNÉES TEMPS RÉEL:

Accélération:
  X: -0.05g  Y: 0.08g  Z: 9.82g
  Magnitude: 9.82g

Température: 36.5°C

Gyroscope:
  X: 0.1°/s  Y: -0.2°/s  Z: 0.0°/s
```

### 4.2 Vérifier les capteurs

| Test | Action | Résultat attendu |
|------|--------|-----------------|
| **Acutéléro** | Secouez l'ESP32 | X/Y/Z changent beaucoup |
| **Température** | Mettez la main dessus | Température augmente |
| **Gyro** | Tournez l'ESP32 | X/Y/Z changent |
| Z-axis | Laissez plat | Z ≈ 9.8g (gravité) |

✅ **Si tout change quand vous le manipulez → Les capteurs fonctionnent!**

---

## 🚨 ÉTAPE 5: Tester la Détection de Chute (5 minutes)

### Option A: Simulation dans l'app

**La plus sûre!** 😊

1. **Dashboard** → Bouton **[🧪 SIMULER CHUTE]**
2. L'app génère fausses données d'accélération
3. Vous verrez l'alerte popup:
```
🚨 DÉTECTION DE CHUTE
Confiance: 87.3%
[Appeler]  [Annuler]
```

### Option B: Chute controllée (si vous êtes prudent!)

⚠️ **Attention: Ne pas faire tomber l'ESP32 de haut!**

Pour simuler une chute sûr:
1. Tenez l'ESP32 à 30cm de hauteur
2. Laissez tomber sur un coussin/canapé
3. Obs ferve le Dashboard pendant la chute
4. Vous devriez voir:
   - Acceleration spike > 1.5g
   - Si aussi rotation > 100°/s → 🚨 Alerte!

✅ **Si vous recevez une alerte → La détection fonctionne!**

---

## 📊 ÉTAPE 6: Tester les Alertes (5 minutes)

### 6.1 Alerte Température

1. **Settings** → Slider "Alerte haute"
2. Définir à: **37.5°C**
3. **Chauffer** légèrement le capteur MLX90614 (ex: rapprochez votre main)
4. Si température > 37.5°C → 🔴 Alerte TEMP

### 6.2 Historique des Alertes

1. **Dashboard** → Simuler chute **3 fois**
2. **Allez à** l'onglet 🚨 **Alerts History**
3. Vous devrez voir 3 alertes listées:
```
[14:32:15] CHUTE DÉTECTÉE
  Confiance: 85.3%
  [Appeler]  [Marquer résolu]

[14:31:42] CHUTE DÉTECTÉE
  Confiance: 76.8%
  [Appeler]  [Marquer résolu]
```

4. **Cliquez** "Marquer résolu" sur une alerte
5. Elle disparaît de la liste

✅ **Historique fonctionnel!**

---

## ☎️ ÉTAPE 7: Tester SOS Emergency (2 minutes)

### ⚠️ TEST PRUDENT!

1. **Alerts History** → Cliquez **[Appeler]** sur une alerte
2. L'app ouvre l'app téléphone native
3. Un appel est prêt (mais pas encore lancé)
4. **Vérifier** le numéro (Settings → Nº SOS)
5. **Raccrochez immédiatement** (pour test)

✅ **Le système d'appel fonctionne!**

---

## 🔧 ÉTAPE 8: Tests Avancés (optionnel)

### 8.1 Test TCP direct (Python)

Si vous avez Python 3.8+:

```bash
# Aller au dossier
cd C:\Users\hajar_or4e1ft\health_monitor_app\esp32_health_monitor

# Lancer le test
python test_esp32.py

# Quand demandé:
# Enter ESP32 IP: 192.168.1.100
# Enter ESP32 Port: 5000
# Enter number of readings: 10
```

Vous verrez:
```
[14:32:15] #1
  📍 Accel: X=  0.12g  Y= -0.05g  Z=  9.81g  (mag=9.82g)
  🔄 Gyro:  X=  2.1°/s  Y= -1.3°/s  Z=  0.8°/s
  🌡️  Temp: 36.5°C
  📡 RSSI:  -52 dBm
```

✅ **Si ça marche → Connexion TCP stabiliée!**

### 8.2 Vérifier les Performances

| Métrique | Valeur attendue | Votre résultat |
|----------|-----------------|----------------|
| Latence WiFi | < 200ms | _____ |
| Taux données | 10Hz (100ms) | _____ |
| Accu capteur cali | ±0.1g | _____ |
| Temp precision | ±0.5°C | _____ |

---

## ✅ Checklist Finale

Complétez en function de votre test:

```
🔌 Montage Physique
  ☐ ESP32 connecté
  ☐ MPU6050 connecté (I2C 0x68)
  ☐ MLX90614 connecté (I2C 0x5A)
  ☐ Tous les câbles assurez

📥 Firmware
  ☐ Code uploadé sur ESP32
  ☐ Moniteur série montre "TCP Server started"
  ☐ IP WiFi visible dans le moniteur

📱 Application
  ☐ App Flutter lancée sur mobile
  ☐ IP correcte dans Settings
  ☐ État: "Connecté" ✅

🧪 Capteurs
  ☐ Accélération varie avec mouvement
  ☐ Température augmente avec chaleur
  ☐ Gyroscope varie avec rotation
  ☐ Z-axis ≈ 9.8g au repos

🚨 Détection
  ☐ Simulation génère alerte
  ☐ Confiance > 75%
  ☐ Alerte affichée dans l'app

📊 Alerte & Histoire
  ☐ Alertes sauvegardées en historique
  ☐ Marquage "résolu" fonctionne
  ☐ Historique s'efface proprement

☎️ SOS
  ☐ Bouton appel visible
  ☐ Numéro d'urgence correct
  ☐ Appel se lance (ne pas vraiment appeler!)
```

---

## 🆘 Problèmes Courants

### ❌ "Erreur: Carte non reconnue"
```
Solution:
1. Installer le driver CH340G depuis:
   https://www.wemos.cc/en/latest/ch340_driver.html
2. Redémarrer Arduino IDE
3. Sélectionner le port COM correct
```

### ❌ "Erreur: I2C sensors not found"
```
Moniteur série affiche:
  "❌ MPU6050 not found at 0x68"

Solutions:
1. Vérifier les câbles SDA/SCL (GPIO21/22)
2. Vérifier les résistances pull-up (4.7kΩ)
3. Tester avec i2c_scanner.ino
4. Remplacer le capteur si défectueux
```

### ❌ "App dit: Mode test (sans ESP32)"
```
L'app ne trouve pas l'ESP32

Solutions:
1. Les deux appareils sur le même WiFi?
2. L'IP correcte dans Settings?
3. ESP32 a bien démarré? (Look moniteur série)
4. Firewall Android bloque?
   → Settings > Apps > Permissions > Internet
```

### ❌ "Aucune donnée du capteur"
```
Le Dashboard est vide

Solutions:
1. Vérifier connexion WiFi établie (État: Connecté)
2. Vérifier I2C sensors dans moniteur série
3. Redémarrer l'ESP32 (appuyer RESET)
4. Relancer l'app Flutter
```

### ❌ "Alertes ne s'affichent pas"
```
Solutions:
1. Vérifier Confiance > 75% (baisse le seuil dans Settings)
2. Vérifier les paramètres de détection:
   - Sensibilité: 1.0x (défaut)
   - Accélération: 1.5g (défaut)
3. Regarder le moniteur série pour les logs de détection
```

---

## 📝 Notes de Débogage

### Activer les logs détaillés

Dans `esp32_health_monitor.ino`, décommenter (ligne ~100):
```cpp
#define DEBUG_VERBOSE true  // Active tous les logs
```

Recompiler et uploader. Le moniteur affichera plus de détails.

### Enregistrer les données

Pour tester hors-ligne, générer un fichier CSV:

```python
# test_esp32.py modifié
# Recolter 1000 échantillons (100 secondes)
python test_esp32.py > sensor_data.csv
```

Puis analyser avec Excel/Python Pandas.

---

## 📞 Prochaines Étapes

### Si tout fonctionne ✅
- [ ] Tester avec plu users réels
- [ ] Calibrer seuils per-patient (Settings)
- [ ] Tester 8+ heures autonomie
- [ ] Passer en production APK (--release)

### Si certains tests échouent ❌
- [ ] Consulter [SETUP_GUIDE.md](SETUP_GUIDE.md) pour troubleshooting détaillé
- [ ] Vérifier [PHASE_6_INTEGRATION.md](PHASE_6_INTEGRATION.md) pour architecture
- [ ] Revérifier les connexions I2C
- [ ] Trester capteurs individuellement

---

## 💡 Tips Pro

1. **Gardez le moniteur série ouvert** pendant le test → Voyez les erreurs en temps réel
2. **Testez la WiFi** loin du routeur → Vérifiez la portée
3. **Calibrez les seuils** avant déploiement → Chaque utilisateur est différent
4. **Testez les appels d'urgence** sans vraiment appeler → Peut être coûteux!
5. **Gardez des logs** → Utile pour diagnostiquer les problèmes

---

## 🎯 Résumé Test (30-45 min)

| # | Tâche | Durée | Status |
|---|-------|-------|--------|
| 1 | Montage physique | 5 min | ☐ |
| 2 | Upload firmware | 10 min | ☐ |
| 3 | Config app | 5 min | ☐ |
| 4 | Test capteurs | 10 min | ☐ |
| 5 | Test détection | 5 min | ☐ |
| 6 | Test alertes | 5 min | ☐ |
| 7 | Test SOS | 2 min | ☐ |
| **TOTAL** | | **42 min** | ☐ |

---

**Bonne chance avec votre système! 🚀**

*Dernière mise à jour: 16 avril 2026*
