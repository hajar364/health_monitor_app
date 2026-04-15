# Exemples d'Utilisation - Health Monitor Pro

Ce fichier montre comment utiliser les différents services de l'app.

---

## 1. Utiliser le Service Bluetooth

### Exemple 1.1: Se Connecter à l'ESP32

```dart
import 'services/bluetooth_esp32_service.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final BluetoothESP32Service _btService = BluetoothESP32Service();

  @override
  void initState() {
    super.initState();
    _connectToESP32();
  }

  Future<void> _connectToESP32() async {
    // Option 1: Se connecter au premier ESP32 trouvé
    bool connected = await _btService.connectToFirstESP32();
    
    if (connected) {
      print('✅ Connecté!');
    } else {
      print('❌ Connexion échouée');
    }
  }

  @override
  void dispose() {
    _btService.dispose();
    super.dispose();
  }
}
```

### Exemple 1.2: Écouter les Données

```dart
class MyPage extends StatelessWidget {
  final BluetoothESP32Service _btService = BluetoothESP32Service();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<HealthData>(
        stream: _btService.healthDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          
          return Column(
            children: [
              Text('Temp: ${data.temperature}°C'),
              Text('FC: ${data.heartRate} BPM'),
              Text('Status: ${data.status.name}'),
              if (data.isAbnormal)
                Text('⚠️ ${data.reason}', style: TextStyle(color: Colors.red)),
            ],
          );
        },
      ),
    );
  }
}
```

### Exemple 1.3: Envoyer des Commandes

```dart
// Demander une mesure immédiate
await _btService.requestMeasurement();

// Demander le statut de l'ESP32
await _btService.requestStatus();

// Allumer la LED
await _btService.activateLED();

// Éteindre la LED
await _btService.deactivateLED();

// Configurer l'intervalle de mesure (500ms)
await _btService.setMeasureInterval(500);

// Déconnecter
await _btService.disconnect();
```

---

## 2. Utiliser le Service d'Alerte

### Exemple 2.1: Détecter et Afficher les Alertes

```dart
import 'services/alert_service.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final AlertService _alertService = AlertService();
  
  @override
  void initState() {
    super.initState();
    
    // Écouter les alertes critiques
    _alertService.alertStream.listen((data) {
      // Afficher une alerte visuelle
      AlertService.showAlertSnackBar(context, data);
      
      // Si critique, afficher dialogue
      if (data.isCritical) {
        AlertService.showCriticalAlertDialog(context, data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Traiter les données de santé
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Injecter une alerte de test
          _alertService.processHealthData(
            HealthData(
              heartRate: 88,
              temperature: 38.5,
              timestamp: DateTime.now(),
              status: HealthStatus.alert,
              alertType: AlertType.fever,
              reason: '🤒 Fièvre modérée (38.5°C)',
            ),
          );
        },
        child: Text('Test Alerte Fièvre'),
      ),
    );
  }

  @override
  void dispose() {
    _alertService.dispose();
    super.dispose();
  }
}
```

### Exemple 2.2: Contrôler les Alertes

```dart
final AlertService alerts = AlertService();

// Activer/Désactiver le mode silencieux
alerts.setMuted(true);    // Mode silencieux
alerts.setMuted(false);   // Alertes activées

// Réinitialiser le cooldown des alertes
alerts.resetAlertCooldowns();

// Vérifier si en mode silencieux
bool isMuted = alerts.isMuted;
```

---

## 3. Modèle de Données HealthData

### Exemple 3.1: Créer des Données

