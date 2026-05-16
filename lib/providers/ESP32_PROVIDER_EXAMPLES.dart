// ============================================================
// EXEMPLES D'UTILISATION DU PROVIDER ESP32 IP
// ============================================================

// 📌 EXEMPLE 1: AFFICHER L'IP ACTUELLE DANS UN WIDGET
// ============================================================

import 'package:flutter/material.dart';
import '../providers/esp32_ip_provider.dart';

class IPDisplayWidget extends ConsumerWidget {
  const IPDisplayWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(esp32SettingsProvider);

    return settingsAsync.when(
      data: (settings) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('ESP32 Connecté à:'),
              Text(
                'http://${settings.ipAddress}:${settings.port}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Erreur: $error'),
    );
  }
}

// 📌 EXEMPLE 2: UTILISER L'IP DANS UN SERVICE HTTP
// ============================================================

// Dans votre service WiFi/HTTP:
import 'package:http/http.dart' as http;

class MyHttpService {
  Future<void> fetchSensorData(String ipAddress, int port) async {
    final url = Uri.http('$ipAddress:$port', '/sensors');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Données reçues: ${response.body}');
      }
    } catch (e) {
      print('Erreur: $e');
    }
  }

  Future<void> fetchSensorDataFromProvider(WidgetRef ref) async {
    // Dans un ConsumerWidget ou Notifier:
    final settingsAsync = ref.watch(esp32SettingsProvider);

    settingsAsync.when(
      data: (settings) {
        fetchSensorData(settings.ipAddress, settings.port);
      },
      loading: () => print('Chargement...'),
      error: (error, stack) => print('Erreur: $error'),
    );
  }
}

// 📌 EXEMPLE 3: MODIFIER L'IP DANS UN FORMULAIRE
// ============================================================

class SettingsForm extends ConsumerStatefulWidget {
  const SettingsForm({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<SettingsForm> {
  late TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(esp32SettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        _ipController.text = settings.ipAddress;

        return Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'Adresse IP'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Sauvegarder l'IP
                await ref
                    .read(esp32SettingsProvider.notifier)
                    .saveIPAddress(_ipController.text);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('IP sauvegardée !')),
                );
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Erreur: $error'),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}

// 📌 EXEMPLE 4: UTILISER DANS UN STATENOTIFIER
// ============================================================

class MySensorNotifier extends StateNotifier<List<SensorReading>> {
  final Ref ref;

  MySensorNotifier(this.ref) : super([]);

  Future<void> loadSensorData() async {
    final settingsAsync = ref.watch(esp32SettingsProvider);

    settingsAsync.when(
      data: (settings) async {
        try {
          final url = Uri.http(
            '${settings.ipAddress}:${settings.port}',
            '/sensors',
          );
          final response = await http.get(url);

          if (response.statusCode == 200) {
            // Traiter les données
            print('Données: ${response.body}');
          }
        } catch (e) {
          print('Erreur: $e');
        }
      },
      loading: () => print('Chargement paramètres...'),
      error: (error, stack) => print('Erreur: $error'),
    );
  }
}

// 📌 EXEMPLE 5: ACCÈS RAPIDE À L'IP (NON-ASYNC)
// ============================================================

class QuickIPAccessWidget extends ConsumerWidget {
  const QuickIPAccessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utilise le provider synchrone - utile pour l'affichage rapide
    final ip = ref.watch(lastKnownIPProvider);

    return Text('IP actuelle: $ip');
  }
}

// 📌 EXEMPLE 6: ÉCOUTER LES CHANGEMENTS D'IP
// ============================================================

class IPChangeListenerWidget extends ConsumerWidget {
  const IPChangeListenerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écouter les changements
    ref.listen(esp32SettingsProvider, (previous, next) {
      next.when(
        data: (settings) {
          print('IP changée à: ${settings.ipAddress}');
          // Vous pouvez déclencher des actions ici
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nouvelle IP: ${settings.ipAddress}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        loading: () {},
        error: (error, stack) {
          print('Erreur IP: $error');
        },
      );
    });

    return const Placeholder();
  }
}

// 📌 EXEMPLE 7: INTÉGRATION DANS VOTRE DASHBOARD
// ============================================================

class HealthDashboard extends ConsumerWidget {
  const HealthDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(esp32SettingsProvider);
    final sensorData = ref.watch(sensorDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Monitor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Naviguer vers l'écran de configuration
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ESP32ConnectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Afficher l'IP actuelle
            settingsAsync.when(
              data: (settings) => Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const Icon(Icons.router),
                  title: const Text('ESP32 Connecté'),
                  subtitle: Text('${settings.ipAddress}:${settings.port}'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Erreur: $error'),
            ),

            // Afficher les données des capteurs
            sensorData.when(
              data: (data) => Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Température: ${data.temperature}°C'),
                      Text('Accélération X: ${data.accelX}'),
                    ],
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Erreur: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

// 📌 EXEMPLE 8: METTRE À JOUR L'HEURE DE DERNIÈRE CONNEXION
// ============================================================

// Appelé après une connexion réussie:
Future<void> onSuccessfulConnection(WidgetRef ref) async {
  await ref.read(esp32SettingsProvider.notifier).updateLastConnectedTime();
}

// 📌 RÉSUMÉ DES MÉTHODES DISPONIBLES:
// ============================================================
/*
final esp32SettingsProvider = StateNotifierProvider<...>(...);

// Accéder aux paramètres:
ref.watch(esp32SettingsProvider);

// Sauvegarder une IP:
await ref.read(esp32SettingsProvider.notifier).saveIPAddress('192.168.1.100');

// Sauvegarder un port:
await ref.read(esp32SettingsProvider.notifier).savePort(80);

// Sauvegarder tous les paramètres:
await ref.read(esp32SettingsProvider.notifier).saveSettings(newSettings);

// Mettre à jour l'heure de connexion:
await ref.read(esp32SettingsProvider.notifier).updateLastConnectedTime();

// Réinitialiser:
await ref.read(esp32SettingsProvider.notifier).clearSettings();

// Accès rapide à l'IP (synchrone):
ref.watch(lastKnownIPProvider);
*/
