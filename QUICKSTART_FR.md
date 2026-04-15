# 🚀 Démarrage Rapide - Health Monitor Pro

## 5 Minutes pour Démarrer

### Phase 1: Configuration ESP32 (3 min)

**1. Télécharger le code**
```
✓ Le fichier est prêt: esp32_health_monitor/esp32_health_monitor.ino
```

**2. Installer les librairies Arduino IDE**
- Sketch → Include Library → Manage Libraries
- Chercher et installer:
  - `Adafruit MLX90614`
  - `MPU6050` (par Electronic Cats)
  - `ArduinoJson` (version ≥ 6.18)

**3. Configurer Arduino IDE**
```
Tools → Board → esp32 → ESP32 Dev Module
Tools → Flash Frequency → 80MHz
Tools → Upload Speed → 921600
Tools → Port → COM_X (votre port)
```

**4. Téléverser le code**
```
Croquis → Téléverser (Ctrl+U)
Attendre: "Téléversement terminé"
```

**5. Vérifier (Serial Monitor)**
```
Tools → Serial Monitor (115200 baud)
Devriez voir:
  [OK] MLX90614 initialisé
  [OK] MPU6050 initialisé
  === ESP32 Health Monitor - PRÊT ===
```

### Phase 2: Configuration Flutter (2 min)

**1. Installer les dépendances**
```bash
cd health_monitor_app
flutter pub get
```

**2. Configurer Bluetooth (Android)**
- Appareiller l'ESP32 sur le téléphone:
  - Paramètres → Bluetooth
  - Chercher "ESP32_HealthMonitor"
  - Appareiller

**3. Lancer l'app**
```bash
flutter run
```

**4. Se connecter**
- L'app affichera: "Recherche ESP32..."
- Une fois connecté: ✅ "Connecté à ESP32"
- Dashboard affichera les données en temps réel

---

## 🧪 Tests Rapides

### ✅ Test 1: Affichage Température

```
Action: Approcher votre main du MLX90614
Résultat attendu:
  - Dashboard: "Température: 36.8°C"
  - Couleur: Verte (normal)
Durée: 5 secondes
```

### ✅ Test 2: Accélération

```
Action: Pencher/déplacer légèrement l'ESP32
Résultat attendu:
  - Dashboard: "Accélération: 0.5 g"
  - Affichage X, Y, Z
Durée: 1 seconde
```

### ✅ Test 3: Alerte Fièvre

```
Action: Approcher glaçon près du MLX90614 
        (simulation fièvre)
Résultat attendu:
  - Temp → 38-39°C
  - LED s'allume 🔴
  - Dashboard: 🤒 "Fièvre modérée"
  - Son d'alerte 🔔
Durée: 10 secondes
```

### ✅ Test 4: Alerte Chute (Simulation)

```
Action: Déplacer rapidement ESP32 vers le bas
        (simuler chute)
Résultat attendu après 5s immobilité:
  - LED clignotante 🔴
  - Dashboard: 🚨 "Chute détectée"
  - Son urgent 3 bips
  - Dialogue critique "ALERTE CRITIQ UE"
Durée: 6 secondes
```

---

## 📊 Où Voir Quoi

| Page | Qu'afficher | Icône |
|------|----------|-------|
| **Live Dashboard** | Données temps réel | 📊 |
| **Connectivity** | État Bluetooth | 🔗 |
| **Dashboard** | Graphiques/stats | 📈 |
| **History** | Historique mesures | 📜 |
| **Heart Analysis** | FC tendances | ❤️ |
| **Alerts** | Journal des alertes | 🚨 |

---

## 🆘 Aide Rapide

**Q: Pas de données reçues**
```
Vérifier:
1. ✓ Bluetooth activé sur téléphone
2. ✓ Appareillage effectué
3. ✓ ESP32 affiche "[OK]" capteurs
4. ✓ Serial Monitor affiche JSON
→ Redémarrer app Flutter
```

**Q: LED ne s'allume jamais**
```
Vérifier:
1. ✓ Températ sure > 38°C (approcher main)
2. ✓ Ou déplacer ESP32 vite pendant 5s+
3. ✓ LED physiquement en place
4. ✓ GPIO12 libre
→ Tester directement: Commande LED_ON
```

**Q: Les alertes apparaissent plusieurs fois**
```
Normal! La détection est sensible.
Solution:
1. Éloigner la main du capteur
2. Immobiliser l'ESP32
3. Attendre 5s + consigne de "Réinitialiser"
```

---

## 📱 Interface Principale (Live Dashboard)

```
┌────────────────────────┐
│ 🔗 Health Monitor-Live │◄── État Bluetooth
├────────────────────────┤
│  🚨 ALERTE FIÈVRE 🤒   │◄── Banner d'alerte
├────────────────────────┤
│  ❤️ Fréquence Cardiaque │
│  78 BPM | NORMAL       │◄── Métrique 1
├────────────────────────┤
│  🌡️ Température | 36.8°C│
│  NORMALE | Amb: 25°C   │◄── Métrique 2
├────────────────────────┤
│  📈 Accélération        │
│  0.5 g | X/Y/Z data    │◄── Métrique 3
├────────────────────────┤
│  💡 LED d'alerte       │
│  Inactif (gris)        │◄── État LED
├────────────────────────┤
│  📝 Tous paramètres    │
│  stables.              │◄── Note médicale
├────────────────────────┤
│[Mesure][Statut]       │◄── Boutons action
└────────────────────────┘
```

---

## ⚙️ Configuration Facultative

Pour ajuster les seuils (fichier: `ESP32_CONFIGURATION.md`):

```cpp
// Éditer dans esp32_health_monitor.ino
const float TEMP_FEVER = 38.0;        // Fièvre à 38°C (modifier ici)
const int ACC_THRESHOLD = 18000;      // Seuil chute
const int IMMOBILITY_TIME = 5000;     // Temps confirmation
```

Puis **retéléverser** l'ESP32.

---

## 🎓 Apprendre Plus

- 📖 **Guide Complet**: Lire `GUIDE_INTEGRATION_FINALE.md`
- ⚙️ **Configuration ESP32**: Voir `ESP32_CONFIGURATION.md`
- 🐛 **Dépannage**: Section "Dépannage" du guide complet

---

## ✨ Prochaines Actions

1. **✓ Démarrage rapide** (ce fichier)
2. **→ Test sur vrai matériel**
3. **→ Ajuster seuils si besoin**
4. **→ Intégrer serveur backend (optionnel)**
5. **→ Certificat médical si usage professionnel**

---

**Bienvenue dans Health Monitor Pro! 🏥**  
*Prêt à surveiller la santé en temps réel?*

**Besoin d'aide?** Consulter `GUIDE_INTEGRATION_FINALE.md`
