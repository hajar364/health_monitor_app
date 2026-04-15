import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'dart:convert';
import 'package:health_monitor_app/services/esp32_service.dart';
import 'package:health_monitor_app/models/health_data.dart';

/// Service Bluetooth pour recevoir les données du firmware ESP32
/// Gère la connexion, la réception de données JSON et l'envoi de commandes
class BluetoothESP32Service {
  static const String ESP32_DEVICE_NAME = "ESP32_HealthMonitor";
  
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  final ESP32Service _esp32Service = ESP32Service();
  
  BluetoothConnection? _connection;
  StreamSubscription? _bluetoothSubscription;
  
  final _bluetoothDataController = StreamController<String>.broadcast();
  final _healthDataController = StreamController<HealthData>.broadcast();
  
  bool _isConnected = false;
  String? _connectedDeviceAddress;
  String _buffer = '';

  // Getters
  bool get isConnected => _isConnected && _connection != null;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  Stream<String> get bluetoothDataStream => _bluetoothDataController.stream;
  Stream<HealthData> get healthDataStream => _healthDataController.stream;

  /// Lister les appareils Bluetooth disponibles
  Future<List<BluetoothDevice>> getAvailableDevices() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      print('❌ Erreur listing appareils: $e');
      return [];
    }
  }

  /// Connecter à un appareil Bluetooth par son adresse
  Future<bool> connectToDevice(String deviceAddress) async {
    try {
      print('🔵 Tentative de connexion à $deviceAddress...');
      
      _connection = await BluetoothConnection.toAddress(deviceAddress);
      _connectedDeviceAddress = deviceAddress;
      _isConnected = true;
      _buffer = '';
      
      print('✅ Connecté à l\'ESP32 !');
      _esp32Service.setConnectionStatus(true);
      
      // Écouter les données entrantes
      _listenToBluetoothData();
      
      return true;
      
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _isConnected = false;
      _esp32Service.setConnectionStatus(false);
      return false;
    }
  }

  /// Connecter au premier ESP32 trouvé
  Future<bool> connectToFirstESP32() async {
    try {
      final devices = await getAvailableDevices();
      
      for (final device in devices) {
        if (device.name?.contains('ESP32') ?? false) {
          print('📱 ESP32 trouvé: ${device.name} - ${device.address}');
          return connectToDevice(device.address);
        }
      }
      
      print('⚠️ Aucun ESP32 trouvé dans les appareils appairés');
      return false;
      
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }

  /// Écouter et traiter les données du Bluetooth
  void _listenToBluetoothData() {
    if (_connection?.input == null) return;
    
    _bluetoothSubscription = _connection!.input!.listen(
      (Uint8List data) {
        String received = String.fromCharCodes(data);
        _buffer += received;
        
        // Traiter les blocs JSON complets
        _processBuffer();
      },
      onError: (error) {
        print('❌ Erreur Bluetooth: $error');
        disconnect();
      },
      onDone: () {
        print('⚠️ Connexion Bluetooth fermée');
        disconnect();
      },
    );
  }

  /// Traiter le buffer pour extraire les blocs JSON complets
  void _processBuffer() {
    while (true) {
      // Chercher le début d'un JSON
      final startIdx = _buffer.indexOf('{');
      if (startIdx == -1) {
        _buffer = '';
        return;
      }

      // Chercher la fin de ce JSON
      int braceCount = 0;
      int endIdx = -1;
      
      for (int i = startIdx; i < _buffer.length; i++) {
        if (_buffer[i] == '{') {
          braceCount++;
        } else if (_buffer[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            endIdx = i;
            break;
          }
        }
      }

      if (endIdx == -1) {
        // JSON incomplet, attendre plus de données
        if (startIdx > 0) {
          _buffer = _buffer.substring(startIdx);
        }
        return;
      }

      // Extraire et traiter le bloc JSON
      final jsonBlock = _buffer.substring(startIdx, endIdx + 1);
      
      try {
        // Envoyer les données brutes
        _bluetoothDataController.add(jsonBlock);
        
        // Parser avec ESP32Service
        _esp32Service.parseAndProcessData(jsonBlock);
        
        // Relayer via notre stream aussi
        final healthData = HealthData.fromJson(jsonDecode(jsonBlock));
        _healthDataController.add(healthData);
        
      } catch (e) {
        print('⚠️ Erreur parsing JSON: $e');
        print('   Bloc: $jsonBlock');
      }

      // Passer au prochain JSON dans le buffer
      _buffer = _buffer.substring(endIdx + 1);
    }
  }

  /// Envoyer une commande à l'ESP32
  Future<void> sendCommand(String command) async {
    if (!isConnected || _connection == null) {
      throw Exception('Non connecté à l\'ESP32');
    }
    
    try {
      _connection!.output.add(utf8.encode(command + '\n'));
      await _connection!.output.allSent;
      print('📤 Commande envoyée: $command');
      return;
    } catch (e) {
      print('❌ Erreur envoi: $e');
      rethrow;
    }
  }

  /// Demander une mesure immédiate
  Future<void> requestMeasurement() async {
    await sendCommand('MEASURE');
  }

  /// Activer la LED d'alerte
  Future<void> activateLED() async {
    await sendCommand('LED_ON');
  }

  /// Désactiver la LED d'alerte
  Future<void> deactivateLED() async {
    await sendCommand('LED_OFF');
  }

  /// Demander le statut de l'ESP32
  Future<void> requestStatus() async {
    await sendCommand('STATUS');
  }

  /// Configurer l'intervalle de mesure en millisecondes
  Future<void> setMeasureInterval(int intervalMs) async {
    if (intervalMs < 100) {
      throw Exception('Intervalle minimum: 100ms');
    }
    await sendCommand('SET_INTERVAL:$intervalMs');
  }

  /// Configurer les seuils de l'ESP32
  Future<void> setThreshold(String metric, double minVal, double maxVal) async {
    // Cette commande dépend de l'implémentation ESP32
    // À adapter selon vos besoins
    await sendCommand('SET_THRESHOLD $metric $minVal $maxVal');
  }

  /// Déconnecter
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _isConnected = false;
      _connectedDeviceAddress = null;
      await _bluetoothSubscription?.cancel();
      _buffer = '';
      _esp32Service.setConnectionStatus(false);
      print('✓ Déconnecté');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }

  /// Fermer et nettoyer les ressources
  void dispose() {
    disconnect();
    _bluetoothDataController.close();
    _healthDataController.close();
    _esp32Service.dispose();
  }
}

