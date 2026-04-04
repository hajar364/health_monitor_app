import 'package:health_monitor_app/models/health_data.dart';
import 'dart:convert';

/// Adaptateur pour le firmware ESP32 avec MAX30100, MLX90614, MPU6050
class ESP32FirmwareAdapter {
  
  /// Parse la sortie Serial du firmware et retourne HealthData
  /// Format attendu:
  /// === Mesures ===
  /// Température: Amb=26.71 °C | Obj=27.91 °C
  /// MAX30100: IR=0 | RED=0
  /// MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
  /// ⚠️ Alerte : LED allumée ! / OK : LED éteinte.
  
  static HealthData parseSerialOutput(String serialData) {
    try {
      final lines = serialData.split('\n');
      
      double temperature = 0.0;
      double ambientTemp = 0.0;
      int irValue = 0;
      int redValue = 0;
      int accelX = 0, accelY = 0, accelZ = 0;
      int gyroX = 0, gyroY = 0, gyroZ = 0;
      bool alerte = false;
      
      // Parse chaque ligne
      for (var line in lines) {
        line = line.trim();
        
        // Parse Température: Amb=26.71 °C | Obj=27.91 °C
        if (line.contains('Température:')) {
          final ambMatch = RegExp(r'Amb=([\d.]+)').firstMatch(line);
          final objMatch = RegExp(r'Obj=([\d.]+)').firstMatch(line);
          
          if (ambMatch != null) {
            ambientTemp = double.parse(ambMatch.group(1) ?? '0');
            temperature = ambientTemp;
          }
          if (objMatch != null) {
            temperature = double.parse(objMatch.group(1) ?? '0');
          }
        }
        
        // Parse MAX30100: IR=0 | RED=0
        if (line.contains('MAX30100:')) {
          final irMatch = RegExp(r'IR=(\d+)').firstMatch(line);
          final redMatch = RegExp(r'RED=(\d+)').firstMatch(line);
          
          if (irMatch != null) irValue = int.parse(irMatch.group(1) ?? '0');
          if (redMatch != null) redValue = int.parse(redMatch.group(1) ?? '0');
        }
        
        // Parse MPU6050: Accel[X=0 Y=0 Z=0] Gyro[X=0 Y=0 Z=0]
        if (line.contains('MPU6050:')) {
          final accelXMatch = RegExp(r'Accel.*X=(-?\d+)').firstMatch(line);
          final accelYMatch = RegExp(r'Accel.*Y=(-?\d+)').firstMatch(line);
          final accelZMatch = RegExp(r'Accel.*Z=(-?\d+)').firstMatch(line);
          final gyroXMatch = RegExp(r'Gyro.*X=(-?\d+)').firstMatch(line);
          final gyroYMatch = RegExp(r'Gyro.*Y=(-?\d+)').firstMatch(line);
          final gyroZMatch = RegExp(r'Gyro.*Z=(-?\d+)').firstMatch(line);
          
          if (accelXMatch != null) accelX = int.parse(accelXMatch.group(1) ?? '0');
          if (accelYMatch != null) accelY = int.parse(accelYMatch.group(1) ?? '0');
          if (accelZMatch != null) accelZ = int.parse(accelZMatch.group(1) ?? '0');
          if (gyroXMatch != null) gyroX = int.parse(gyroXMatch.group(1) ?? '0');
          if (gyroYMatch != null) gyroY = int.parse(gyroYMatch.group(1) ?? '0');
          if (gyroZMatch != null) gyroZ = int.parse(gyroZMatch.group(1) ?? '0');
        }
        
        // Détection alerte
        if (line.contains('⚠️ Alerte')) {
          alerte = true;
        }
      }
      
      // Convertir les valeurs brutes en données utiles
      final heartRate = _estimateHeartRateFromPPG(irValue, redValue);
      final accelData = _convertAccelToG(accelX, accelY, accelZ);
      final status = alerte ? HealthStatus.alert : HealthStatus.normal;
      final reason = _generateReason(temperature, irValue, accelX);
      
      return HealthData(
        heartRate: heartRate,
        temperature: temperature,
        humidity: 0.0,  // MLX90614 ne fournit pas d'humidité
        accelX: accelData['x']!,
        accelY: accelData['y']!,
        accelZ: accelData['z']!,
        timestamp: DateTime.now(),
        status: status,
        reason: reason,
      );
      
    } catch (e) {
      print('❌ Erreur parsing firmware: $e');
      return HealthData.empty();
    }
  }

  /// Estime la fréquence cardiaque à partir des valeurs IR/RED du MAX30100
  /// Basé sur le ratio IR/RED et la détection du capteur
  static double _estimateHeartRateFromPPG(int irValue, int redValue) {
    // Si aucun doigt détecté (valeurs très basses)
    if (irValue < 10000 || redValue < 10000) {
      return 0.0;  // Pas de mesure
    }
    
    // Ratio IR/RED pour estimation simple
    final ratio = irValue / (redValue + 1);  // +1 pour éviter division par 0
    
    // Formule empirique (à calibrer selon capteur)
    // Normalement, le MAX30100 fournit directement FC via SpO2
    // Ici on estime à partir du ratio
    double estimatedHR = 60 + (ratio - 2.0) * 30;  // Plage estimée: 60-120 BPM
    
    // Clamp vers plage raisonnable
    return estimatedHR.clamp(40.0, 200.0);
  }

  /// Convertit les valeurs accélération brutes (int16) en G (gravité)
  /// MPU6050 en mode ±2g: 16384 unités = 1G
  static Map<String, double> _convertAccelToG(int ax, int ay, int az) {
    const sensitivity = 16384.0;  // Sensibilité en mode ±2g
    
    return {
      'x': ax / sensitivity,
      'y': ay / sensitivity,
      'z': az / sensitivity,
    };
  }

  /// Génère une explication textuelle des conditions de mesure
  static String _generateReason(double temperature, int irValue, int accelX) {
    List<String> reasons = [];
    
    // Conditions température
    if (temperature > 38.0) {
      reasons.add('FEVER (${temperature.toStringAsFixed(1)}°C)');
    } else if (temperature < 35.0) {
      reasons.add('HYPOTHERMIA (${temperature.toStringAsFixed(1)}°C)');
    }
    
    // Détection doigt
    if (irValue < 10000) {
      reasons.add('NO_FINGER_DETECTED');
    }
    
    // Détection mouvement fort
    if (accelX.abs() > 20000) {
      reasons.add('STRONG_MOTION');
    }
    
    return reasons.isNotEmpty ? reasons.join('; ') : 'NORMAL';
  }

  /// Convertit HealthData en JSON au format compatible avec le firmware
  static Map<String, dynamic> toFirmwareJSON(HealthData data) {
    return {
      'heartRate': data.heartRate.toStringAsFixed(1),
      'temperature': data.temperature.toStringAsFixed(2),
      'humidity': data.humidity.toStringAsFixed(1),
      'accelX': data.accelX.toStringAsFixed(2),
      'accelY': data.accelY.toStringAsFixed(2),
      'accelZ': data.accelZ.toStringAsFixed(2),
      'status': data.status.name,
      'reason': data.reason,
      'timestamp': data.timestamp.toIso8601String(),
    };
  }
}

extension on HealthData {
  static HealthData empty() {
    return HealthData(
      heartRate: 0,
      temperature: 0,
      humidity: 0,
      accelX: 0,
      accelY: 0,
      accelZ: 0,
      timestamp: DateTime.now(),
      status: HealthStatus.normal,
      reason: 'No data',
    );
  }
}
