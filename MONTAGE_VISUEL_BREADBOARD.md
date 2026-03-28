# 🔌 GUIDE VISUEL DE MONTAGE - ÉTAPE PAR ÉTAPE

## MATÉRIEL NÉCESSAIRE

```
Outils:
☐ Tournevis (très fin, pour micro-vis)
☐ Multimètre
☐ Pince à dénuder (optional, pour isoler les fils)
☐ Ruban isolant (pour protéger les contacts)

Composants:
☐ 1x ESP32-DevKit-C
☐ 1x Breadboard 830 points minimum
☐ 1x KY-039 (Capteur Fréquence Cardiaque)
☐ 1x DHT22 (Capteur Température/Humidité)
☐ 1x MPU6050 (Capteur Accélération)
☐ 1x LED Rouge (3mm ou 5mm)
☐ 3x Résistance 10kΩ (pull-up I2C + DHT)
☐ 2x Résistance 20kΩ (diviseur tension FC)
☐ 1x Résistance 220Ω (limitation LED)
☐ ~50 Fils Jumper (mâle-femelle et mâle-mâle)
☐ 1x Câble USB (alimentation ou USB-Serial)
```

---

## 📐 DISPOSITION SUR LA BREADBOARD

```
Légende:
+ = Rail positive (VCC 5V)
- = Rail négative (GND)
= = Séparation centrale
# = Composant
. = Trou libre


        COL:  A  B  C  D  E  │  F  G  H  I  J
            ┌─ ┬─ ┬─ ┬─ ┬─ ──┼─ ┬─ ┬─ ┬─ ┬─ ┐
    RANG 1  │ + ║ ║ ║ ║ ║ ║  │  ║ ║ ║ ║ + ║
            ├─ ╫─ ╫─ ╫─ ╫─ ──┼─ ╫─ ╫─ ╫─ ╫─ ┤
    RANG 2  │ - ║ ║ ║ ║ ║ ║  │  ║ ║ ║ ║ - ║
            ├─ ╫─ ╫─ ╫─ ╫─ ──┼─ ╫─ ╫─ ╫─ ╫─ ┤
    RANG 3  │   ║ ║ ║ ║ ║ ║  │  ║ ║ ║ ║   ║
            ├─ ╫─ ╫─ ╫─ ╫─ ──┼─ ╫─ ╫─ ╫─ ╫─ ┤
    ...     │   ║ ║ ║ ║ ║ ║  │  ║ ║ ║ ║   ║
            └─ ┴─ ┴─ ┴─ ┴─ ──┴─ ┴─ ┴─ ┴─ ┴─ ┘

DISPOSITION RECOMMANDÉE:
Colonne A-B: Rail VCC (5V) et GND
Colonne C-E: ESP32 (côté gauche)
Colonne F: Séparation centrale (vide)
Colonne G-I: Capteurs (côté droit)
```

---

## 📍 ÉTAPE 1: PRÉPARER LES RAILS DE PUISSANCE

```
Vue de face de la breadboard:

     [USB 5V]
         │
    ┌────┴────────────────┐
    │ + + + + + + + + + + │
    │ - - - - - - - - - - │
    │
    └─────────────────────┘

Action:
1. Placer la breadboard devant vous (rangées horizontales)
2. Brancher USB sur courant externe
3. Utiliser fils ROUGES pour les rails positifs (5V)
4. Utiliser fils NOIRS pour les rails négatifs (GND)
5. Vérifier avec multimètre: 5V entre + et -
```

**Vérification:**
```
Multimètre en voltmètre CC (DC Voltage):
→ Pointe rouge sur rail +5V
→ Pointe noire sur rail GND
→ Doit afficher: 5.0V (accepter 4.8-5.2V)
```

---

## 🔴 ÉTAPE 2: IMPLANTER L'ESP32

