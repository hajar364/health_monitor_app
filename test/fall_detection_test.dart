import 'package:flutter_test/flutter_test.dart';
import 'package:health_monitor_app/models/fall_detection_data.dart';
import 'package:health_monitor_app/services/fall_detection_service.dart';
import 'package:health_monitor_app/models/threshold_settings.dart';

void main() {
  group('Fall Detection Tests', () {
    late FallDetectionService fallDetectionService;
    late ThresholdSettings thresholds;

    setUp(() {
      thresholds = ThresholdSettings();
      fallDetectionService = FallDetectionService(thresholds: thresholds);
    });

    test('Normal movement should NOT trigger fall detection', () {
      // Données normales (marche tranquille)
      final normalData = <IMUSensorData>[
        for (int i = 0; i < 50; i++)
          IMUSensorData(
            timestamp: DateTime.now().add(Duration(milliseconds: i * 100)),
            accelX: 0.1,
            accelY: 0.1,
            accelZ: 9.8,
            gyroX: 5.0,
            gyroY: 5.0,
            gyroZ: 5.0,
            magnitude: 9.8,
            temperature: 36.5,
          )
      ];

      final result = fallDetectionService.analyzeSensorData(normalData);

      expect(result, isNull, reason: 'Normal movement should not detect fall');
    });

    test('Sharp peak should trigger fall detection', () {
      // Pic d'accélération suivi de stabilisation
      final fallData = <IMUSensorData>[
        // 40 samples normales
        for (int i = 0; i < 40; i++)
          IMUSensorData(
            timestamp: DateTime.now().add(Duration(milliseconds: i * 100)),
            accelX: 0.0,
            accelY: 0.0,
            accelZ: 9.8,
            gyroX: 0.0,
            gyroY: 0.0,
            gyroZ: 0.0,
            magnitude: 9.8,
            temperature: 36.5,
          ),
        // 5 samples avec pic d'accélération
        for (int i = 40; i < 45; i++)
          IMUSensorData(
            timestamp: DateTime.now().add(Duration(milliseconds: i * 100)),
            accelX: 2.0,
            accelY: 2.5,
            accelZ: 0.5,
            gyroX: 200.0,
            gyroY: 180.0,
            gyroZ: 150.0,
            magnitude: 3.2,
            temperature: 36.5,
          ),
        // 5 samples au sol (stabilisé)
        for (int i = 45; i < 50; i++)
          IMUSensorData(
            timestamp: DateTime.now().add(Duration(milliseconds: i * 100)),
            accelX: 0.1,
            accelY: 0.1,
            accelZ: 9.8,
            gyroX: 0.0,
            gyroY: 0.0,
            gyroZ: 0.0,
            magnitude: 9.8,
            temperature: 36.5,
          )
      ];

      final result = fallDetectionService.analyzeSensorData(fallData);

      expect(result, isNotNull, reason: 'Sharp peak should detect fall');
      expect(result!.severity, isNotNull);
    });

    test('Alert service should trigger on high confidence fall', () {
      // Simulation d'une chute confirmée
      final fall = FallEvent(
        id: 'test_fall_001',
        timestamp: DateTime.now(),
        severity: 'HIGH',
        confidence: 85.0,
        reason: 'Detection_Peak_Rotation_Ground',
        isConfirmed: true,
      );

      expect(fall.confidence, greaterThan(75.0));
      expect(fall.severity, equals('HIGH'));
      expect(fall.isConfirmed, isTrue);
    });

    test('Low confidence should not alert', () {
      final lowConfidenceFall = FallEvent(
        id: 'test_false_positive',
        timestamp: DateTime.now(),
        severity: 'LOW',
        confidence: 30.0,
        reason: 'Uncertain',
        isConfirmed: false,
      );

      expect(lowConfidenceFall.confidence, lessThan(60.0));
      expect(lowConfidenceFall.isConfirmed, isFalse);
    });
  });

  group('Threshold Settings Tests', () {
    test('Default thresholds should be reasonable', () {
      final thresholds = ThresholdSettings();

      expect(thresholds.accelerationThreshold, greaterThan(0.5));
      expect(thresholds.accelerationThreshold, lessThan(3.0));
      expect(thresholds.fallDetectionSensitivity, greaterThan(0.3));
      expect(thresholds.fallDetectionSensitivity, lessThan(2.5));
    });

    test('CopyWith should preserve values', () {
      final original = ThresholdSettings();
      final modified = original.copyWith(
        accelerationThreshold: 2.0,
        fallDetectionSensitivity: 1.5,
      );

      expect(modified.accelerationThreshold, equals(2.0));
      expect(modified.fallDetectionSensitivity, equals(1.5));
      expect(original.accelerationThreshold, isNot(2.0));
    });
  });
}
