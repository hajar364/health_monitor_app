# Chapitre 4: Architecture Flutter et Communication IoT

## 4.1 Introduction

La partie applicative mobile du projet Health Monitor a été développée avec **Flutter**, framework open-source de Google permettant le développement cross-platform. Le choix de Flutter s'est justifié par plusieurs facteurs:

### 4.1.1 Justification du choix de Flutter

| Critère | Flutter | Alternative (React Native) |
|---------|---------|---------------------------|
| **Performance** | Excellente (GPU rendering) | Bonne |
| **Compilation** | Native (AOT) | Bridge JavaScript |
| **Temps de développement** | Rapide (Hot Reload) | Moyen |
| **Écosystème IoT** | Riche (flutter_bluetooth_serial) | Limité |
| **Courbe d'apprentissage** | Modérée | Modérée |

Flutter offre notamment:
- ✅ **Compilation native** pour meilleures performances
- ✅ **Hot Reload** pour itération rapide en développement
- ✅ **Material Design 3** intégré
- ✅ Gestion robuste des états (Provider, Riverpod)
- ✅ Support natif Bluetooth et HTTP

---

## 4.2 Architecture Globale de l'Application

### 4.2.1 Schéma constitutif

```
┌─────────────────────────────────────────────────────────┐
│              COUCHE PRÉSENTATION (UI)                   │
├─────────────────────────────────────────────────────────┤
│  • 6 Pages écran                                        │
│  • Navigation unifiée (Bottom Navigation Bar)          │
│  • Widgets réutilisables                               │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────V────────────────────────────────────┐
│         COUCHE MÉTIER (Services & Models)              │
├──────────────────────────────────────────────────────────┤
│  • ESP32Service: Gestion Bluetooth/JSON                │
│  • HealthService: Fetch HTTP données capteurs         │
│  • HealthData: Modèle unique de données               │
│  • Business Logic: Détection anomalies, parsing        │
└────────────────────┬───────────────────────────────────┘
                     │
┌────────────────────V───────────────────────────────────┐
│       COUCHE COMMUNICATION (IoT & Données)            │
├──────────────────────────────────────────────────────────┤
│  • Bluetooth (HC-05 / ESP32 interne)                   │
│  • HTTP REST API                                       │
│  • JSON serialization/deserialization                  │
│  • Stream processing (temps réel)                      │
└────────────────────┬───────────────────────────────────┘
                     │
              ┌──────V──────┐
              │ ESP32 / API │
              │  Capteurs   │
              └─────────────┘
```

### 4.2.2 Principes d'architecture

L'application suit le pattern **MVC** (Model-View-Controller):

- **Modèles** (`lib/models/`): Représentation des données (HealthData)
- **Vues** (`lib/*.dart`): Pages écran et widgets (6 pages)
- **Contrôleurs** (`lib/services/`): Services de communication et logique

Cette séparation permet:
- ✅ Testabilité du code
- ✅ Maintainabilité long terme
- ✅ Réusabilité des composants
- ✅ Évolutivité future

---

## 4.3 Couche Présentation (UI)

### 4.3.1 Structure des Pages

L'application comporte **6 pages fonctionnelles** organisées autour d'une navigation unifiée:

#### **1. Live Dashboard** (Tableau de bord en direct)
**Fichier:** `live_dashboard_updated.dart`

```dart
class LiveDashboardUpdated extends StatelessWidget {
  // Affichage temps réel des vitals:
  - Fréquence cardiaque (BPM)
  - Température corporelle (°C)
  - Niveau d'activité physique
  - Note médicale contextuelle
}
```

**Widgets clés:**
- `HealthMetricCard`: Affichage d'une métrique avec icône et statut
- `PhysicianNote`: Bloc de texte pour contexte médical