```
Vue de haut (face du ESP32):

     [USB]
      │ │
      V V
    ┌─────────────┐
    │ GND  ESP32  VIN │
    │ GPIO12      GPIO13 │
    │ GPIO14      GPIO15 │
    │ GPIO2       GPIO0  │
    │ GPIO4       GPIO5  │
    │ GPIO16      GPIO17 │
    │ GPIO5       GPIO18 │
    │ GPIO19      GPIO21 │
    │ GPIO22      GPIO23 │
    │ GPIO25      GPIO26 │
    │ GPIO27      GPIO32 │
    │ GPIO33      GPIO34 │
    │ GPIO35      GND    │
    └─────────────┘

Action dans la breadboard:
1. Positionner ESP32 au CENTRE GAUCHE (colonnes C-E)
2. Les broches doivent aller dans les trous de la breadboard
3. ⚠️ NE PAS FORCER! Si ça ne rentre pas, vérifier l'orientation
4. Laisser au moins 2 rangées libres au-dessus et au-dessous

Important:
☐ Ne pas tordre les broches
☐ Vérifier que GND de ESP32 est connecté au rail GND
☐ Vérifier que VIN de ESP32 est connecté au rail +5V
```

---

## 🟡 ÉTAPE 3: MONTRER LE DIVISEUR DE TENSION (KY-039)

```
Problème:
KY-039 sort du 5V, mais ESP32 GPIO35 accepte que 3.3V max!
→ Solution: Diviseur de tension

Formule diviseur:
Vout = Vin × R2 / (R1 + R2)
Vout = 5V × 20kΩ / (10kΩ + 20kΩ) = 3.33V ✓

Montage sur breadboard:

        KY-039 Signal (5V)
            │
            │
        ┌───┴────┐
        │         │
       [R1]      │
      10kΩ      │
        │        │
        └────┬───┤
             │   │
           [R2]  └─→ ESP32 GPIO35 (3.3V)
          20kΩ
             │
            GND

Position physique:
1. Placer KY-039 à droite de la breadboard (colonne H)
2. KY-039 (+5V) → R1 (10kΩ) → ligne signal
3. De cette ligne: en haut vers GPIO35 ET en bas vers R2
4. R2 (20kΩ) → GND

Vérification multimètre:
→ Entre KY-039 signal et GND: 5V
→ Entre GPIO35 et GND: 3.3V (après R2)
```

---

## 🔵 ÉTAPE 4: MONTRER LE DHT22

```
Montage DHT22:

    DHT22 (3 broches)
    ┌─────┬─────┬─────┐
    │  VCC│ Data│ GND │
    └─────┴────┬────┴─────┘
        │      │      │
        │      │      GND (fil noir)
        │      │
        │    [R3]  ← Résistance pull-up 10kΩ
        │    10kΩ  (entre Data et VCC)
        │      │
        +5V   GPIO4

Position physique sur breadboard:
1. DHT22 s'insère dans 3 trous consécutifs (colonnes G, H, I)
2. DHT VCC → fil rouge → rail +5V
3. DHT Data → fil bleu → GPIO4 (+ résistance pull-up)
4. DHT GND → fil noir → rail GND

Important:
☐ La broche VCC doit être bien en 5V
☐ La résistance pull-up DOIT être sur la ligne Data
☐ Pas de fil cassé (capteur très sensible)
```

---

## 🟢 ÉTAPE 5: MONTRER LE MPU6050

```
MPU6050 (I2C):
┌────────────────────────┐
│ GND  SCL  SDA  VCC │ (en haut du module)
└────┬───┬───┬───┬───┘
     │   │   │   │

                 ESP32
           ┌─────┬───────┐
           │ GPIO21│ GPIO22   │
           │  (SDA)│  (SCL)  │
           └──┬─────┴────┬───┘
              │         │
   ┌──────┐   │     ┌──────┐
   │ R4   │   │     │ R5   │
   │ 10kΩ │   │     │ 10kΩ │  ← Pull-ups I2C
   │      │   │     │      │
   └──┬───┘   │     └──┬───┘
      │       │         │
      └───┬───┘         │
          └─────────┬───┘
                    │
              MPU6050
              SDA/SCL

Position physique:
1. MPU6050 à côté du DHT22 (colonnes I-J environ)
2. MPU GND → fil noir → rail GND
3. MPU VCC → fil rouge → rail +5V
4. MPU SCL → GPIO22 (colonne E) + résistance 10kΩ vers +5V
5. MPU SDA → GPIO21 (colonne E) + résistance 10kΩ vers +5V

⚠️ ATTENTION I2C:
Les pull-ups DOIVENT être en place!
Sinon l'ESP32 ne verra pas le capteur.
```

