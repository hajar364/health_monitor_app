import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/esp32_ip_provider.dart';

class ESP32SetupScreen extends ConsumerStatefulWidget {
  const ESP32SetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ESP32SetupScreen> createState() => _ESP32SetupScreenState();
}

class _ESP32SetupScreenState extends ConsumerState<ESP32SetupScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _deviceNameController;
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _portController = TextEditingController();
    _deviceNameController = TextEditingController();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final settingsAsync = ref.read(esp32SettingsProvider);
    settingsAsync.whenData((settings) {
      setState(() {
        _ipController.text = settings.ipAddress;
        _portController.text = settings.port.toString();
        _deviceNameController.text = settings.deviceName;
      });
    });
  }

  Future<void> _saveAndConnect() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty) {
      setState(() {
        _statusMessage = '❌ Tous les champs sont requis';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '⏳ Connexion en cours...';
    });

    try {
      final port = int.parse(_portController.text);
      final settings = ESP32Settings(
        ipAddress: _ipController.text.trim(),
        port: port,
        deviceName: _deviceNameController.text.trim(),
        rememberDevice: true,
      );

      // Sauvegarder les paramètres
      await ref
          .read(esp32SettingsProvider.notifier)
          .saveSettings(settings);

      // Tester la connexion
      final wifiService = ref.read(wifiServiceProvider);
      final connected = await wifiService.connectToESP32(
        settings.ipAddress,
        port: settings.port,
      );

      setState(() {
        _isConnected = connected;
        if (connected) {
          _statusMessage = '✅ ESP32 connecté avec succès!';
        } else {
          _statusMessage = '❌ Impossible de se connecter à l\'ESP32';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Configuration ESP32'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Titre ===
            Text(
              '📡 Paramètres de connexion',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Configurez l\'adresse IP et le port de votre ESP32',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),

            // === Champ IP ===
            TextField(
              controller: _ipController,
              enabled: !_isLoading,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Adresse IP de l\'ESP32',
                hintText: '192.168.1.100',
                prefixIcon: const Icon(Icons.router),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _ipController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _ipController.clear,
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // === Champ Port ===
            TextField(
              controller: _portController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '80',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === Champ Nom du device ===
            TextField(
              controller: _deviceNameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Nom du device',
                hintText: 'ESP32 Health Monitor',
                prefixIcon: const Icon(Icons.devices),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === Bouton de connexion ===
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveAndConnect,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isLoading ? 'Connexion...' : 'Tester et sauvegarder',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === Message de statut ===
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _isConnected
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.warning,
                      color:
                          _isConnected ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _isConnected
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // === Section d'aide ===
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
                  Text(
                    '💡 Aide',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Assurez-vous que votre ESP32 est alimenté et connecté à WiFi\n'
                    '2. Vérifiez l\'adresse IP (visible dans le moniteur série)\n'
                    '3. Le port par défaut est 80 (HTTP standard)\n'
                    '4. Une fois sauvegardé, la configuration persiste',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
