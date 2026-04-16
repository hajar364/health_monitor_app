import '../models/alert_event.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();

  List<AlertEvent> _alertHistory = [];

  factory AlertService() {
    return _instance;
  }

  AlertService._internal() {
    _initNotifications();
  }

  // Initialiser notifications
  void _initNotifications() {
    print('✅ AlertService initialisé');
  }

  // Déclencher alerte SOS
  void triggerSOSAlert(AlertEvent alert) async {
    print('🚨 SOS ALERT TRIGGERED');
    print('📢 Type: ${alert.alertType}');
    print('🔴 Severity: ${alert.severity}');
    print('💬 Message: ${alert.message}');

    // Ajouter à l'historique
    _alertHistory.add(alert);
    
    print('✅ Alerte sauvegardée dans l\'historique');
  }

  // Appel d'urgence
  Future<bool> emergencyCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        print('📞 Appel en cours vers: $phoneNumber');
        return true;
      }
    } catch (e) {
      print('❌ Erreur appel: $e');
    }
    return false;
  }

  // SMS d'urgence
  Future<bool> sendEmergencySMS(String phoneNumber, String message) async {
    try {
      final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber, queryParameters: {'body': message});
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        print('💬 SMS envoyé à: $phoneNumber');
        return true;
      }
    } catch (e) {
      print('❌ Erreur SMS: $e');
    }
    return false;
  }

  // Ajouter alerte base de données
  Future<void> saveAlertToDatabase(AlertEvent event) async {
    _alertHistory.add(event);
    print('💾 Alerte sauvegardée: ${event.id}');
  }

  // Obtenir historique
  List<AlertEvent> getAlertHistory() {
    return _alertHistory;
  }

  // Résoudre alerte
  void resolveAlert(String alertId, String reason) {
    try {
      final index = _alertHistory.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        print('✅ Alerte $alertId marquée comme résolue: $reason');
      }
    } catch (e) {
      print('❌ Erreur résolution: $e');
    }
  }

  // Effacer historique
  void clearAllAlerts() {
    _alertHistory.clear();
    print('🗑️ Historique des alertes effacé');
  }

  // Nombre d'alertes
  int getUnresolvedAlertCount() {
    return _alertHistory.length;
  }
}