/// Widget pour scanner et se connecter aux appareils Bluetooth
class BluetoothScannerWidget extends StatefulWidget {
  final Function(BluetoothESP32Service) onConnected;

  const BluetoothScannerWidget({
    Key? key,
    required this.onConnected,
  }) : super(key: key);

  @override
  State<BluetoothScannerWidget> createState() => _BluetoothScannerWidgetState();
}

class _BluetoothScannerWidgetState extends State<BluetoothScannerWidget> {
  late BluetoothESP32Service _bluetoothService;
  List<BluetoothDevice> _bondedDevices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _bluetoothService = BluetoothESP32Service();
    _loadBondedDevices();
  }

  Future<void> _loadBondedDevices() async {
    setState(() => _isScanning = true);
    try {
      final devices = await _bluetoothService.getAvailableDevices();
      setState(() {
        _bondedDevices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothService.connectToESP32(device.address);
      widget.onConnected(_bluetoothService);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur connexion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Bluetooth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _loadBondedDevices,
          ),
        ],
      ),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : _bondedDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aucun appareil Bluetooth trouvé'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBondedDevices,
                        child: const Text('Rechercher à nouveau'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _bondedDevices.length,
                  itemBuilder: (context, index) {
                    final device = _bondedDevices[index];
                    return ListTile(
                      title: Text(device.name ?? 'Appareil inconnu'),
                      subtitle: Text(device.address),
                      trailing: const Icon(Icons.bluetooth),
                      onTap: () => _connectToDevice(device),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}
