# Phase 6 - Intégration Flutter App + Firmware ESP32

## 🎯 Objectif
Connecter l'app Flutter sur mobile avec le firmware ESP32 via WiFi/TCP pour tester le système complet de détection de chute.

---

## 📋 Architecture

```
┌─────────────────┐                    ┌──────────────────┐
│  Flutter App    │                    │  ESP32 Firmware  │
│   (Mobile)      │                    │                  │
├─────────────────┤      WiFi/TCP      ├──────────────────┤
│  - Dashboard    │◄───────[:5000]────►│  - MPU6050      │
│  - Alerts       │    (100ms tick)    │  - MLX90614     │
│  - Patients     │      (JSON)        │  - TCP Server   │
│  - Settings     │                    │                 │
└─────────────────┘                    └──────────────────┘
       │                                        │
       │                                        │
       ▼                                        ▼
  [WiFi Client]                           [WiFi AP]
```

---

## 🔧 Prérequis

**Hardware:**
- ✅ ESP32 avec firmware Phase 6 uploadé
- ✅ MPU6050 + MLX90614 connectés
- ✅ Mobile TECNO BD2d avec app Flutter
- ✅ Même réseau WiFi (2.4GHz)

**Software:**
- ✅ Firmware `esp32_health_monitor.ino` compilé ✅
- ✅ App Flutter built & running ✅
- ✅ Python 3.x (pour test script)

---

## 🚀 Étapes d'Intégration

### 1. Préparer ESP32

**Sur le ESP32:**

1. Ouvre `esp32_health_monitor.ino` ligne 35-36
2. Édite WiFi SSID et PASSWORD
3. Compile et upload
4. Vérifier dans Serial Monitor:
   ```
   ✅ MPU6050 initialisé
   ✅ MLX90614 initialisé
   📍 IP: 192.168.1.100
   ✅ Serveur TCP démarré sur port 5000
   ```

### 2. Préparer Flutter App

**Sur le mobile:**

1. Ouvre l'app Fall Detection
2. Va à l'onglet **Settings** (⚙️)
3. Entre l'IP de l'ESP32:
   - **WiFi IP**: `192.168.1.100` (adapter selon ta config)
   - **Port**: `5000`
4. Clique **Save** ou **Connect**

### 3. Tester Connexion

**Vérifier que ça fonctionne:**

- Dashboard affiche: **"Connecté ✅"** (vert)
- Les capteurs à jour en temps réel
- LED sur ESP32 s'allume (bleu normal, rouge si chute)

**Si erreur:**
- Vérifie IP ESP32 correcte
- Même réseau WiFi
- Port 5000 ouvert
- Firewall autorise connexion

---

## 🧪 Test Scénarios

### Scenario 1: Impact Normal (Marche)

**Attendu:**
- ✅ Accel: ~9.8g normal
- ❌ Pas de détection chute
- 📍 Affichage stable

**Résultat:** ✅ Pas de fausse alerte

---

### Scenario 2: Simulation Chute (App)

**Sur le Dashboard:**
1. Clique bouton **"🧪 SIMULER CHUTE"**
2. Devrait afficher:
   ```
   🚨 ALERTE CHUTE DÉTECTÉE
   Confiance: 85.3%
   Sévérité: HIGH
   ```

**Résultat:** ✅ Alerte correctement triggered

---

### Scenario 3: Chute Réelle (Si disponible)

1. Laisse l'ESP32 au repos
2. Accélère verticalement (simule chute)
3. Devrait afficher alerte **automatiquement**
4. LED ESP32 clignote en rouge

**Résultat:** ✅ Détection en temps réel

---

## 📊 Données Affichées en Direct

### Dashboard
```
🏥 DÉTECTION DE CHUTE

État ESP32: Connecté ✅
IP: 192.168.1.100 / Port: 5000

Données Capteurs (Temps réel):
  Accélération: X: 0.15g Y: 0.08g Z: 9.81g
  Magnétude Accélération: 9.82 g
  Température: 36.7°C
  Gyroscope: X: 1.2°/s

[Bouton: 🧪 SIMULER CHUTE]
```

### Historique Alertes
```
📜 HISTORIQUE ALERTES

[2024-04-16 14:32:15] 🚨 CHUTE
  Confiance: 85.3%
  Sévérité: 🔴 HIGH
  Patient: Jean Dupont
  [Appeler] [Marquer résolu]
```

