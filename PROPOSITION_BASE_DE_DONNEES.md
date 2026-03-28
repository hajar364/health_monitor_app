# Proposition: Structure de Base de Données pour Health Monitor

## 1. Vue d'Ensemble Stratégique

### 1.1 Objectifs de la BD

La base de données doit:
- ✅ **Stocker** historique complet des mesures (temps réel)
- ✅ **Persister** configuration utilisateur et seuils d'alerte
- ✅ **Archiver** alertes et événements critiques
- ✅ **Supporter** requêtes analytiques (tendances, statistiques)
- ✅ **Optimiser** performances (latence <50ms)
- ✅ **Faciliter** export et rapports

### 1.2 Choix Technologique

#### Comparatif Recommandé

| Critère | **SQLite** | **Hive** | **Firebase** |
|---------|-----------|---------|------------|
| **Performance locale** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Taille max** | 140 TB | GB | Illimité |
| **Requêtes complexes** | ⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐ |
| **Sync cloud** | Non-natif | Non | ⭐⭐⭐⭐ |
| **Facilité setup** | Moyen | Facile | Facile |
| **Coût** | Gratuit | Gratuit | Freemium |
| **Mode offline** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Limité |

**Recommandation: SQLite** (+ Hive pour config)
- Données temps réel: SQLite
- Configuration: Hive (key-value rapide)
- Future: Firebase pour cloud sync

---

## 2. Modèle Entité-Relation (MER)

### 2.1 Schéma Conceptuel

```
┌─────────────────────────────────────────────────────────┐
│                    USER                                 │
│ ┌───────────────────────────────────────────────────┐   │
│ │ userId (PK)                                       │   │
│ │ name                                              │   │
│ │ age                                               │   │
│ │ birthDate                                         │   │
│ │ weight                                            │   │
│ │ height                                            │   │
│ │ medicalConditions (JSON)                          │   │
│ └───────────────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────────────┘
                 │ 1:N
                 │
    ┌────────────────────────────┐
    │                            │
    ▼                            ▼
┌──────────────────┐    ┌──────────────────┐
│  HEALTH_DATA     │    │  ALERT_RULES     │
│ (mesures temps   │    │ (seuils)         │
│  réel)           │    └──────────────────┘
│                  │
│ healthDataId (PK)│
│ userId (FK)      │
│ heartRate        │
│ temperature      │
│ humidity         │
│ accelX/Y/Z       │
│ timestamp        │
│ status           │
│ reason           │
└──────────────────┘
        │
        │ 1:N
        │
        ▼
  ┌──────────────┐
  │   ALERTS     │
  │ (événements) │
  │              │
  │ alertId (PK) │
  │ userId (FK)  │
  │ type         │
  │ severity     │
  │ timestamp    │
  │ description  │
  │ resolved     │
  └──────────────┘
```

---

## 3. Schémas Détaillés (SQLite)

### 3.1 Table USER

```sql
CREATE TABLE user (
  userId INTEGER PRIMARY KEY AUTOINCREMENT,
  
  -- Identité
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  lastModified DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  -- Données anthropométriques
  age INTEGER,
  birthDate DATE,
  weight REAL,
  height REAL,
  gender TEXT CHECK(gender IN ('M', 'F', 'Other')),
  
  -- Historique médical
  medicalHistory TEXT,  -- JSON: {"diabetes": true, "hypertension": false}
  medications TEXT,     -- JSON: [{"name": "...", "dosage": "..."}]
  
  -- Alertes personnelles
  emergencyContact TEXT,
  allergies TEXT,
  
  -- Paramètres app
  theme TEXT DEFAULT 'light',
  language TEXT DEFAULT 'fr',
  notificationsEnabled BOOLEAN DEFAULT 1,
  
  CHECK (weight > 0),
  CHECK (height > 0),
  CHECK (age >= 0 AND age <= 150)
);

CREATE UNIQUE INDEX idx_user_username ON user(username);
CREATE INDEX idx_user_email ON user(email);
```

**Exemple INSERT:**
```sql
INSERT INTO user (username, email, age, weight, height, gender)
VALUES ('john_doe', 'john@example.com', 32, 75.5, 180, 'M');
```

### 3.2 Table HEALTH_DATA

