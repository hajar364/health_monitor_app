import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/threshold_settings.dart';
import '../services/fall_detection_service.dart';
import '../providers/esp32_ip_provider.dart';
import 'esp32_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThresholdSettings settings;
  late FallDetectionService fallService;
  late TextEditingController phoneCtrl;

  @override
  void initState() {
    super.initState();
    settings = ThresholdSettings();
    fallService = FallDetectionService(thresholds: settings);
    phoneCtrl = TextEditingController(text: settings.emergencyNumber ?? '112');
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Accéder à ESP32SettingsNotifier via Provider
    final esp32Settings = context.watch<ESP32SettingsNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CONNEXION ESP32 ===
            _buildSection(
              title: '📡 Connexion ESP32',
              icon: Icons.wifi,
              children: [
                // Afficher les paramètres actuels
                if (esp32Settings.isLoading)
                  const CircularProgressIndicator()
                else if (esp32Settings.error != null)
                  Text('Erreur: ${esp32Settings.error}')
                else
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.router),
                        title: const Text('Adresse IP'),
                        subtitle: Text(esp32Settings.settings.ipAddress),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ESP32SetupScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings_ethernet),
                        title: const Text('Port'),
                        subtitle: Text(esp32Settings.settings.port.toString()),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ESP32SetupScreen(),
                            ),
                          );
                        },
                      ),
                      if (esp32Settings.settings.lastConnectedAt != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Dernière connexion: ${esp32Settings.settings.lastConnectedAt}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ESP32SetupScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Modifier configuration'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // === DÉTECTION DE CHUTE ===
            _buildSection(
              title: '🚨 Détection de Chute',
              icon: Icons.warning,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sensibilité'),
                        Text(
                          '${settings.fallDetectionSensitivity.toStringAsFixed(2)}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.fallDetectionSensitivity,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      label: settings.fallDetectionSensitivity
                          .toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          settings = settings.copyWith(
                            fallDetectionSensitivity: value,
                          );
                        });
                      },
                    ),
                    Text(
                      'Moins sensible ← → Plus sensible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Seuil d\'accélération'),
                        Text(
                          '${settings.accelerationThreshold.toStringAsFixed(1)}g',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.accelerationThreshold,
                      min: 1.0,
                      max: 3.0,
                      divisions: 10,
                      label: settings.accelerationThreshold.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          settings = settings.copyWith(
                            accelerationThreshold: value,
                          );
                        });
                      },
                    ),
                    Text(
                      'Impact pour déclencher une détection',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Délai de confirmation'),
                        Text(
                          '${settings.fallConfirmationDelay}ms',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.fallConfirmationDelay.toDouble(),
                      min: 100,
                      max: 1000,
                      divisions: 9,
                      label: settings.fallConfirmationDelay.toString(),
                      onChanged: (value) {
                        setState(() {
                          settings = settings.copyWith(
                            fallConfirmationDelay: value.toInt(),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === ALERTES TEMPÉRATURE ===
            _buildSection(
              title: '🌡️ Alertes Température',
              icon: Icons.thermostat,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🔴 Température Élevée'),
                        Text(
                          '${settings.temperatureHighAlert.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.temperatureHighAlert,
                      min: 37.0,
                      max: 42.0,
                      divisions: 10,
                      label: settings.temperatureHighAlert.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          settings = settings.copyWith(
                            temperatureHighAlert: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🔵 Température Basse'),
                        Text(
                          '${settings.temperatureLowAlert.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.temperatureLowAlert,
                      min: 32.0,
                      max: 36.0,
                      divisions: 8,
                      label: settings.temperatureLowAlert.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          settings = settings.copyWith(
                            temperatureLowAlert: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === URGENCE ===
            _buildSection(
              title: '🆘 Paramètres d\'Urgence',
              icon: Icons.phone_in_talk,
              children: [
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Numéro d\'urgence',
                    hintText: '15 (SAMU)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Délai avant appel auto'),
                        Text(
                          '${(settings.sosActivationTime / 1000).toStringAsFixed(0)}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.sosActivationTime.toDouble(),
                      min: 30000,
                      max: 300000,
                      divisions: 9,
                      label: (settings.sosActivationTime / 1000).toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          settings = settings.copyWith(
                            sosActivationTime: value.toInt(),
                          );
                        });
                      },
                    ),
                    Text(
                      'Temps pour annuler l\'alerte avant appel automatique',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Activer appels automatiques'),
                  value: settings.enableAutoCall,
                  onChanged: (value) {
                    setState(() {
                      settings = settings.copyWith(enableAutoCall: value ?? true);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === BOUTONS ACTIONS ===
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        settings = ThresholdSettings();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Seuils réinitialisés')),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Par défaut'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Paramètres sauvegardés')),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}
