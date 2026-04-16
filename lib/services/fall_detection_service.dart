import '../models/fall_detection_data.dart';
import '../models/threshold_settings.dart';
import 'dart:math';

class FallDetectionService {
  final ThresholdSettings thresholds;
  late List<IMUSensorData> _sensorBuffer;
  int bufferSize = 50; // ~500ms de données à 100Hz

  FallDetectionService({required this.thresholds}) {
    _sensorBuffer = [];
  }

  // Analyser buffer de données capteurs
  FallEvent? analyzeSensorData(List<IMUSensorData> dataBuffer) {
    if (dataBuffer.isEmpty) return null;

    final startIdx = (dataBuffer.length > bufferSize) ? dataBuffer.length - bufferSize : 0;
    _sensorBuffer = dataBuffer.sublist(startIdx);


    // Algorithme de détection de chute (3 étapes)
    
    // 1. Détection pic d'accélération (chute)
    final peakAccel = _detectAccelerationPeak();
    if (peakAccel == null) return null;

    // 2. Détection changement rapide d'orientation (gyroscope)
    final rapidRotation = _detectRapidRotation();

    // 3. Confirmation position au sol (accél stabilisée bas)
    final isOnGround = _confirmGroundPosition();

    // Calcul confiance (0-100%)
    double confidence = 0;
    if (peakAccel) confidence += 40;
    if (rapidRotation) confidence += 35;
    if (isOnGround) confidence += 25;

    // Seuil minimum de confiance
    if (confidence < 60) return null;

    // Détermine sévérité
    String severity = 'LOW';
    if (confidence > 85) {
      severity = 'HIGH';
    } else if (confidence > 70) {
      severity = 'MEDIUM';
    }

    return FallEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      severity: severity,
      confidence: confidence,
      reason: _getDetectionReason(peakAccel, rapidRotation, isOnGround),
      isConfirmed: false,
      sensorData: _sensorBuffer.last,
    );
  }

  // Détection 1: Pic d'accélération
  bool _detectAccelerationPeak() {
    if (_sensorBuffer.length < 5) return false;

    final threshold = 9.8 * thresholds.accelerationThreshold;
    
    // Cherche un point où magnitude > seuil
    for (int i = 0; i < _sensorBuffer.length - 1; i++) {
      final mag = sqrt(
        _sensorBuffer[i].accelX * _sensorBuffer[i].accelX +
        _sensorBuffer[i].accelY * _sensorBuffer[i].accelY +
        _sensorBuffer[i].accelZ * _sensorBuffer[i].accelZ
      );

      if (mag > threshold) {
        // Vérifie qu'il y a baisse après (phase 2 = libre chute)
        if (i + 1 < _sensorBuffer.length) {
          final magNext = sqrt(
            _sensorBuffer[i + 1].accelX * _sensorBuffer[i + 1].accelX +
            _sensorBuffer[i + 1].accelY * _sensorBuffer[i + 1].accelY +
            _sensorBuffer[i + 1].accelZ * _sensorBuffer[i + 1].accelZ
          );
          if (magNext < threshold * 0.8) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Détection 2: Rotation rapide (chute = rotation rapide)
  bool _detectRapidRotation() {
    if (_sensorBuffer.length < 3) return false;

    const gyroThreshold = 100.0; // °/s
    for (final data in _sensorBuffer) {
      final gyroMag = sqrt(
        data.gyroX * data.gyroX +
        data.gyroY * data.gyroY +
        data.gyroZ * data.gyroZ
      );
      if (gyroMag > gyroThreshold) {
        return true;
      }
    }
    return false;
  }

  // Détection 3: Confirmation au sol
  bool _confirmGroundPosition() {
    if (_sensorBuffer.isEmpty) return false;

    // Après chute, accélération devrait être ~9.8 (repos au sol)
    // avec le Z négatif (gravité vers bas)
    final lastData = _sensorBuffer.last;
    final mag = sqrt(
      lastData.accelX * lastData.accelX +
      lastData.accelY * lastData.accelY +
      lastData.accelZ * lastData.accelZ
    );

    // Si magnitude est proche de 9.8 ± 1, c'est au repos
    return (mag > 8.5 && mag < 10.8);
  }

  String _getDetectionReason(
    bool peakAccel,
    bool rapidRotation,
    bool isOnGround,
  ) {
    final reasons = <String>[];
    if (peakAccel) reasons.add('pic accélération');
    if (rapidRotation) reasons.add('rotation rapide');
    if (isOnGround) reasons.add('au sol');
    return reasons.join(' + ');
  }

  // Confirmation manuelle chute
  void confirmFall(FallEvent fall) {
    print('✅ Chute confirmée: ${fall.id}');
  }

  // Annulation fausse alerte
  void cancelFall(FallEvent fall) {
    print('❌ Alerte annulée: ${fall.id}');
  }

  // Mise à jour seuils
  void updateThresholds(ThresholdSettings newThresholds) {
    // thresholds = newThresholds;
    print('⚙️ Seuils mis à jour');
  }
}
