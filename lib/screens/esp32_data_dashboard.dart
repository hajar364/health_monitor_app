import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/esp32_ip_provider.dart';
import '../models/fall_detection_data.dart';

class ESP32DataDashboard extends ConsumerWidget {
  const ESP32DataDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Afficher l'état de connexion
    final connectionStatus = ref.watch(esp32ConnectionStatusProvider);

    // Afficher les paramètres ESP32
    final esp32Settings = ref.watch(esp32SettingsProvider);

    // Afficher les données des capteurs en temps réel
    final sensorStream = ref.watch(esp32SensorStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Données ESP32'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === SECTION CONNEXION ===
            _buildConnectionStatus(context, connectionStatus, esp32Settings),
            const SizedBox(height: 24),

            // === SECTION CAPTEURS ===
            Text(
              '📡 Données des capteurs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            // Afficher les données en temps réel
            sensorStream.when(
              data: (sensorData) => _buildSensorDataCards(sensorData),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '❌ Erreur de connexion',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(
    BuildContext context,
    AsyncValue<bool> connectionStatus,
    AsyncValue<ESP32Settings> esp32Settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'État de connexion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              connectionStatus.when(
                data: (isConnected) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.check_circle : Icons.warning,
                        color: isConnected
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Connecté' : 'Déconnecté',
                        style: TextStyle(
                          color: isConnected
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                ),
                error: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Erreur',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          esp32Settings.when(
            data: (settings) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IP: ${settings.ipAddress}:${settings.port}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Device: ${settings.deviceName}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            loading: () => const Text('Chargement...'),
            error: (e, _) => Text('Erreur: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataCards(IMUSensorData sensorData) {
    return Column(
      children: [
        // === Accélération ===
        _buildSensorCard(
          title: '📍 Accélération',
          icon: Icons.trending_down,
          values: [
            ('X', sensorData.accelX),
            ('Y', sensorData.accelY),
            ('Z', sensorData.accelZ),
          ],
          unit: 'G',
        ),
        const SizedBox(height: 12),

        // === Rotation (Gyroscope) ===
        _buildSensorCard(
          title: '🔄 Rotation',
          icon: Icons.rotate_90_degrees_ccw,
          values: [
            ('X', sensorData.gyroX),
            ('Y', sensorData.gyroY),
            ('Z', sensorData.gyroZ),
          ],
          unit: '°/s',
        ),
        const SizedBox(height: 12),

        // === Température ===
        _buildSensorCard(
          title: '🌡️ Température',
          icon: Icons.thermostat,
          values: [
            ('Tobj', sensorData.temperature),
          ],
          unit: '°C',
        ),
        const SizedBox(height: 12),

        // === Magnitude ===
        _buildSensorCard(
          title: '📏 Magnitude',
          icon: Icons.speed,
          values: [
            ('Accel', sensorData.magnitude),
          ],
          unit: 'G',
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required String title,
    required IconData icon,
    required List<(String, double)> values,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: values
                .map(
                  (e) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.$1,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e.$2.toStringAsFixed(2)} $unit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
