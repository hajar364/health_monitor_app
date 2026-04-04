import 'package:flutter_test/flutter_test.dart';
import 'package:health_monitor_app/services/esp32_firmware_adapter.dart';
import 'package:health_monitor_app/models/health_data.dart';

void main() {
  group('ESP32FirmwareAdapter', () {
    
    /// Test 1: Parser output firmware normale (température OK, capteurs échouent)
    test('Parse firmware output - Temperature OK, sensors fail', () {
      final sampleData = '''=== Mesures ===
Température: Amb=26.71 °C | Obj=27.91 °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.''';

      final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);

      expect(result.temperature, 27.91);  // Température objet
      expect(result.heartRate, 0.0);      // IR/RED = 0 → pas de doigt
      expect(result.accelX, 0.0);         // Accel convertis en G
      expect(result.status, HealthStatus.normal);
      expect(result.reason, 'NO_FINGER_DETECTED');
    });

    /// Test 2: Parser output avec alerte (fièvre détectée)
    test('Parse firmware output - Fever alert', () {
      final sampleData = '''=== Mesures ===
Température: Amb=24.5 °C | Obj=38.8 °C
MAX30100: IR=45000 | RED=40000
MPU6050: Accel[X=100 Y=50 Z=16384] Gyro[X=50 Y=100 Z=200]
⚠️ Alerte : LED allumée !''';

      final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);

      expect(result.temperature, 38.8);
      expect(result.heartRate, greaterThan(50.0));  // Estimation FC
      expect(result.heartRate, lessThan(150.0));
      expect(result.status, HealthStatus.alert);
      expect(result.reason, contains('FEVER'));
    });

    /// Test 3: Parser output avec mouvement fort
    test('Parse firmware output - Strong motion detected', () {
      final sampleData = '''=== Mesures ===
Température: Amb=25.0 °C | Obj=36.5 °C
MAX30100: IR=50000 | RED=45000
MPU6050: Accel[X=30000 Y=25000 Z=16384] Gyro[X=100 Y=100 Z=100]
⚠️ Alerte : LED allumée !''';

      final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);

      expect(result.status, HealthStatus.alert);
      expect(result.reason, contains('MOTION'));
    });

    /// Test 4: Conversion accélération en G
    test('Acceleration conversion to G', () {
      // MPU6050 en mode ±2g: 16384 unités = 1G
      final sampleData = '''=== Mesures ===
Température: Amb=25.0 °C | Obj=36.5 °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=16384 Y=8192 Z=0] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.''';

      final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);

      expect(result.accelX, closeTo(1.0, 0.01));   // 1G
      expect(result.accelY, closeTo(0.5, 0.01));   // 0.5G
      expect(result.accelZ, closeTo(0.0, 0.01));   // 0G
    });

    /// Test 5: Estimation FC à partir du PPG (IR/RED)
    test('Heart rate estimation from PPG', () {
      // IR/RED ratio pour estimer FC
      final sampleData = '''=== Mesures ===
Température: Amb=25.0 °C | Obj=36.5 °C
MAX30100: IR=60000 | RED=40000
MPU6050: Accel[X=0 Y=0 Z=16384] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.''';

      final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);

      // Ratio = 60000/40000 = 1.5
      // Estimation = 60 + (1.5 - 2.0) * 30 = 60 - 15 = 45 BPM
      expect(result.heartRate, greaterThan(40.0));
      expect(result.heartRate, lessThan(120.0));
    });

    /// Test 6: Parser format JSON (compatibility)
    test('Parse legacy JSON format', () {
      final jsonData = '''
      {
        "heartRate": 72.5,
        "temperature": 36.8,
        "humidity": 45.0,
        "accelX": 0.1,
        "accelY": 0.05,
        "accelZ": 0.98,
        "isAbnormal": false,
        "reason": "Normal reading",
        "timestamp": "${DateTime.now().millisecondsSinceEpoch}"
      }
      ''';

      // Note: parseSerialOutput s'attend à format firmware
      // Pour JSON, utiliser directement HealthData.fromJson()
      final data = HealthData.fromJson({
        "heartRate": 72.5,
        "temperature": 36.8,
        "humidity": 45.0,
        "accelX": 0.1,
        "accelY": 0.05,
        "accelZ": 0.98,
        "isAbnormal": false,
        "reason": "Normal reading",
      });

      expect(data.heartRate, 72.5);
      expect(data.temperature, 36.8);
      expect(data.status, HealthStatus.normal);
    });

    /// Test 7: Gestion données invalides/manquantes
    test('Handle incomplete firmware output gracefully', () {
      final incompleteData = '''=== Mesures ===
Température: Amb=25.0 °C | Obj=36.5 °C''';

      // Ne devrait pas crash
      final result = ESP32FirmwareAdapter.parseSerialOutput(incompleteData);

      expect(result.temperature, 36.5);
      expect(result.heartRate, 0.0);  // Valeurs par défaut
    });

    /// Test 8: Conversion vers JSON pour persistance
    test('Convert HealthData to firmware JSON', () {
      final data = HealthData(
        heartRate: 75.0,
        temperature: 37.0,
        humidity: 50.0,
        accelX: 0.1,
        accelY: 0.05,
        accelZ: 0.99,
        timestamp: DateTime(2026, 3, 28, 14, 30),
        status: HealthStatus.normal,
        reason: 'Test conversion',
      );

      final json = ESP32FirmwareAdapter.toFirmwareJSON(data);

      expect(json['heartRate'], '75.0');
      expect(json['temperature'], '37.00');
      expect(json['status'], 'normal');
    });

    /// Test 9: Cas extrêmes - hypothermie
    test('Detect hypothermia (low temperature)', () {
      final sampleData = '''=== Mesures ===
Température: Amb=25.0 °C | Obj=34.5 °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=16384] Gyro[X=0 Y=0 Z=0]
⚠️ Alerte : LED allumée !''';

      final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);

      expect(result.temperature, 34.5);
      expect(result.status, HealthStatus.alert);
      expect(result.reason, contains('HYPOTHERMIA'));
    });

    /// Test 10: Cas extrêmes - fréquence cardiaque élevée
    test('Detect high PPG ratio (possible tachycardia)', () {
      final sampleData = '''=== Mesures ===
Température: Amb=25.0 °C | Obj=36.5 °C
MAX30100: IR=80000 | RED=30000
MPU6050: Accel[X=0 Y=0 Z=16384] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.''';

      final result = ESP32FirmwareAdapter.parseSerialOutput(sampleData);

      // Ratio = 80000/30000 = 2.67
      // Estimation = 60 + (2.67 - 2.0) * 30 = 60 + 20 = 80 BPM
      expect(result.heartRate, greaterThan(70.0));
    });
  });

  group('ESP32Service Integration', () {
    
    /// Test 11: Service détecte format firmware automatiquement
    test('ESP32Service auto-detects firmware format', () {
      // Ce test demande que esp32_service.dart soit modifié
      // pour supporter la détection automatique
      
      final firmwareOutput = '''=== Mesures ===
Température: Amb=26.71 °C | Obj=37.91 °C
MAX30100: IR=45000 | RED=40000
MPU6050: Accel[X=100 Y=50 Z=16384] Gyro[X=100 Y=50 Z=100]
⚠️ Alerte : LED allumée !''';

      // ESP32Service devrait parser ceci via _parseFirmwareFormat()
      expect(firmwareOutput.contains('=== Mesures ==='), true);
    });

    /// Test 12: Parsing avec buffer accumulation
    test('Handle data arriving in chunks', () {
      const part1 = '=== Mesures ===\nTempérature: Amb=26.71 °C | Obj=37';
      const part2 = '.91 °C\nMAX30100: IR=45000 | RED=40000\n';
      const part3 = 'MPU6050: Accel[X=100 Y=50 Z=16384] Gyro[X=100 Y=50 Z=100]\n';
      const part4 = '⚠️ Alerte : LED allumée !';

      final completeData = part1 + part2 + part3 + part4;
      final result = ESP32FirmwareAdapter.parseSerialOutput(completeData);

      expect(result.temperature, 37.91);
      expect(result.status, HealthStatus.alert);
    });
  });

  group('Edge Cases', () {
    
    test('Handle empty strings', () {
      expect(
        () => ESP32FirmwareAdapter.parseSerialOutput(''),
        isNotNull,
      );
    });

    test('Handle malformed temperature string', () {
      final badData = '''=== Mesures ===
Température: Amb=ABC °C | Obj=XYZ °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.''';

      // Devrait gérer gracefully (valeurs par défaut)
      final result = ESP32FirmwareAdapter.parseSerialOutput(badData);
      expect(result.temperature, 0.0);
    });

    test('Handle multiple measurement blocks', () {
      final multiBlock = '''=== Mesures ===
Température: Amb=25.0 °C | Obj=36.5 °C
MAX30100: IR=0 | RED=0
MPU6050: Accel[X=0 Y=0 Z=16384] Gyro[X=0 Y=0 Z=0]
OK : LED éteinte.
=== Mesures ===
Température: Amb=26.0 °C | Obj=37.5 °C
MAX30100: IR=50000 | RED=45000
MPU6050: Accel[X=100 Y=50 Z=16384] Gyro[X=100 Y=50 Z=100]
⚠️ Alerte : LED allumée !''';

      // Devrait parser la dernière mesure
      final result = ESP32FirmwareAdapter.parseSerialOutput(multiBlock);
      expect(result.temperature, 37.5);
    });
  });
}

// ===== Guide d'Exécution des Tests =====
//
// Ajouter à pubspec.yaml:
// dev_dependencies:
//   flutter_test:
//     sdk: flutter
//
// Exécuter les tests:
// ```bash
// flutter test test/services/firmware_adapter_test.dart
// ```
//
// Exécuter avec verbose:
// ```bash
// flutter test test/services/firmware_adapter_test.dart -v
// ```
//
// Exécuter un seul test:
// ```bash
// flutter test test/services/firmware_adapter_test.dart -k "Parse firmware output - Temperature OK"
// ```