```dart
import 'models/health_data.dart';

// Créer une mesure normale
final normalData = HealthData(
  heartRate: 72,
  temperature: 36.8,
  humidity: 55,
  accelX: 0.05,
  accelY: 0.1,
  accelZ: 0.95,
  timestamp: DateTime.now(),
  status: HealthStatus.normal,
  reason: 'Santé normale',
);

// Créer une alerte fièvre
final feverAlert = HealthData(
  heartRate: 88,
  temperature: 38.5,
  timestamp: DateTime.now(),
  status: HealthStatus.alert,
  alertType: AlertType.fever,
  reason: '🤒 Fièvre modérée (38.5°C)',
);

// Créer une alerte chute
final fallAlert = HealthData(
  heartRate: 95,
  temperature: 36.5,
  accelX: 2.5,
  accelY: 1.8,
  accelZ: 0.3,
  timestamp: DateTime.now(),
  status: HealthStatus.alert,
  alertType: AlertType.fall,
  reason: '🚨 Chute détectée',
);
```

### Exemple 3.2: Parser depuis JSON

```dart
// JSON reçu de l'ESP32
final jsonData = {
  "temperature": 36.8,
  "temperatureAmbient": 25.0,
  "accelX": 0.05,
  "accelY": 0.1,
  "accelZ": 0.95,
  "fallDetected": false,
  "feverDetected": false,
  "hypothermiaDetected": false,
  "ledActive": false,
  "status": "OK",
  "alertStatus": "NORMAL",
  "timestamp": 1234567890
};

// Parser en HealthData
final data = HealthData.fromJson(jsonData);

// Accéder aux propriétés
print('Température: ${data.temperature}°C');
print('Status: ${data.status.name}');
print('Is critical: ${data.isCritical}');
print('Alert description: ${data.alertDescription}');
```

### Exemple 3.3: Exporter en JSON

```dart
final data = HealthData(
  heartRate: 72,
  temperature: 36.8,
  timestamp: DateTime.now(),
);

// Exporter en JSON
final json = data.toJson();
print(jsonEncode(json));
// Sortie: {"heartRate":72,"temperature":36.8,...}
```

---

## 4. Service ESP32 (Parsing)

### Exemple 4.1: Parser Manuellement des Données

```dart
import 'services/esp32_service.dart';

final esp32Service = ESP32Service();

// JSON brut reçu
final jsonString = '''{
  "temperature": 38.5,
  "fallDetected": false,
  "feverDetected": true,
  "timestamp": 1234567890
}''';

// Parser
esp32Service.parseAndProcessData(jsonString);

// Les données sont émises via le stream
esp32Service.streamBluetoothData().listen((data) {
  print('Données parsées: $data');
  print('Status: ${data.status}');
  print('Reason: ${data.reason}');
});
```

### Exemple 4.2: Injecter des Données de Test

```dart
final esp32Service = ESP32Service();

// Injecter donnée normale
esp32Service.injectTestData();

// Injecter alerte fièvre
esp32Service.injectFeverAlert();

// Injecter alerte chute
esp32Service.injectFallAlert();

// Injecter hypothermie
esp32Service.injectHypothermiaAlert();

// Écouter les données injectées
esp32Service.streamBluetoothData().listen((data) {
  print('✅ ${data.alertDescription}');
  print('📊 ${data.temperature}°C');
});
```

---

## 5. Intégration Complète (Widget Exemple)