---

## 🔴 ÉTAPE 6: MONTRER LA LED D'ALERTE

```
Montage LED:

        +5V
         │
        [R6] ← Résistance 220Ω
        220Ω
         │
        │  │
        │←┘│  ← LED (longue broche = +)
        │  │
         └──→ GPIO13
             
            GND

Position physique:
1. LED colonne G ligne 20
2. Broche longue de la LED → R6 (220Ω) → rail +5V
3. Broche courte de la LED → fil noir → GPIO13

Vérification:
- Avant de brancher: vérifier polarité LED
  Broche longue toujours vers le positif!
```

---

## 🧪 ÉTAPE 7: VÉRIFICATION COMPLÈTE AVANT ALIMENTATION

```
CHECKLIST FINAL:

ALIMENTATION:
☐ +5V bien connecté aux rails
☐ GND connecté aux rails
☐ Multimètre 5V entre + et -

CONNEXIONS ESP32:
☐ ESP32 complètement inséré
☐ GND ESP32 → rail GND
☐ VIN ESP32 → rail +5V
☐ Aucune broche pliée

CAPTEURS:
☐ KY-039: +5V, GND, Signal via diviseur
☐ DHT22: +5V, GND, Data avec pull-up
☐ MPU6050: +5V, GND, I2C (SDA/SCL) avec pull-ups
☐ LED: +5V via 220Ω, GND via GPIO13

SYSTÈME:
☐ Pas de fils nus qui se touchent
☐ Pas de court-circuit visible
☐ Tous les composants bien enfoncés
☐ Aucun fil qui pend

SÉCURITÉ:
☐ Éteindre avant tout changement
☐ Attendre 10 secondes après débranchement
☐ Pas de liquide près de la breadboard
☐ Température des composants acceptables
```

---

## 📸 PHOTOS DE RÉFÉRENCE

### Configuration type vue de haut:

```
┌─────────────────────────────────────────┐
│  RANGÉE 1  (VCC rails)                  │
│  + + + + + + + + + + + + + + + + + + + + │
│                                          │
│  RANGÉE 2  (GND rails)                  │
│  - - - - - - - - - - - - - - - - - - - - │
│                                          │
│  RANGÉE 3-10                            │
│  ║ GND     ║ ║ ║ ║ ║    ║ ║ KY-039      │
│  ║ VIN 5V  ║ ESP32 ║    ║ ║  │         │
│  ║ GPIO4   ║ ║ ║ ║ ║    ║ ║ Data       │
│  ║ GPIO21  ║ ║ ║ ║ ║    ║ ║    DHT22   │
│  ║ GPIO22  ║ ║ ║ ║ ║    ║ │            │
│  ║ GPIO13  ║ ║ ║ ║ ║    ║ ║ MPU6050    │
│  ║ GPIO35  ║ ║ ║ ║ ║    ║ ║            │
│                                          │
│  RANGÉE 11+  (Free space)               │
│  ║ ║ ║ ║ ║ ║ ║ ║ ║ ║ ║ ║              │
│                                          │
└─────────────────────────────────────────┘
```

---

## 🎯 RÉSUMÉ RAPIDE

```
Position des composants:

ESP32: Colonnes C-E (Au centre-gauche)
KY-039: Colonne H (Diviseur de tension présent)
DHT22: Colonne G-H (Pull-up 10kΩ sur Data)
MPU6050: Colonnes I-J (Pull-ups sur I2C)
LED: Colonne G (Avec 220Ω en série)
```

---

## ✅ PRÊT À BRANCHER?

Une fois que vous voyez:
- ✓ Tous les fils bien enfoncés
- ✓ 5V sur les rails
- ✓ Pas de court-circuit visible
- ✓ Tous les composants en place
- ✓ Pas de fil nus qui se touchent

👉 Vous pouvez maintenant BRANCHER le câble USB et téléverser le code Arduino!

**Bon assemblage! 🚀**