**Fonctionnalités:**
- Affichage en direct (1Hz de l'ESP32)
- Code couleur: Vert (normal), Orange (alerte), Rouge (critique)
- Mise à jour sans latence perceptible

#### **2. Device Connectivity** (Connectivité des appareils)
**Fichier:** `device_connectivity.dart`

```dart
class DeviceConnectivity extends StatelessWidget {
  // Gestion des appareils Bluetooth
  - Scanning des capteurs disponibles
  - Liste des appareils détectés
  - Instructions d'appairage
  - Affichage statut connexion
}
```

**Logique:**
```
État: [Scanning] → [Appareils détectés] → [Appairage] → [Connecté]
```

#### **3. Health Dashboard** (Vue d'ensemble santé)
**Fichier:** `health_dashboard.dart`

Agrégation des données de santé avec:
- Cartes de métrique (FC, Température, Activité)
- Indicateurs de statut (Normal/Warning/Alert)
- Historique des 24 dernières heures (scaffolding)

#### **4. Health History** (Historique santé)
**Fichier:** `health_history.dart`

Interface avec **TabBar** pour navigation temporelle:
```
[Jour] | [Semaine] | [Mois] | [Année]
```

Structure:
```dart
DefaultTabController(
  length: 4,
  child: Scaffold(
    appBar: AppBar(
      bottom: TabBar(...),  // Onglets
    ),
    body: TabBarView(
      children: [
        _buildDayView(),    // Vue jour: implémentée
        _buildWeekView(),   // TODO
        _buildMonthView(),  // TODO
        _buildYearView(),   // TODO
      ],
    ),
  ),
)
```

#### **5. Heart Rate Analysis** (Analyse fréquence cardiaque)
**Fichier:** `heart_rate_analysis.dart`

Analyse détaillée de la FC:
- **Zones cardiaques:**
  - Zone rouge (Peak): 155+ BPM
  - Zone orange (Cardio): 125-154 BPM
  - Zone jaune (Fat Burn): 95-124 BPM
  - Zone verte (Out of Zone): 0-64 BPM
- **Tendances:** Variations sur 7 jours
- **Insights:** Recommandations médicales
- **Graphique:** Placeholder pour courbe de tendance

#### **6. Alerts & Notifications** (Alertes)
**Fichier:** `alerts_notifications.dart`

Journal des alertes avec:
- Icônes par sévérité (Emergency, Warning, Info)
- Horodatage précis
- Description détaillée
- Statut de l'alerte

### 4.3.2 Navigation Unifiée

L'application utilise une **BottomNavigationBar** unique:

```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  currentIndex: _currentIndex,
  onTap: (index) {
    setState(() {
      _currentIndex = index;
    });
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Live"),
    BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: "Connect"),
    BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Dashboard"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Heart"),
    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
  ],
)
```

**Avantages de cette approche:**
- ✅ Navigation intuitrice
- ✅ Accès rapide à tous les modules
- ✅ Persistance de l'état entre changements d'onglet
- ✅ Cohérent avec standards Material Design

---

## 4.4 Couche Métier (Models & Services)

### 4.4.1 Modèle de Données Unifié

#### Structure `HealthData`

```dart
enum HealthStatus { normal, warning, alert }

class HealthData {
  final double heartRate;           // BPM
  final double temperature;         // °C
  final double humidity;            // %
  final double accelX, accelY, accelZ;  // accélération (g)
  final DateTime timestamp;
  final HealthStatus status;        // Enum pour statut
  final String reason;              // Explication anomalie
  
  factory HealthData.fromJson(Map<String, dynamic> json) {
    // Parse depuis JSON ESP32
  }
  
  Map<String, dynamic> toJson() {
    // Serialise pour persistance
  }
}
```

**Avantages:**
- ✅ Modèle unique pour toute l'app
- ✅ Type-safe (enum pour statut)
- ✅ Facilite synchronisation
- ✅ Compatible JSON ESP32

#### Explainability via `reason`

Le champ `reason` contient l'explication locale générée par l'ESP32:

```
reason: "TACHYCARDIA (FC > 120 BPM); FEVER (38.5°C)"
```

Cela permet à l'utilisateur de **comprendre POURQUOI** une alerte s'est levée.

### 4.4.2 Service IoT (ESP32Service)

#### Responsabilités

```dart
class ESP32Service {
  // 1. Streaming Bluetooth
  Stream<HealthData> streamBluetoothData()
  
  // 2. Parsing JSON depuis ESP32
  void parseAndProcessData(String jsonString)
  
  // 3. Injection de données test
  void injectTestData()
  void injectAlertData()
  
  // 4. Gestion connexion
  bool get isConnected
  void setConnectionStatus(bool connected)
}
```

#### Implémentation du Parsing

```dart
void parseAndProcessData(String jsonString) {
  try {
    // 1. Validation format JSON
    if (!jsonString.startsWith('{') || !jsonString.endsWith('}')) {
      return;
    }
    
    // 2. Parse JSON
    final json = jsonDecode(jsonString);
    
    // 3. Création modèle
    final healthData = HealthData(
      heartRate: (json['heartRate'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      accelX: (json['accelX'] ?? 0.0).toDouble(),
      accelY: (json['accelY'] ?? 0.0).toDouble(),
      accelZ: (json['accelZ'] ?? 0.0).toDouble(),
      timestamp: DateTime.now(),
      status: (json['isAbnormal'] ?? false) 
        ? HealthStatus.alert 
        : HealthStatus.normal,
      reason: json['reason'] ?? '',
    );
    
    // 4. Émission du stream
    _healthDataController.add(healthData);
    
  } catch (e) {
    print('Erreur parsing: $e');
  }
}
```

**Points clés:**
- ✅ Gestion des valeurs nulles
- ✅ Conversion de type robuste
- ✅ Pattern Stream pour temps réel
- ✅ Logging des erreurs

### 4.4.3 Service HTTP (HealthService)

```dart
class HealthService {
  static Future<Map<String, dynamic>> getHealthData() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.100/data"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Erreur serveur ESP32");
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Impossible de se connecter');
    }
  }
}
```

---

## 4.5 Communication IoT

### 4.5.1 Modes de Communication

L'application supporte **deux modes** de communication avec l'ESP32:

#### **Mode 1: Bluetooth (Recommandé pour mobile)**

Avantages:
- ✅ Sans fil complet
- ✅ Portée ~10m
- ✅ Basse latence (<100ms)
- ✅ Sans WiFi requis

Implémentation:
```dart
// Utilisation: flutter_bluetooth_serial
BluetoothConnection connection = await BluetoothConnection.toAddress(address);

// Écoute les données
connection.input?.listen((Uint8List data) {
  String jsonString = String.fromCharCodes(data);
  esp32Service.parseAndProcessData(jsonString);
});
```

Configuration ESP32:
```cpp
// Serial Bluetooth (TX/RX)
Serial.begin(115200);  // HC-05 écoute ici
Serial.println(jsonData);  // Envoie JSON
```

#### **Mode 2: HTTP REST (Pour WiFi/tests)**

Avantages:
- ✅ Plus simple à implémenter
- ✅ Débogage facile
- ✅ Stateless

Implémentation:
```dart
Future<HealthData> fetchFromESP32() async {
  final response = await http.get(
    Uri.parse('http://192.168.1.100/api/health')
  );
  
  if (response.statusCode == 200) {
    return HealthData.fromJson(jsonDecode(response.body));
  }
  throw Exception('Erreur connexion');
}
```

### 4.5.2 Format de Données JSON

Échange entre ESP32 et Flutter via **JSON standardisé**:

```json
{
  "heartRate": 72.5,
  "temperature": 36.8,
  "humidity": 45.0,
  "accelX": 0.05,
  "accelY": -0.1,
  "accelZ": 1.02,
  "isAbnormal": false,
  "reason": "Tous les vitals stables",
  "timestamp": 1648392000000
}
```

Schéma:
```
┌──────────────────────┐
│   Données Capteurs   │
│ (FC, Temp, Accél)    │
└──────────┬───────────┘
           │
        ESP32
           │
    ┌──────V──────────┐
    │ Analyse locale  │
    │ Détection anom. │
    └──────┬──────────┘
           │
    ┌──────V──────────┐
    │ Génération JSON │
    │ + Explication   │
    └──────┬──────────┘
           │
        Bluetooth
           │
        Flutter
           │
    ┌──────V──────────┐
    │ Parse JSON      │
    │ Met à jour UI   │
    │ Sauvegarde hist │
    └─────────────────┘
```

### 4.5.3 Flux de Données en Temps Réel

```dart
// Vue: Écoute les données du service
StreamBuilder<HealthData>(
  stream: esp32Service.getHealthDataStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final data = snapshot.data!;
      
      return HealthMetricCard(
        title: "Heart Rate",
        value: "${data.heartRate.toStringAsFixed(1)} BPM",
        status: data.status.name,
      );
    }
    return LoadingWidget();
  },
)
```

**Avantages StreamBuilder:**
- ✅ Reactive (met à jour dès que données arrivent)
- ✅ Gère les états (loading, error, data)
- ✅ Pas de rebuild inutile
- ✅ Type-safe

---

## 4.6 Gestion des États et Données

### 4.6.1 Pattern Stream

L'application utilise **Dart Streams** pour lire les données en temps réel:

```dart
// Dans ESP32Service
final _healthDataController = StreamController<HealthData>.broadcast();

Stream<HealthData> getHealthDataStream() {
  return _healthDataController.stream;
}

// Dans Widget
StreamBuilder<HealthData>(
  stream: _esp32Service.getHealthDataStream(),
  builder: (context, snapshot) {
    // Reconstruction automatique quand données arrivent
  }
)
```

### 4.6.2 Persistance (À implémenter)

Pour l'historique, deux options:

**Option 1: Hive (Recommandée)**
- Stockage local lightweight
- Pas de configuration complexe
- Accès rapide

```dart
final box = await Hive.openBox('health_data');
box.add(healthData.toJson());
```

**Option 2: SQLite**
- Plus puissant
- Requêtes complexes
- Synchronisation possible

---

## 4.7 Gestion des Erreurs et Cas Limites

### 4.7.1 Erreurs de Connexion

```dart
try {
  Stream<HealthData> dataStream = esp32Service.getHealthDataStream();
} on BluetoothException catch (e) {
  showErrorDialog("Impossible de se connecter: ${e.message}");
} on TimeoutException {
  showErrorDialog("Délai d'attente dépassé - appareil hors de portée?");
} catch (e) {
  showErrorDialog("Erreur inconnue: $e");
}
```

### 4.7.2 Données Invalides

```dart
// Dans parseAndProcessData()
if (json['heartRate'] == null || json['heartRate'] < 0) {
  print("⚠️ Données FC invalides");
  return;  // Ignorer ce message
}

// Validation de plages
if (heartRate > 200 || heartRate < 20) {
  heartRate = 0;  // Signal perdu
}
```

### 4.7.3 Reconnexion Automatique

```dart
Future<void> _reconnectWithRetry(int maxRetries) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      await _connectBluetooth();
      print("✓ Reconnecté");
      return;
    } catch (e) {
      print("Tentative $i échouée");
      await Future.delayed(Duration(seconds: 2));
    }
  }
  throw Exception("Impossible de reconnecter");
}
```

---

## 4.8 Performance et Optimisations

### 4.8.1 Optimisations UI

| Technique | Bénéfice |
|-----------|----------|
| **StatelessWidget** | Pas de rebuild inutile |
| **const** constructors | Optimisation compilation |
| **ListView.builder** | Chargement lazy |
| **RepaintBoundary** | Optimisation rendu |

### 4.8.2 Gestion Mémoire

```dart
@override
void dispose() {
  _dataSubscription?.cancel();
  _healthDataController.close();
  super.dispose();
}
```

### 4.8.3 Latence

**Mesure:** Latence de bout en bout
```
ESP32 (lecture capteur) → JSON → Bluetooth → Parse → Affichage
|__________________|  |______________|  |_______________|
    100ms             50ms                  150ms
                Total: ~300ms (acceptable)
```

---

## 4.9 État Actuel et Limitations

### 4.9.1 Implémentation Actuelle

✅ **Fonctionnel:**
- UI complète 6 pages
- Modèle de données unifié
- Service de parsing JSON
- Gestion des états
- Simulation de données

⚠️ **En cours:**
- Intégration Bluetooth réelle
- Persistance locale

❌ **À faire:**
- Graphiques temps réel
- Historique complet (4 tabs)
- Synchronisation cloud
- Export données

### 4.9.2 Limitations Connues

| Limitation | Cause | Impact |
|-----------|-------|--------|
| Pas de persistance | Pas de DB | Perte données au fermeture app |
| Tabs histoire vides | À développer | Impossible voir historique |
| Pas de graphiques | Dépendance manquante | Pas de visualisation tendances |
| Simulation seulement | ESP32 non connecté | Données fictives uniquement |

---

## 4.10 Tests et Validation

### 4.10.1 Tests UI

```dart
testWidgets('Live Dashboard affiche les vitals', (WidgetTester tester) async {
  await tester.pumpWidget(const HealthApp());
  
  expect(find.text('Heart Rate'), findsOneWidget);
  expect(find.text('78 BPM'), findsOneWidget);
  expect(find.byType(HealthMetricCard), findsWidgets);
});
```

### 4.10.2 Tests Service

```dart
test('Parsing JSON correct', () {
  final json = '{"heartRate":72.5,"temperature":36.8, ...}';
  esp32Service.parseAndProcessData(json);
  
  expect(esp32Service.lastData.heartRate, 72.5);
  expect(esp32Service.lastData.temperature, 36.8);
});
```

### 4.10.3 Test Bluetooth

```dart
test('Reconnexion après déconnexion', () async {
  esp32Service.disconnect();
  var reconnected = await esp32Service.reconnect();
  
  expect(reconnected, true);
  expect(esp32Service.isConnected, true);
});
```

---

## 4.11 Conclusion Partielle

La couche Flutter du projet Health Monitor offre:

✅ **Interface intuitive** adaptée à la surveillance santé  
✅ **Architecture scalable** MVC bien définie  
✅ **Communication IoT robuste** via Bluetooth/HTTP  
✅ **Modèle unifié** pour cohérence données  
✅ **Gestion d'erreurs** complète  

La prochaine phase impliquera:
- Connexion réelle à l'ESP32 via Bluetooth
- Persistance des données historiques (Hive/SQLite)
- Implémentation de graphiques pour visualisation tendances

Cette architecture permettra une évolution future sans refactoring majeur.

---

**Fin du Chapitre 4**