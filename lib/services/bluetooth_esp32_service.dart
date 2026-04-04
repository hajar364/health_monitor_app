import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'dart:convert';
import 'package:health_monitor_app/services/esp32_service.dart';
import 'package:health_monitor_app/models/health_data.dart';

/// Service Bluetooth pour recevoir les données du firmware ESP32
class BluetoothESP32Service {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  final ESP32Service _esp32Service = ESP32Service();
  
  StreamSubscription? _bluetoothSubscription;
  final _bluetoothDataController = StreamController<String>.broadcast();
  
  bool _isConnected = false;
  String? _connectedDeviceAddress;

  // getter
  bool get isConnected => _isConnected;
  Stream<String> get bluetoothDataStream => _bluetoothDataController.stream;
  Stream<HealthData> get healthDataStream => _esp32Service.streamBluetoothData();

  /// Scanner et connecter à l'ESP32 via Bluetooth
  Future<void> connectToESP32(String deviceAddress) async {
    try {
      print('🔵 Tentative de connexion à $deviceAddress...');
      
      _connection = await BluetoothConnection.toAddress(deviceAddress);
      _connectedDeviceAddress = deviceAddress;
      _isConnected = true;
      
      print('✅ Connecté à l\'ESP32 !');
      
      // Écouter les données entrantes
      _listenToBluetoothData();
      
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Écouter et parser les données du Bluetooth
  void _listenToBluetoothData() {
    _connection?.input?.listen(
      (Uint8List data) {
        String received = String.fromCharCodes(data);
        print('📡 Données reçues: $received');
        
        // Envoyer au stream brut
        _bluetoothDataController.add(received);
        
        // Parser et traiter
        _processIncomingData(received);
      },
      onError: (error) {
        print('❌ Erreur Bluetooth: $error');
        disconnect();
      },
      onDone: () {
        print('⚠️ Connexion Bluetooth fermée');
        disconnect();
      },
    ).asFuture();
  }

  /// Traiter les données entrantes (buffer accumulation)
  String _buffer = '';

  void _processIncomingData(String received) {
    _buffer += received;

    // Vérifier si on a un bloc complet de données
    if (_buffer.contains('=== Mesures ===') && 
        _buffer.contains('LED éteinte') || _buffer.contains('LED allumée')) {
      
      // Extraire le bloc complet
      final startIdx = _buffer.indexOf('=== Mesures ===');
      final endIdx = _buffer.lastIndexOf('LED') + 15;  // Après "LED allumée/éteinte"
      
      if (startIdx != -1 && endIdx > startIdx) {
        final completeBlock = _buffer.substring(startIdx, endIdx);
        
        // Parser et émettre
        _esp32Service.parseAndProcessData(completeBlock);
        
        // Nettoyer le buffer
        _buffer = _buffer.substring(endIdx);
      }
    }
  }

  /// Envoyer une commande à l'ESP32
  Future<void> sendCommand(String command) async {
    if (!_isConnected || _connection == null) {
      throw Exception('Non connecté à l\'ESP32');
    }
    
    try {
      _connection!.output.add(utf8.encode(command + '\n'));
      await _connection!.output.allSent;
      print('📤 Commande envoyée: $command');
    } catch (e) {
      print('❌ Erreur envoi: $e');
    }
  }

  /// Demander une mesure immédiate
  Future<void> requestMeasurement() async {
    await sendCommand('MEASURE');
  }

  /// Activer/Désactiver LED d'alerte
  Future<void> setLED(bool enabled) async {
    final command = enabled ? 'LED_ON' : 'LED_OFF';
    await sendCommand(command);
  }

  /// Configurer les seuils de l'ESP32
  Future<void> setThreshold(String metric, double minVal, double maxVal) async {
    final command = 'SET_THRESHOLD $metric $minVal $maxVal';
    await sendCommand(command);
  }

  /// Déconnecter
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _isConnected = false;
      _connectedDeviceAddress = null;
      await _bluetoothSubscription?.cancel();
      print('✓ Déconnecté');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }

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

  void dispose() {
    _bluetoothSubscription?.cancel();
    _connection?.dispose();
    _bluetoothDataController.close();
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
