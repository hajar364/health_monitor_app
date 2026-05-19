import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/wifi_tcp_service.dart';
import '../services/fall_detection_service.dart';
import '../services/alert_service.dart';
import '../models/fall_detection_data.dart';
import '../models/threshold_settings.dart';
import '../models/alert_event.dart';
import '../providers/esp32_ip_provider.dart';
import 'esp32_setup_screen.dart';
import '../widgets/app_logo.dart';

// États de connexion possibles
enum _ConnState { connecting, connected, disconnected, simulating }

class FallDetectionDashboard extends StatefulWidget {
  const FallDetectionDashboard({super.key});

  @override
  State<FallDetectionDashboard> createState() => _FallDetectionDashboardState();
}

class _FallDetectionDashboardState extends State<FallDetectionDashboard> {
  late WifiTcpService wifiService;
  late FallDetectionService fallService;
  late AlertService alertService;

  _ConnState _state = _ConnState.connecting;
  IMUSensorData? lastSensorData;
  List<IMUSensorData> sensorBuffer = [];
  DateTime? lastUpdate;
  String _activeIp = '';
  int _activePort = 80;

  // Compteur pour la re-tentative automatique
  int _retryIn = 30;
  Timer? _retryTimer;
  StreamSubscription? _sensorStreamSub;
  StreamSubscription? _testStreamSub;
  bool _fallDialogShowing = false;

