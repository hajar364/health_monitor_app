import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/threshold_settings.dart';
import '../services/fall_detection_service.dart';
import '../providers/esp32_ip_provider.dart';
import 'esp32_setup_screen.dart';
import '../widgets/app_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThresholdSettings settings;
  late FallDetectionService fallService;
  late TextEditingController phoneCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    settings = ThresholdSettings();
    fallService = FallDetectionService(thresholds: settings);
    phoneCtrl = TextEditingController(text: '0617951701');
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  void _initFromLoaded(ThresholdSettings loaded) {
    settings = loaded;
    phoneCtrl.text = loaded.sosPhoneNumber.isEmpty ? '0617951701' : loaded.sosPhoneNumber;
    _initialized = true;
  }

  Future<void> _save() async {
    final toSave = settings.copyWith(sosPhoneNumber: phoneCtrl.text);
    await context.read<ThresholdSettingsNotifier>().save(toSave);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Paramètres sauvegardés')),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final defaults = ThresholdSettings();
    await context.read<ThresholdSettingsNotifier>().save(defaults);
    if (mounted) {
      setState(() {
        settings = defaults;
        phoneCtrl.text = '0617951701';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Seuils réinitialisés')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esp32Settings = context.watch<ESP32SettingsNotifier>();
    final thresholdNotifier = context.watch<ThresholdSettingsNotifier>();

    // Initialiser le brouillon local dès que SharedPreferences est chargé
    if (!_initialized && thresholdNotifier.isLoaded) {
      _initFromLoaded(thresholdNotifier.settings);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: AppLogo(size: 36),
        ),
        title: const Text('Paramètres',
            style: TextStyle(color: Colors.white)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: !thresholdNotifier.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === CONNEXION ESP32 ===
                  _buildSection(
                    title: '📡 Connexion ESP32',
                    icon: Icons.wifi,
                    children: [
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ESP32SetupScreen(),
                                ),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.settings_ethernet),
                              title: const Text('Port'),
                              subtitle: Text(esp32Settings.settings.port.toString()),
                              trailing: const Icon(Icons.edit),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ESP32SetupScreen(),
                                ),
                              ),
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
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ESP32SetupScreen(),
                                  ),
                                ),
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
                      _buildSliderRow(
                        label: 'Sensibilité',
                        valueText: '${settings.fallDetectionSensitivity.toStringAsFixed(2)}x',
                        value: settings.fallDetectionSensitivity,
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        onChanged: (v) => setState(() {
                          settings = settings.copyWith(fallDetectionSensitivity: v);
                        }),
                        hint: 'Moins sensible ← → Plus sensible',
                      ),
                      const SizedBox(height: 16),
                      _buildSliderRow(
                        label: 'Seuil d\'accélération',
                        valueText: '${settings.accelerationThreshold.toStringAsFixed(1)}g',
                        value: settings.accelerationThreshold,
                        min: 1.0,
                        max: 3.0,
                        divisions: 10,
                        onChanged: (v) => setState(() {
                          settings = settings.copyWith(accelerationThreshold: v);
                        }),
                        hint: 'Impact pour déclencher une détection',
                      ),
                      const SizedBox(height: 16),
                      _buildSliderRow(
                        label: 'Délai de confirmation',
                        valueText: '${settings.fallConfirmationDelay}ms',
                        value: settings.fallConfirmationDelay.toDouble(),
                        min: 100,
                        max: 1000,
                        divisions: 9,
                        onChanged: (v) => setState(() {
                          settings = settings.copyWith(fallConfirmationDelay: v.toInt());
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // === ALERTES TEMPÉRATURE ===
                  _buildSection(
                    title: '🌡️ Alertes Température',
                    icon: Icons.thermostat,
                    children: [
                      _buildSliderRow(
                        label: '🔴 Température Élevée',
                        valueText: '${settings.temperatureHighAlert.toStringAsFixed(1)}°C',
                        value: settings.temperatureHighAlert,
                        min: 37.0,
                        max: 42.0,
                        divisions: 10,
                        onChanged: (v) => setState(() {
                          settings = settings.copyWith(temperatureHighAlert: v);
                        }),
                      ),
                      const SizedBox(height: 16),
                      _buildSliderRow(
                        label: '🔵 Température Basse',
                        valueText: '${settings.temperatureLowAlert.toStringAsFixed(1)}°C',
                        value: settings.temperatureLowAlert,
                        min: 32.0,
                        max: 36.0,
                        divisions: 8,
                        onChanged: (v) => setState(() {
                          settings = settings.copyWith(temperatureLowAlert: v);
                        }),
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
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numéro d\'urgence',
                          hintText: '15 (SAMU)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSliderRow(
                        label: 'Délai avant appel auto',
                        valueText: '${(settings.sosActivationTime / 1000).toStringAsFixed(0)}s',
                        value: settings.sosActivationTime.toDouble(),
                        min: 30000,
                        max: 300000,
                        divisions: 9,
                        onChanged: (v) => setState(() {
                          settings = settings.copyWith(sosActivationTime: v.toInt());
                        }),
                        hint: 'Temps pour annuler l\'alerte avant appel automatique',
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Activer appels automatiques'),
                        value: settings.enableAutoCall,
                        onChanged: (v) => setState(() {
                          settings = settings.copyWith(enableAutoCall: v ?? true);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // === ACTIONS ===
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetToDefaults,
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
                          onPressed: _save,
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

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              valueText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
        ),
        if (hint != null)
          Text(
            hint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
      ],
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
