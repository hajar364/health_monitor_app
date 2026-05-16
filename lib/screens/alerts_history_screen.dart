import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/alert_service.dart';
import '../models/alert_event.dart';
import '../widgets/app_logo.dart';

class AlertsHistoryScreen extends StatelessWidget {
  const AlertsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertService = context.watch<AlertService>();
    final alerts = alertService.alertHistory.reversed.toList();
    final unresolved = alertService.unresolvedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: AppLogo(size: 36),
        ),
        title: const Text(
          'Historique des Alertes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: 'Vider',
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de résumé
          if (alerts.isNotEmpty)
            Container(
              color: Colors.blue.shade700,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _summaryChip(
                    '${alerts.length}',
                    'Total',
                    Colors.white,
                    Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  _summaryChip(
                    '$unresolved',
                    'Non résolues',
                    Colors.red.shade200,
                    Colors.red.shade900.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                  _summaryChip(
                    '${alerts.length - unresolved}',
                    'Résolues',
                    Colors.green.shade200,
                    Colors.green.shade900.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          // Liste
          Expanded(
            child: alerts.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) =>
                        _AlertCard(alert: alerts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(
      String count, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(count,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: textColor.withValues(alpha: 0.85), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green.shade400),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune alerte',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Tout va bien !',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider l\'historique ?'),
        content: const Text('Toutes les alertes seront supprimées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              context.read<AlertService>().clearAllAlerts();
              Navigator.pop(ctx);
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Carte alerte ────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AlertEvent alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    final ts = alert.timestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Row(
            children: [
              // Icône sévérité
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_severityIcon(alert.severity), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Titre + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.getAlertTypeLabel(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$timeStr — $dateStr',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Badge sévérité
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alert.severity,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              // Statut résolu
              if (alert.isResolved)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Détails
            _detailBlock('Message', alert.message),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _detailBlock('Type', alert.alertType)),
                const SizedBox(width: 8),
                Expanded(
                    child: _detailBlock('Sévérité', alert.severity,
                        valueColor: color)),
              ],
            ),
            if (alert.patient != null) ...[
              const SizedBox(height: 8),
              _detailBlock('Patient', alert.patient!.getDisplayName()),
            ],
            if (alert.isResolved) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _detailBlock(
                          'Résolution', alert.resolution ?? '')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _detailBlock(
                      'Résolu à',
                      alert.resolvedAt != null
                          ? '${alert.resolvedAt!.hour.toString().padLeft(2, '0')}:${alert.resolvedAt!.minute.toString().padLeft(2, '0')}'
                          : '—',
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context
                            .read<AlertService>()
                            .resolveAlert(alert.id, 'Fausse alerte');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Alerte annulée'),
                              duration: Duration(seconds: 2)),
                        );
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Fausse alerte',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<AlertService>()
                            .resolveAlert(alert.id, 'Traitée');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Alerte résolue'),
                              duration: Duration(seconds: 2)),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Résolue',
                          style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailBlock(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade700;
      case 'MEDIUM':
        return Colors.amber.shade700;
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Icons.emergency;
      case 'HIGH':
        return Icons.warning_amber_rounded;
      case 'MEDIUM':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }
}