  @override
  void initState() {
    super.initState();
    wifiService = WifiTcpService();
    fallService = FallDetectionService(thresholds: ThresholdSettings());
    alertService = AlertService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDashboard());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _sensorStreamSub?.cancel();
    _testStreamSub?.cancel();
    super.dispose();
  }

  // ─────────────────── CONNEXION ───────────────────────────────

  Future<void> _initDashboard() async {
    if (!mounted) return;
    final esp32 = context.read<ESP32SettingsNotifier>().settings;
    final thresholds = context.read<ThresholdSettingsNotifier>().settings;
    fallService = FallDetectionService(thresholds: thresholds);
    await _connect(esp32.ipAddress, esp32.port);
  }

  Future<void> _connect(String ip, int port) async {
    if (!mounted) return;

    _retryTimer?.cancel();
    _sensorStreamSub?.cancel();
    _testStreamSub?.cancel();

    setState(() {
      _state = _ConnState.connecting;
      _activeIp = ip;
      _activePort = port;
      lastSensorData = null;
      sensorBuffer.clear();
    });

    final ok = await context
        .read<WifiServiceNotifier>()
        .connectToESP32(ip, port: port);

    if (!mounted) return;

    if (ok) {
      setState(() => _state = _ConnState.connected);
      _startRealStream();
    } else {
      _onConnectionFailed();
    }
  }

  void _onConnectionFailed() {
    if (!mounted) return;
    setState(() {
      _state = _ConnState.disconnected;
      _retryIn = 30;
    });
    _startRetryCountdown();
  }

  // Lance un compte à rebours puis retente automatiquement
  void _startRetryCountdown() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _retryIn--);
      if (_retryIn <= 0) {
        t.cancel();
        _connect(_activeIp, _activePort);
      }
    });
  }

  void _startRealStream() {
    _sensorStreamSub = wifiService.getSensorDataStream().listen(
      (data) {
        if (!mounted) return;
        setState(() {
          lastSensorData = data;
          lastUpdate = DateTime.now();
          sensorBuffer.add(data);
          if (sensorBuffer.length > 50) sensorBuffer.removeAt(0);
        });
        // Priorité 1 : chute confirmée par l'ESP32 (algorithme embarqué)
        if (data.fallDetected) {
          _handleFall(FallEvent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            severity: 'HIGH',
            confidence: 95,
            reason: 'impact + immobilité (ESP32)',
            isConfirmed: true,
            sensorData: data,
          ));
          return;
        }
        // Priorité 2 : détection Flutter côté client
        _analyzeFall();
      },
      onError: (_) {
        if (!mounted) return;
        // Connexion perdue en cours de streaming
        _onConnectionFailed();
      },
    );
  }

  void _startSimulatedStream() {
    _testStreamSub =
        Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
      if (!mounted) return;
      final d = wifiService.generateTestSensorData();
      setState(() {
        lastSensorData = d;
        lastUpdate = DateTime.now();
        sensorBuffer.add(d);
        if (sensorBuffer.length > 50) sensorBuffer.removeAt(0);
      });
      _analyzeFall();
    });
  }

  void _startSimulation() {
    _retryTimer?.cancel();
    _sensorStreamSub?.cancel();
    setState(() {
      _state = _ConnState.simulating;
      lastSensorData = null;
      sensorBuffer.clear();
    });
    _startSimulatedStream();
  }

  void _analyzeFall() {
    final fall = fallService.analyzeSensorData(sensorBuffer);
    if (fall != null && fall.confidence > 75) _handleFall(fall);
  }

  // ─────────────────── DÉTECTION DE CHUTE ─────────────────────

  void _handleFall(FallEvent fall) {
    if (_fallDialogShowing) return; // popup déjà visible
    _fallDialogShowing = true;

    final thresholds = context.read<ThresholdSettingsNotifier>().settings;
    final sosPhone = thresholds.sosPhoneNumber.isNotEmpty
        ? thresholds.sosPhoneNumber
        : null;
    final totalSeconds =
        (thresholds.sosActivationTime / 1000).round().clamp(5, 120);

    int secondsLeft = totalSeconds;
    Timer? sosTimer;

    void cancelTimer() {
      sosTimer?.cancel();
      sosTimer = null;
    }

    // Enregistrer dans l'historique
    alertService.triggerSOSAlert(AlertEvent(
      id: fall.id,
      timestamp: fall.timestamp,
      alertType: 'FALL',
      severity: fall.severity,
      message: 'Chute détectée — ${fall.reason}',
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) {
          // Lance le compte à rebours une seule fois
          sosTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            secondsLeft--;
            if (secondsLeft <= 0) {
              t.cancel();
              Navigator.of(dialogCtx).pop();
              if (thresholds.enableAutoCall && sosPhone != null) {
                alertService.emergencyCall(sosPhone);
              }
            } else {
              setDialogState(() {});
            }
          });

          return AlertDialog(
            backgroundColor: Colors.red.shade50,
            title: const Text(
              '🚨 CHUTE DÉTECTÉE',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confiance : ${fall.confidence.toStringAsFixed(1)} %'),
                Text('Sévérité  : ${fall.severity}'),
                Text('Raison    : ${fall.reason}'),
                const SizedBox(height: 16),
                if (thresholds.enableAutoCall && sosPhone != null) ...[
                  Text(
                    'Appel SOS vers $sosPhone dans $secondsLeft s',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1 - (secondsLeft / totalSeconds),
                      minHeight: 6,
                      color: Colors.red,
                      backgroundColor: Colors.red.shade100,
                    ),
                  ),
                ] else
                  Text(
                    sosPhone == null
                        ? '⚠️ Aucun numéro configuré dans Paramètres'
                        : '📵 Appel auto désactivé dans Paramètres',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cancelTimer();
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text('ANNULER'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  cancelTimer();
                  Navigator.of(dialogCtx).pop();
                  alertService.emergencyCall(sosPhone ?? '0617951701');
                },
                icon: const Icon(Icons.phone),
                label: Text('APPELER ${sosPhone ?? '0617951701'}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      cancelTimer();
      _fallDialogShowing = false;
    });
  }

  void _simulateFall() {
    for (int i = 0; i < 20; i++) {
      final intensity = 1 + (i / 20) * 3;
      sensorBuffer.add(IMUSensorData(
        timestamp: DateTime.now(),
        accelX: 2.0 * intensity, accelY: 1.5 * intensity,
        accelZ: -9.8 + 3.0 * intensity,
        gyroX: 50 * intensity, gyroY: 40 * intensity, gyroZ: 30 * intensity,
        magnitude: 9.8 * intensity, temperature: 36.5,
      ));
    }
    for (int i = 0; i < 10; i++) {
      sensorBuffer.add(IMUSensorData(
        timestamp: DateTime.now(),
        accelX: 0.1, accelY: 0.1, accelZ: -9.8,
        gyroX: 1, gyroY: 1, gyroZ: 1,
        magnitude: 9.8, temperature: 36.5,
      ));
    }
    final fall = fallService.analyzeSensorData(sensorBuffer);
    if (fall != null) {
      _handleFall(fall);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Chute non détectée (confiance insuffisante)')),
      );
    }
  }

  // ─────────────────── BUILD ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Reconnecter si l'IP change dans les settings
    final esp32Settings = context.watch<ESP32SettingsNotifier>();
    if (!esp32Settings.isLoading &&
        _activeIp.isNotEmpty &&
        _state != _ConnState.connecting &&
        (esp32Settings.settings.ipAddress != _activeIp ||
            esp32Settings.settings.port != _activePort)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _connect(esp32Settings.settings.ipAddress, esp32Settings.settings.port);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: AppLogo(size: 36),
        ),
        title: const Text(
          'HealthGuard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          if (_state != _ConnState.connecting)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reconnecter',
              onPressed: () => _connect(_activeIp, _activePort),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ConnState.connecting:
        return _buildConnectingView();
      case _ConnState.disconnected:
        return _buildDisconnectedView();
      case _ConnState.connected:
      case _ConnState.simulating:
        return _buildDataView();
    }
  }

  // ─────────────────── VUE : CONNEXION EN COURS ────────────────

  Widget _buildConnectingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 96, showLabel: true),
            const SizedBox(height: 32),
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 24),
            const Text(
              'Connexion à l\'ESP32…',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$_activeIp:$_activePort',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Timeout : 5 s',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── VUE : PAS DE CONNEXION ──────────────────

  Widget _buildDisconnectedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Icône principale
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade200, width: 2),
            ),
            child: Icon(Icons.wifi_off, size: 64, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),

          const Text(
            'ESP32 non accessible',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Impossible de joindre $_activeIp:$_activePort',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Vérifiez que l\'ESP32 est allumé\net connecté au même réseau WiFi.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Compte à rebours + barre de progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nouvelle tentative dans',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Text(
                      '$_retryIn s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _retryIn <= 10
                            ? Colors.orange.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1 - (_retryIn / 30),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Réessayer maintenant
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _connect(_activeIp, _activePort),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton Modifier l'IP
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                _retryTimer?.cancel();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ESP32SetupScreen()),
                );
                // Retenter après retour de la page settings
                if (mounted) {
                  final s = context.read<ESP32SettingsNotifier>().settings;
                  _connect(s.ipAddress, s.port);
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Modifier l\'adresse IP'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton Mode simulation
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _startSimulation,
              icon: Icon(Icons.science, color: Colors.orange.shade600),
              label: Text(
                'Continuer en mode simulation',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Aide diagnostic
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
                  '💡 Aide au diagnostic',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                ..._diagTips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: TextStyle(color: Colors.blue.shade600)),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _diagTips = [
    'Vérifiez que l\'ESP32 est alimenté (LED allumée)',
    'L\'ESP32 et le téléphone doivent être sur le même réseau WiFi',
    'Consultez le moniteur série Arduino pour voir l\'IP réelle',
    'Le port par défaut est 80 (firmware HTTP)',
    'Désactivez le pare-feu ou VPN si actif',
  ];

  // ─────────────────── VUE : DONNÉES ───────────────────────────

  Widget _buildDataView() {
    final isSimulated = _state == _ConnState.simulating;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionBanner(isSimulated),
          const SizedBox(height: 16),
          if (lastSensorData != null) ...[
            _buildSensorGrid(),
            const SizedBox(height: 16),
            _buildMagnitudeChart(),
            const SizedBox(height: 16),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          _buildActionButtons(isSimulated),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Bannière statut ────────────────────────────────────────

  Widget _buildConnectionBanner(bool isSimulated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSimulated ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSimulated ? Colors.orange.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSimulated ? Icons.science : Icons.cloud_done,
            color: isSimulated ? Colors.orange.shade600 : Colors.green.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSimulated
                      ? 'Mode simulation (ESP32 hors ligne)'
                      : 'ESP32 connecté — $_activeIp:$_activePort',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSimulated
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                ),
                if (lastUpdate != null)
                  Text(
                    'Dernière donnée : ${_formatTime(lastUpdate!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          if (isSimulated)
            OutlinedButton(
              onPressed: () => _connect(_activeIp, _activePort),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                side: BorderSide(color: Colors.orange.shade400),
              ),
              child: Text(
                'Reconnecter',
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade700),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Grille capteurs ─────────────────────────────────────────

  Widget _buildSensorGrid() {
    final d = lastSensorData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📡 Données capteurs (temps réel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _sensorTile('Accel X', d.accelX, 'g', Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _sensorTile('Accel Y', d.accelY, 'g', Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _sensorTile('Accel Z', d.accelZ, 'g', Colors.blue)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _sensorTile('Gyro X', d.gyroX, '°/s', Colors.purple)),
          const SizedBox(width: 8),
          Expanded(child: _sensorTile('Gyro Y', d.gyroY, '°/s', Colors.purple)),
          const SizedBox(width: 8),
          Expanded(child: _sensorTile('Gyro Z', d.gyroZ, '°/s', Colors.purple)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _sensorTile('🌡 Température', d.temperature, '°C',
              _tempColor(d.temperature), big: true)),
          const SizedBox(width: 8),
          Expanded(child: _sensorTile('📏 Magnitude', d.magnitude, 'g',
              d.magnitude > 12 ? Colors.red : Colors.green, big: true)),
        ]),
      ],
    );
  }

  Widget _sensorTile(String label, double value, String unit, Color color,
      {bool big = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(big ? 1 : 2)} $unit',
            style: TextStyle(
              fontSize: big ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Graphe magnitude ─────────────────────────────────────────

  Widget _buildMagnitudeChart() {
    if (sensorBuffer.length < 2) return const SizedBox.shrink();

    final spots = sensorBuffer
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.magnitude))
        .toList();

    final maxY =
        (sensorBuffer.map((d) => d.magnitude).reduce((a, b) => a > b ? a : b) + 2)
            .clamp(12.0, 50.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📈 Magnitude accélération',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 5,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue.shade600,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.shade100.withValues(alpha: 0.4),
                ),
              ),
              LineChartBarData(
                spots: [
                  FlSpot(0, 14.7),
                  FlSpot((sensorBuffer.length - 1).toDouble(), 14.7),
                ],
                color: Colors.red.shade300,
                barWidth: 1,
                dashArray: [4, 4],
                dotData: const FlDotData(show: false),
              ),
            ],
          )),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(width: 12, height: 2, color: Colors.blue.shade600),
            const SizedBox(width: 4),
            const Text('Magnitude', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 12),
            Container(width: 12, height: 2, color: Colors.red.shade300),
            const SizedBox(width: 4),
            const Text('Seuil chute', style: TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  // ─── Boutons action ──────────────────────────────────────────

  Widget _buildActionButtons(bool isSimulated) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _simulateFall,
            icon: const Icon(Icons.warning),
            label: const Text('🧪 SIMULER UNE CHUTE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Buffer', '${sensorBuffer.length}/50'),
              _statItem(
                'Temp.',
                lastSensorData != null
                    ? '${lastSensorData!.temperature.toStringAsFixed(1)}°C'
                    : '—',
              ),
              _statItem(
                'Mag.',
                lastSensorData != null
                    ? '${lastSensorData!.magnitude.toStringAsFixed(2)} g'
                    : '—',
              ),
              _statItem('Source', isSimulated ? 'Sim.' : 'ESP32'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  Color _tempColor(double t) {
    if (t > 39) return Colors.red;
    if (t < 35) return Colors.blue;
    return Colors.green;
  }
}
