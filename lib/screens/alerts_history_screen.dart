import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../models/alert_event.dart';

class AlertsHistoryScreen extends StatefulWidget {
  const AlertsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends State<AlertsHistoryScreen> {
  late AlertService alertService;
  List<AlertEvent> alerts = [];

  @override
  void initState() {
    super.initState();
    alertService = AlertService();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final loaded = await alertService.getAlertHistory();
    setState(() {
      alerts = loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Historique des Alertes'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Vider l\'historique?'),
                  content: const Text('Tous les alertes seront supprimées.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        alertService.clearAllAlerts();
                        _loadAlerts();
                        Navigator.pop(context);
                      },
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pas d\'alerte enregistrée',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('Tout va bien! ✅'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: alert.isResolved ? 1 : 4,
                  color: alert.isResolved
                      ? Colors.grey.shade100
                      : alert.severity == 'CRITICAL'
                          ? Colors.red.shade50
                          : alert.severity == 'HIGH'
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Text(
                          alert.getSeverityIcon(),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.getAlertTypeLabel(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')} - ${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (alert.isResolved)
                          const Chip(
                            label: Text('Résolu'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Message', alert.message),
                            const SizedBox(height: 12),
                            _buildDetailRow('Sévérité', alert.severity),
                            const SizedBox(height: 12),
                            _buildDetailRow('Type', alert.alertType),
                            if (alert.patient != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow('Patient', alert.patient!.getDisplayName()),
                            ],
                            if (alert.isResolved) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow('Résolution', alert.resolution ?? ''),
                              _buildDetailRow(
                                'Résolu à',
                                '${alert.resolvedAt?.hour}:${alert.resolvedAt?.minute.toString().padLeft(2, '0')}',
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      alertService.resolveAlert(alert.id, 'Fausse alerte');
                                      _loadAlerts();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Alerte annulée')),
                                      );
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text('Fausse alerte'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      alertService.resolveAlert(alert.id, 'Traitée');
                                      _loadAlerts();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Alerte résolue')),
                                      );
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text('Résolue'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
