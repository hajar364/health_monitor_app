# ⚡ QUICKSTART (15 MINUTES)

> ⚠️ Pour experts seulement! Lire les guides complets si vous êtes débutant.

---

## 🔌 CONNEXIONS ESSENTIELLES

```
KY-039:    +5V → 220Ω → GPIO35 (via diviseur 10k/20k) | -5V → GND | Signal → GPIO35
DHT22:     +5V | Data → GPIO4 (+ pull-up 10k) | GND
MPU6050:   +5V | SDA → GPIO21 (+ pull-up 10k) | SCL → GPIO22 (+ pull-up 10k) | GND
LED:       +5V → 220Ω → GPIO13 → GND
```

---

## 📲 ÉTAPES

1. **Assembler** (5 min): Suivre MONTAGE_VISUEL_BREADBOARD.md
2. **Code Arduino** (2 min): Copier esp32_health_monitor/esp32_health_monitor.ino
3. **Compiler** (0.5 min): Arduino IDE → Upload
4. **Tester** (2 min): Serial Monitor (115200)
5. **Flutter** (5.5 min): Mettre à jour lib/services, lib/models

---

## ✅ VÉRIFICATIONS

- [ ] Multimètre: 5V entre VCC et GND
- [ ] Serial Monitor affiche: `[✓] DHT22 initialisé` et `[✓] MPU6050 initialisé`
- [ ] LED s'allume lors d'un test d'alerte

---

## 🧪 TEST ALERTE

Appuyer sur GPIO14 2 secondes:
```
→ Messages d'alerte dans Serial Monitor
→ LED clignote 3 fois
```

---

## 📱 FLUTTER

Mettre à jour `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

Puis: `flutter pub get`

---

## 🎯 PRÊT!

L'app affiche maintenant les données en temps réel. 🚀

**Besoin d'aide?** → Voir INDEX_COMPLET.md ou GUIDE_DEPANNAGE_COMPLET.md