```dart
import 'package:flutter/material.dart';
import 'services/bluetooth_esp32_service.dart';
import 'services/alert_service.dart';
import 'models/health_data.dart';

class HealthMonitorWidget extends StatefulWidget {
  @override
  State<HealthMonitorWidget> createState() => _HealthMonitorWidgetState();
}

class _HealthMonitorWidgetState extends State<HealthMonitorWidget> {
  late BluetoothESP32Service _btService;
  late AlertService _alertService;
  HealthData? _currentData;

  @override
  void initState() {
    super.initState();
    _btService = BluetoothESP32Service();
    _alertService = AlertService();
    
    // Établir la connexion
    _connectAndListen();
  }

  Future<void> _connectAndListen() async {
    // Connecter
    await _btService.connectToFirstESP32();

    // Écouter les données
    _btService.healthDataStream.listen((data) {
      setState(() => _currentData = data);
      
      // Traiter les alertes
      _alertService.processHealthData(data);
      
      // Afficher alerte si critique
      if (data.isCritical) {
        AlertService.showCriticalAlertDialog(context, data);
      }
    });
  }

  @override
  void dispose() {
    _btService.dispose();
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) {
      return Center(child: CircularProgressIndicator());
    }

    final data = _currentData!;

    return Scaffold(
      appBar: AppBar(title: Text('Health Monitor')),
      body: Column(
        children: [
          // Status badge
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: data.isAbnormal ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    data.alertDescription,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    data.reason,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Métriques
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildMetric(
                  '🌡️ Température',
                  '${data.temperature.toStringAsFixed(1)}°C',
                  data.temperatureAmbient != null
                    ? 'Ambiance: ${data.temperatureAmbient!.toStringAsFixed(1)}°C'
                    : '',
                ),
                _buildMetric(
                  '❤️ Fréquence Cardiaque',
                  '${data.heartRate.toStringAsFixed(0)} BPM',
                  '',
                ),
                _buildMetric(
                  '📈 Accélération',
                  '${data.accelMagnitude.toStringAsFixed(2)} g',
                  'X: ${data.accelX}, Y: ${data.accelY}, Z: ${data.accelZ}',
                ),
              ],
            ),
          ),

          // Boutons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _btService.requestMeasurement(),
                    icon: Icon(Icons.refresh),
                    label: Text('Mesurer'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _btService.requestStatus(),
                    icon: Icon(Icons.info),
                    label: Text('Statut'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, String detail) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (detail.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(detail, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}
```

---

## 6. Cas d'Usage Avancés

### Exemple 6.1: Enregistrer les Alertes

```dart
class AlertLogger {
  final List<HealthData> _alertHistory = [];

  void logAlert(HealthData alert) {
    _alertHistory.add(alert);
    print('📝 Alerte enregistrée: ${alert.alertDescription}');
  }

  List<HealthData> getAlertsByType(AlertType type) {
    return _alertHistory.where((a) => a.alertType == type).toList();
  }

  void exportToJSON() {
    final json = _alertHistory.map((a) => a.toJson()).toList();
    print(jsonEncode(json));
  }
}
```

### Exemple 6.2: Statistiques de Santé

```dart
class HealthStats {
  final List<HealthData> measurements;

  HealthStats(this.measurements);

  double get averageTemp {
    return measurements.fold(0.0, (sum, m) => sum + m.temperature)
      / measurements.length;
  }

  double get maxTemp {
    return measurements.map((m) => m.temperature).reduce((a, b) => a > b ? a : b);
  }

  int get totalAlerts {
    return measurements.where((m) => m.isAbnormal).length;
  }

  String getSummary() {
    return '''
    =========== RÉSUMÉ DE SANTÉ ===========
    Mesures: ${measurements.length}
    Temp moyenne: ${averageTemp.toStringAsFixed(1)}°C
    Temp max: ${maxTemp.toStringAsFixed(1)}°C
    Alertes: $totalAlerts
    ''';
  }
}
```

---

## 7. Configuration pour les Tests

### Exemple 7.1: Mode Test (Sans Matériel)

```dart
class MockHealthMonitor {
  final esp32Service = ESP32Service();

  void simulateNormalOperation() {
    Future.delayed(Duration(seconds: 1), () {
      esp32Service.injectTestData();
    });
  }

  void simulateFeverAlert() {
    Future.delayed(Duration(seconds: 2), () {
      esp32Service.injectFeverAlert();
    });
  }

  void simulateFallAlert() {
    Future.delayed(Duration(seconds: 3), () {
      esp32Service.injectFallAlert();
    });
  }
}

// Utilisation
void testAlert() {
  final mock = MockHealthMonitor();
  mock.simulateFeverAlert();  // Test fièvre après 2s
}
```

---

**Fin des Exemples**

Pour plus d'informations, consulter le `GUIDE_INTEGRATION_FINALE.md`.
