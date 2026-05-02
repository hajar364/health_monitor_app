import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/esp32_ip_provider.dart';

class ESP32ConnectionScreen extends ConsumerStatefulWidget {
  const ESP32ConnectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ESP32ConnectionScreen> createState() =>
      _ESP32ConnectionScreenState();
}

class _ESP32ConnectionScreenState extends ConsumerState<ESP32ConnectionScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _portController = TextEditingController(text: '80');
    
    // Charger l'IP sauvegardée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedSettings = ref.read(esp32SettingsProvider);
      savedSettings.when(
        data: (settings) {
          _ipController.text = settings.ipAddress;
          _portController.text = settings.port.toString();
        },
        loading: () {},
        error: (_, __) {},
      );
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connectToESP32() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text) ?? 80;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une adresse IP')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      // Sauvegarder l'IP et le port
      await ref.read(esp32SettingsProvider.notifier).saveIPAddress(ip);
      await ref.read(esp32SettingsProvider.notifier).savePort(port);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paramètres sauvegardés avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Attendre un peu puis revenir
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(esp32SettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration ESP32'),
        backgroundColor: Colors.blueAccent,
      ),
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔗 Connexion ESP32',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrez l\'adresse IP de votre ESP32 Health Monitor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // IP Address Input
              Text(
                'Adresse IP',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '192.168.39.105',
                  prefixIcon: const Icon(Icons.router),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Port Input
              Text(
                'Port',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '80',
                  prefixIcon: const Icon(Icons.settings_input_component),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Device Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Appareil: ${settings.deviceName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    if (settings.lastConnectedAt != null)
                      Text(
                        '⏰ Dernier accès: ${settings.lastConnectedAt!.toString().split('.')[0]}',
                        style: const TextStyle(fontSize: 13),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isConnecting ? null : _connectToESP32,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '💾 Sauvegarder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Clear Button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(esp32SettingsProvider.notifier)
                        .clearSettings();
                    _ipController.clear();
                    _portController.text = '80';

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Paramètres réinitialisés'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text(
                    '🔄 Réinitialiser',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
    );
  }
}