```sql
CREATE TABLE health_data (
  healthDataId INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  
  -- Mesures capteurs
  heartRate REAL NOT NULL CHECK(heartRate >= 0),
  temperature REAL NOT NULL CHECK(temperature >= 30 AND temperature <= 50),
  humidity REAL CHECK(humidity >= 0 AND humidity <= 100),
  
  -- IMU (Inertial Measurement Unit)
  accelX REAL,
  accelY REAL,
  accelZ REAL,
  
  -- Calculs dérivés
  accelMagnitude REAL,  -- sqrt(X² + Y² + Z²)
  activity REAL,        -- 0-10 indice d'activité
  
  -- Statut et contexte
  status TEXT CHECK(status IN ('normal', 'warning', 'alert')),
  reason TEXT,  -- Explication anomalie
  
  -- Horodatage
  timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Métadonnées
  source TEXT DEFAULT 'esp32',  -- 'esp32', 'manual', 'imported'
  confidence REAL DEFAULT 1.0,  -- 0-1, certitude mesure
  
  FOREIGN KEY (userId) REFERENCES user(userId) ON DELETE CASCADE
);

-- Indices pour performance
CREATE INDEX idx_health_data_userId_timestamp 
  ON health_data(userId, timestamp DESC);
CREATE INDEX idx_health_data_timestamp 
  ON health_data(timestamp DESC);
CREATE INDEX idx_health_data_status 
  ON health_data(status);

-- Logique pour calcul magnétude
CREATE TRIGGER calculate_accel_magnitude
AFTER INSERT ON health_data
BEGIN
  UPDATE health_data 
  SET accelMagnitude = SQRT(
    NEW.accelX * NEW.accelX + 
    NEW.accelY * NEW.accelY + 
    NEW.accelZ * NEW.accelZ
  )
  WHERE healthDataId = NEW.healthDataId;
END;
```

**Exemple INSERT:**
```sql
INSERT INTO health_data (userId, heartRate, temperature, humidity, accelX, accelY, accelZ, status)
VALUES (1, 72.5, 36.8, 45.0, 0.05, -0.1, 1.02, 'normal');
```

**Footprint mémoire:**
- Par mesure: ~80 bytes
- 1 jour (1Hz): ~6.9 MB
- 1 an: ~2.5 GB (manageable)

### 3.3 Table ALERT_RULES

```sql
CREATE TABLE alert_rules (
  ruleId INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  
  -- Paramètre surveillé
  metric TEXT NOT NULL CHECK(metric IN 
    ('heartRate', 'temperature', 'humidity', 'activity')),
  
  -- Seuils
  minValue REAL,
  maxValue REAL,
  
  -- Sensibilité
  severity TEXT CHECK(severity IN ('info', 'warning', 'critical')),
  
  -- Activation
  isEnabled BOOLEAN DEFAULT 1,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (userId) REFERENCES user(userId) ON DELETE CASCADE,
  UNIQUE(userId, metric)
);
```

**Valeurs par défaut recommandées:**

```sql
INSERT INTO alert_rules (userId, metric, minValue, maxValue, severity)
VALUES
  (1, 'heartRate', 40, 120, 'warning'),
  (1, 'heartRate', 30, 150, 'critical'),
  (1, 'temperature', 36.5, 37.5, 'warning'),
  (1, 'temperature', 35, 39, 'critical'),
  (1, 'humidity', 30, 70, 'warning');
```

### 3.4 Table ALERTS

```sql
CREATE TABLE alerts (
  alertId INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  healthDataId INTEGER,  -- Référence à la mesure qui a déclenché
  
  -- Contenu alerte
  type TEXT CHECK(type IN ('anomaly', 'threshold', 'pattern', 'manual')),
  severity TEXT NOT NULL CHECK(severity IN ('info', 'warning', 'critical')),
  title TEXT NOT NULL,
  description TEXT,
  
  -- Recommandations
  recommendation TEXT,  -- Ex: "Prenez votre repos"
  
  -- État
  isResolved BOOLEAN DEFAULT 0,
  resolvedAt DATETIME,
  
  -- Horodatage
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  dismissedAt DATETIME,
  
  -- Métadonnées
  tags TEXT,  -- JSON: ["fever", "resting", "follow-up"]
  
  FOREIGN KEY (userId) REFERENCES user(userId) ON DELETE CASCADE,
  FOREIGN KEY (healthDataId) REFERENCES health_data(healthDataId)
);

-- Index pour requêtes rapides
CREATE INDEX idx_alerts_userId_createdAt 
  ON alerts(userId, createdAt DESC);
CREATE INDEX idx_alerts_severity 
  ON alerts(severity);
CREATE INDEX idx_alerts_isResolved 
  ON alerts(isResolved);
```

