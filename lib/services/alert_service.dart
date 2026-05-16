import 'package:flutter/foundation.dart';
import '../models/alert_event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class AlertService extends ChangeNotifier {
  static final AlertService _instance = AlertService._internal();

  final List<AlertEvent> _alertHistory = [];

  factory AlertService() => _instance;

  AlertService._internal();

  List<AlertEvent> get alertHistory => List.unmodifiable(_alertHistory);

  int get unresolvedCount => _alertHistory.where((a) => !a.isResolved).length;

  void triggerSOSAlert(AlertEvent alert) {
    _alertHistory.add(alert);
    notifyListeners();
    debugPrint('🚨 Alerte SOS: ${alert.alertType} — ${alert.severity}');
  }

  /// Appel direct sans interaction utilisateur (requiert CALL_PHONE)
  Future<bool> emergencyCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return false;

    // Demander la permission si pas encore accordée
    final status = await Permission.phone.request();

    if (status.isGranted) {
      // Appel direct — l'app lance l'appel sans que l'utilisateur touche quoi que ce soit
      final result = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
      debugPrint('📞 Appel direct vers $phoneNumber: $result');
      return result ?? false;
    } else {
      // Permission refusée → ouvrir le composeur comme fallback
      debugPrint('⚠️ Permission CALL_PHONE refusée, ouverture composeur');
      return _openDialer(phoneNumber);
    }
  }

  /// Ouvre le composeur (fallback si permission refusée)
  Future<bool> _openDialer(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  void resolveAlert(String alertId, String reason) {
    final index = _alertHistory.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alertHistory[index] = _alertHistory[index].copyWith(
        isResolved: true,
        resolution: reason,
        resolvedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void clearAllAlerts() {
    _alertHistory.clear();
    notifyListeners();
  }

  // Compatibilité avec l'ancien code
  List<AlertEvent> getAlertHistory() => _alertHistory;
  int getUnresolvedAlertCount() => unresolvedCount;
}