### Paramètres WiFi
```
⚙️ PARAMÈTRES

📡 WiFi Configuration:
  IP ESP32: 192.168.1.100
  Port: 5000
  [Tester connexion]

🔽 Seuils Détection:
  Sensibilité: ████░ (1.0x)
  Accélération: ████░ (1.5g)
  Délai confirmation: █████ (500ms)
```

---

## 🔍 Monitoring & Debug

### Option 1: Serial Monitor (ESP32)

```bash
# Arduino IDE → Tools → Serial Monitor (115200 baud)
```

Affiche en temps réel:
```
🚨 CHUTE DÉTECTÉE!
Accel Mag: 15.2g, Gyro Mag: 250°/s
Position sol: ✅
Confiance: 92%
```

### Option 2: Python Test Script

```bash
cd esp32_health_monitor
python3 test_esp32.py
```

Affiche:
```
[14:32:15] #127
  📍 Accel: X=  0.12g  Y= -0.05g  Z=  9.81g  (mag=9.82g)
  🔄 Gyro:  X=  2.1°/s  Y= -1.3°/s  Z=  0.8°/s
  🌡️  Temp: 36.7°C
  📡 RSSI:  -52 dBm
```

### Option 3: Flutter Logs

```bash
flutter logs
```

Affiche dans la console:
```
I/flutter: ✅ Connecté à ESP32
I/flutter: 📊 Données reçues: {"timestamp":..., "accel":{...}}
I/flutter: 🚨 Chute détectée!
```

---

## 🔧 Troubleshooting

### ❌ "Mode test (sans ESP32)" au lieu de "Connecté"

**Causes possibles:**
1. ESP32 n'est pas allumé
2. Serveur TCP n'a pas démarré sur port 5000
3. IP incorrecte dans Settings
4. Firewall bloque port 5000

**Solutions:**
```bash
# Vérifie ESP32 allumé
# Serial → Check "✅ Serveur TCP démarré"

# Vérifie IP correcte
ping 192.168.1.100

# Vérifie port ouvert
netstat -an | grep 5000

# Reset ESP32
# Appuie RST button 2 secondes
```

---

### ❌ "Connexion fermée après 5s"

**Cause:** ESP32 crash ou déconnecte

**Solutions:**
1. Vérifier Serial Monitor ESP32 (erreurs?)
2. Vérifier capteurs initialisés
3. Check I2C pull-ups (10kΩ)
4. Augmente TIMEOUT dans app (lib/services/wifi_tcp_service.dart)

---

### ❌ Capteurs pas reconnus

**Checking MPU6050:**
```
❌ MPU6050 non trouvé!
```

- Vérifie GPIO21 (SDA) et GPIO22 (SCL)
- Adresse I2C? (devrait être 0x68)
- Tension 3.3V?

**Checking MLX90614:**
```
❌ MLX90614 non trouvé!
```

- Adresse I2C? (devrait être 0x5A)
- Lentille thermique propre?
- Tension 3.3V?

---

## 📈 Performance Attendue

| Métrique | Valeur | Notes |
|----------|--------|-------|
| **Latence** | <200ms | WiFi + traitement |
| **Fréquence** | 10Hz | 100ms update |
| **Accuracy** | >90% | Sur falls simulés |
| **Consommation** | ~100mA | WiFi actif |
| **Portée WiFi** | ~50m | 2.4GHz indoor |

---

## ✅ Checklist Intégration

- [ ] ESP32 firmware uploadé & testé
- [ ] App Flutter built & installée
- [ ] IP/Port configurés dans Settings
- [ ] Dashboard affiche "Connecté ✅"
- [ ] Données capteurs en temps réel
- [ ] Simulation chute trigger alerte
- [ ] Alerte sauvegardée en historique
- [ ] LED ESP32 clignote sur chute
- [ ] Network latency acceptable (<200ms)

---

## 🚀 Prochaines Étapes

1. **Test sur terrain:**
   - Tester avec vraies chutes (contrôlées!)
   - Calibrer seuils si nécessaire

2. **Optimisations:**
   - Réduire latence WiFi
   - Calibrer sensibilités par patient
   - Persister données chutes

3. **Production:**
   - Build APK release signée
   - Deploy sur Play Store
   - Intégration backend serveur

---

## 📞 Support

Si problème:
1. Check Serial Monitor (ESP32 logs)
2. Exécute `test_esp32.py`
3. Vérifie réseau WiFi
4. Redémarre ESP32 + App
5. Check GitHub issues / Documentation