**Exemple INSERT:**
```sql
INSERT INTO alerts (userId, healthDataId, type, severity, title, description)
VALUES (
  1, 
  12345, 
  'threshold', 
  'critical', 
  'Fréquence cardiaque élevée',
  'FC détectée à 145 BPM (seuil: 120 BPM)'
);
```

### 3.5 Table ACTIVITY_LOG

```sql
CREATE TABLE activity_log (
  logId INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  
  -- Activité
  action TEXT NOT NULL,  -- 'alert_dismissed', 'threshold_updated', 'data_exported'
  metadata TEXT,  -- JSON pour détails
  
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (userId) REFERENCES user(userId) ON DELETE CASCADE
);

CREATE INDEX idx_activity_log_userId_timestamp 
  ON activity_log(userId, timestamp DESC);
```

---

## 4. Stratégies de Requête

### 4.1 Requête: Historique Dernier 7 Jours

```sql
SELECT 
  timestamp,
  heartRate,
  temperature,
  status,
  reason
FROM health_data
WHERE userId = ?
  AND timestamp >= datetime('now', '-7 days')
ORDER BY timestamp DESC;
```

**Performance:** Index sur (userId, timestamp) → O(log N)

### 4.2 Requête: Statistiques Quotidiennes

```sql
SELECT 
  DATE(timestamp) as date,
  ROUND(AVG(heartRate), 1) as avg_hr,
  MIN(heartRate) as min_hr,
  MAX(heartRate) as max_hr,
  ROUND(AVG(temperature), 1) as avg_temp,
  COUNT(CASE WHEN status = 'alert' THEN 1 END) as alert_count
FROM health_data
WHERE userId = ? 
  AND timestamp >= datetime('now', '-30 days')
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

### 4.3 Requête: Alertes Non Résolues

```sql
SELECT 
  alertId,
  title,
  severity,
  description,
  createdAt,
  (SELECT heartRate FROM health_data WHERE healthDataId = alerts.healthDataId) as measured_value
FROM alerts
WHERE userId = ? AND isResolved = 0
ORDER BY createdAt DESC
LIMIT 10;
```

### 4.4 Requête: Tendance Anomalies

```sql
SELECT 
  DATE(timestamp) as date,
  COUNT(*) as anomaly_count,
  GROUP_CONCAT(DISTINCT reason) as reasons
FROM health_data
WHERE userId = ? 
  AND status IN ('warning', 'alert')
  AND timestamp >= datetime('now', '-30 days')
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

---

## 5. Stratégie d'Archivage et Rétention

### 5.1 Politique de Rétention

```
Données fraîches (0-30 jours)
  ↓
Archive court terme (31-90 jours)  → Résolution: 1 minute
  ↓
Archive moyen terme (91-365 jours) → Résolution: 1 heure
  ↓
Export/Cloud (>1 year)
```

### 5.2 Script d'Archivage

```sql
-- Créer table archive
CREATE TABLE health_data_archive AS 
SELECT * FROM health_data 
WHERE timestamp < datetime('now', '-90 days');

-- Supprimer anciennes données
DELETE FROM health_data 
WHERE timestamp < datetime('now', '-90 days');

-- Optimiser index
VACUUM;
REINDEX;
```

### 5.3 Agrégation Horaire (pour long terme)

