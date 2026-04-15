import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/health_data.dart';

/// Service de gestion des alertes critiques
/// Gère les sons, vibrations, notifications et affichage en cas d'alerte
class AlertService {
  static final AlertService _instance = AlertService._internal();

  factory AlertService() {
    return _instance;
  }

  AlertService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _alertController = StreamController<HealthData>.broadcast();
  
  bool _isMuted = false;
  Map<String, DateTime> _lastAlertTimes = {};
  static const Duration ALERT_DEBOUNCE = Duration(seconds: 5);
  
  // Getters
  Stream<HealthData> get alertStream => _alertController.stream;
  bool get isMuted => _isMuted;

  /// Traiter une nouvelle mesure pour déclencher des alertes si nécessaire
  void processHealthData(HealthData data) {
    if (data.isAbnormal && data.isCritical) {
      // Vérifier debounce
      final alertKey = data.alertType.name;
      final now = DateTime.now();
      final lastAlert = _lastAlertTimes[alertKey];
      
      bool shouldAlert = lastAlert == null || 
                         now.difference(lastAlert) > ALERT_DEBOUNCE;
      
      if (shouldAlert) {
        _lastAlertTimes[alertKey] = now;
        _triggerAlert(data);
      }
    }
  }

  /// Déclencher une alerte
  void _triggerAlert(HealthData data) {
    // Ajouter au stream d'alertes
    _alertController.add(data);
    
    // Jouer le son d'alerte
    _playAlertSound(data.alertType);
    
    print('🚨 ALERTE: ${data.alertDescription}');
    print('   Raison: ${data.reason}');
  }

  /// Jouer un son d'alerte adapté au type d'alerte
  Future<void> _playAlertSound(AlertType alertType) async {
    if (_isMuted) return;

    try {
      // En production, utiliser des vrais fichiers audio
      // Pour la démo, on peut utiliser des tonalités système
      
      switch (alertType) {
        case AlertType.fall:
          // Son d'alerte urgente: 3 bips rapides
          await _playBeeps(3, 100, 100);
          break;
        case AlertType.highFever:
          // Son d'alerte modérée: 2 bips plus longs
          await _playBeeps(2, 200, 150);
          break;
        case AlertType.fever:
          // Son d'alerte légère: 1 bip long
          await _playBeeps(1, 300, 0);
          break;
        case AlertType.hypothermia:
          // Son d'alerte modérée: 2 bips
          await _playBeeps(2, 200, 150);
          break;
        default:
          break;
      }
    } catch (e) {
      print('⚠️ Erreur lecture son: $e');
    }
  }

  /// Jouer une série de bips (simulation)
  Future<void> _playBeeps(int count, int durationMs, int delayMs) async {
    // Note: AudioPlayer nécessite des fichiers audio réels
    // Pour une vraie implémentation en production:
    // 1. Ajouter audioplayers au pubspec.yaml
    // 2. Fournir des fichiers audio pour chaque alerte
    // 3. Utiliser _audioPlayer.play() avec le chemin du fichier
    
    // Pour l'instant, on log juste
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
      print('🔔 BIP ($durationMs ms)');
    }
  }

  /// Activer/Désactiver le mode silencieux
  void setMuted(bool muted) {
    _isMuted = muted;
    print(_isMuted ? '🔇 Alertes en silencieux' : '🔊 Alertes activées');
  }

  /// Réinitialiser les cooldown des alertes
  void resetAlertCooldowns() {
    _lastAlertTimes.clear();
    print('✓ Cooldown des alertes réinitialisé');
  }

  /// Afficher une alerte visuelle (SnackBar)
  static void showAlertSnackBar(BuildContext context, HealthData data) {
    final color = _getAlertColor(data.alertType);
    final icon = _getAlertIcon(data.alertType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.alertDescription,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    data.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Afficher un dialogue d'alerte critique
  static void showCriticalAlertDialog(BuildContext context, HealthData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: Row(
          children: [
            Icon(_getAlertIcon(data.alertType), 
              color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.alertDescription,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ ALERTE CRITIQUE ⚠️',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data.reason,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildHealthMetrics(data),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              // Implémenter: appeler urgences, notifier soignant, etc.
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('🆘 Appeler à l\'aide'),
          ),
        ],
      ),
    );
  }

  /// Construire le widget des métriques de santé
  static Widget _buildHealthMetrics(HealthData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildMetricRow('Température', '${data.temperature.toStringAsFixed(1)}°C', 
            _getTemperatureColor(data.temperature)),
          _buildMetricRow('FC', '${data.heartRate.toStringAsFixed(0)} BPM',
            _getHeartRateColor(data.heartRate)),
          _buildMetricRow('Accélération', 
            '${data.accelMagnitude.toStringAsFixed(2)} g',
            _getAccelColor(data.accelMagnitude)),
        ],
      ),
    );
  }

  static Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Helpers pour les couleurs et icônes
  static Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.fall:
        return Colors.red.shade700;
      case AlertType.highFever:
        return Colors.red.shade600;
      case AlertType.fever:
        return Colors.orange.shade600;
      case AlertType.hypothermia:
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  static IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.fall:
        return Icons.warning;
      case AlertType.highFever:
        return Icons.local_fire_department;
      case AlertType.fever:
        return Icons.thermostat;
      case AlertType.hypothermia:
        return Icons.ac_unit;
      default:
        return Icons.info;
    }
  }

  static Color _getTemperatureColor(double temp) {
    if (temp < 35) return Colors.blue;
    if (temp <= 37.5) return Colors.green;
    if (temp < 39.5) return Colors.orange;
    return Colors.red;
  }

  static Color _getHeartRateColor(double hr) {
    if (hr < 60) return Colors.blue;
    if (hr <= 100) return Colors.green;
    if (hr < 120) return Colors.orange;
    return Colors.red;
  }

  static Color _getAccelColor(double accel) {
    if (accel < 1.0) return Colors.green;
    if (accel < 2.0) return Colors.orange;
    return Colors.red;
  }

  /// Fermer et nettoyer les ressources
  void dispose() {
    _audioPlayer.dispose();
    _alertController.close();
  }
}