```sql
CREATE TABLE health_data_hourly (
  hourlyId INTEGER PRIMARY KEY,
  userId INTEGER NOT NULL,
  hour DATETIME NOT NULL,
  
  heartRate_avg REAL,
  heartRate_min REAL,
  heartRate_max REAL,
  
  temperature_avg REAL,
  humidity_avg REAL,
  
  alert_count INTEGER,
  
  FOREIGN KEY (userId) REFERENCES user(userId),
  UNIQUE(userId, hour)
);

-- Remplir table horaire depuis brutes
INSERT INTO health_data_hourly
SELECT 
  NULL,
  userId,
  datetime(timestamp, 'start of hour') as hour,
  AVG(heartRate),
  MIN(heartRate),
  MAX(heartRate),
  AVG(temperature),
  AVG(humidity),
  COUNT(CASE WHEN status IN ('warning', 'alert') THEN 1 END)
FROM health_data
WHERE timestamp >= datetime('now', '-90 days')
GROUP BY userId, datetime(timestamp, 'start of hour');
```

---

## 6. Configuration Hive (Key-Value Store)

Complément SQLite pour données fréquemment accédées:

```dart
// Configuration utilisateur
final settingsBox = await Hive.openBox('settings');

settingsBox.put('theme', 'dark');
settingsBox.put('language', 'fr');
settingsBox.put('notificationsEnabled', true);

// Seuils d'alerte (cache)
final alertThresholdsBox = await Hive.openBox('alert_thresholds');

alertThresholdsBox.put('heartRate_min', 40);
alertThresholdsBox.put('heartRate_max', 120);
alertThresholdsBox.put('temperature_fever', 38.0);

// Last measurement (pour affichage rapide)
final lastDataBox = await Hive.openBox('last_measurement');

lastDataBox.put('lastHealthData', jsonEncode(healthData.toJson()));
lastDataBox.put('lastUpdate', DateTime.now().toString());
```

**Avantage:** Accès O(1) pour configuration + persistance

---

## 7. Implémentation Flutter

### 7.1 Service d'Accès BD

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'health_monitor.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Exécuter tous les CREATE TABLE ici
    await db.execute(''' ... ''');
  }
}
```

### 7.2 Repository Pattern

```dart
class HealthDataRepository {
  final DatabaseService _dbService = DatabaseService();

  // Insérer mesure
  Future<void> insertHealthData(HealthData data) async {
    final db = await _dbService.database;
    await db.insert(
      'health_data',
      data.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer dernières mesures
  Future<List<HealthData>> getLastMeasurements(int days) async {
    final db = await _dbService.database;
    final result = await db.query(
      'health_data',
      where: 'timestamp >= datetime("now", ?)',
      whereArgs: ['-$days days'],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => HealthData.fromJson(map)).toList();
  }

  // Statistiques du jour
  Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    final db = await _dbService.database;
    final result = await db.rawQuery('''
      SELECT 
        AVG(heartRate) as avg_hr,
        MIN(heartRate) as min_hr,
        MAX(heartRate) as max_hr,
        COUNT(CASE WHEN status = "alert" THEN 1 END) as alerts
      FROM health_data
      WHERE DATE(timestamp) = ? AND userId = ?
    ''', [date.toString().split(' ')[0], userId]);
    
    return result.first;
  }
}
```

---

## 8. Migration Données

### 8.1 Schéma de Version

```dart
// Version 1: Schéma initial
const int dbVersion = 1;

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Migration v1 → v2
    await db.execute('ALTER TABLE health_data ADD COLUMN confidence REAL DEFAULT 1.0');
  }
  if (oldVersion < 3) {
    // Migration v2 → v3
    await db.execute('CREATE TABLE activity_log (...)');
  }
}
```

### 8.2 Export CSV

```dart
Future<String> exportToCsv(DateTime startDate, DateTime endDate) async {
  final repository = HealthDataRepository();
  final data = await repository.getMeasurementsBetween(startDate, endDate);
  
  String csv = 'timestamp,heartRate,temperature,humidity,status,reason\n';
  for (var measurement in data) {
    csv += '${measurement.timestamp},${measurement.heartRate},${measurement.temperature},...\n';
  }
  
  // Sauvegarder fichier
  final file = File('${appDir}/export_${DateTime.now().timestamp}.csv');
  await file.writeAsString(csv);
  
  return file.path;
}
```

---

## 9. Considérations de Sécurité

### 9.1 Chiffrement

```dart
// Utiliser sqflite_common_ffi_web avec chiffrement
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final db = await databaseFactoryFfi.openDatabase(
  path,
  options: OpenDatabaseOptions(
    // Le chiffrement peut être ajouté via Secure Enclave sur iOS
  ),
);
```

### 9.2 Permissions

```dart
// Android: Demander WRITE_EXTERNAL_STORAGE pour export
// iOS: Documents/ privé, pas d'accès direct fichiers BD
```

---

## 10. Optimisations Performance

### 10.1 Batch Insert pour Sync Massive

```dart
Future<void> syncBatch(List<HealthData> measurements) async {
  final db = await _dbService.database;
  final batch = db.batch();
  
  for (var data in measurements) {
    batch.insert('health_data', data.toJson());
  }
  
  await batch.commit(noResult: true);  // Pas d'attente résultats
}
```

**Performance:** 10000 enregistrements: ~200ms vs 10s avec inserts individuels

### 10.2 Pagination

```dart
Future<List<HealthData>> getPage(int pageNumber, int pageSize) async {
  final db = await _dbService.database;
  final offset = pageNumber * pageSize;
  
  return await db.query(
    'health_data',
    orderBy: 'timestamp DESC',
    limit: pageSize,
    offset: offset,
  );
}
```

### 10.3 Analyse Requêtes

```sql
EXPLAIN QUERY PLAN
SELECT * FROM health_data
WHERE userId = 1 AND timestamp > datetime('now', '-7 days');

-- Vérifier qu'index est utilisé:
-- SEARCH health_data USING INDEX idx_health_data_userId_timestamp
```

---

## 11. Schéma Firebase (Alternative Futur)

```json
/users/{uid}/
  ├── profile/
  │   ├── name: "John Doe"
  │   ├── age: 32
  │   └── medicalHistory: {...}
  │
  ├── healthData/{documentId}/
  │   ├── heartRate: 72.5
  │   ├── temperature: 36.8
  │   ├── timestamp: 1648392000000
  │   └── status: "normal"
  │
  ├── alerts/{documentId}/
  │   ├── type: "threshold"
  │   ├── severity: "critical"
  │   ├── timestamp: 1648392000000
  │   └── resolved: false
  │
  └── alertRules/{documentId}/
      ├── metric: "heartRate"
      ├── minValue: 40
      └── maxValue: 120
```

**Collection Sharding pour scalabilité:**
```
/users/{uid}/healthData_2024_03/{docId}
/users/{uid}/healthData_2024_04/{docId}
```

---

## 12. Plan de Migration Étapes

### Étape 1: Implémentation SQLite
```
✓ Créer schéma BD (10h)
✓ Implémenter DatabaseService (5h)
✓ Créer Repository pattern (5h)
→ Total: 20h
```

### Étape 2: Intégration Hive
```
✓ Setup Hive pour config (3h)
✓ Cache dernière mesure (2h)
→ Total: 5h
```

### Étape 3: Tests + Optimisation
```
✓ Tests unitaires (8h)
✓ Benchmark performance (4h)
✓ Optimiser index (3h)
→ Total: 15h
```

### Étape 4: Cloud Sync (Future)
```
✓ Intégration Firebase (10h)
✓ Sync bidirectionnel (8h)
√ Tests E2E (5h)
→ Total: 23h
```

---

## 13. Checklist Implémentation

- [ ] Créer tables SQLite (schema.sql)
- [ ] Implémenter DatabaseService
- [ ] Créer HealthDataRepository
- [ ] Intégrer avec ESP32Service
- [ ] Tester insertion données
- [ ] Implémenter requêtes analytiques
- [ ] Setup Hive pour configuration
- [ ] Créer export CSV
- [ ] Tests performance (batch insert)
- [ ] Documenter migrations
- [ ] Chiffrement BD (optionnel)
- [ ] Backup automatique
- [ ] Monitoring taille BD

---

## 14. Conclusion

Cette architecture BD offre:

✅ **Scalabilité** - Jusqu'à 2.5GB/an, requêtes <50ms  
✅ **Flexibilité** - Migration future vers Firebase  
✅ **Performance** - Index optimisés, batch processing  
✅ **Sécurité** - Données locales, export contrôlé  
✅ **Maintenabilité** - Repository pattern, migrations versionnées

**Pour commencer:**
1. Créer fichier `database/schema.sql`
2. Implémenter `services/database_service.dart`
3. Tester avec `test/database_test.dart`

---

**Fin de la Proposition**
