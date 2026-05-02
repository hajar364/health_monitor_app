// ============================================================
// INTÉGRATION COMPLÈTE - ESP32 IP PROVIDER + CONNEXION
// ============================================================
// Ce fichier montre comment intégrer le nouveau provider
// avec votre système existant d'app_providers.dart

// À AJOUTER au début de votre app_providers.dart:
import 'esp32_ip_provider.dart';  // ← AJOUTER CETTE LIGNE

// ============================================================
// MODIFIER votre ESP32ConnectionNotifier ainsi:
// ============================================================

/*
ANCIEN CODE:
============

class ESP32ConnectionNotifier extends StateNotifier<ESP32ConnectionState> {
  final WifiTcpService wifiService;

  ESP32ConnectionNotifier(this.wifiService) : super(ESP32ConnectionState());

  Future<void> connectToESP32(String ip, int port) async {
    state = state.copyWith(statusMessage: 'Connexion en cours...');
    
    final success = await wifiService.connectToESP32(ip, port: port);
    
    if (success) {
      state = state.copyWith(
        isConnected: true,
        ipAddress: ip,
        port: port,
        statusMessage: 'Connecté ✅',
        lastUpdate: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isConnected: false,
        statusMessage: 'Erreur connexion',
      );
    }
  }
}


NOUVEAU CODE:
=============
*/

class ESP32ConnectionNotifier extends StateNotifier<ESP32ConnectionState> {
  final WifiTcpService wifiService;
  final Ref ref;  // ← AJOUTER LE REF

  ESP32ConnectionNotifier(this.wifiService, this.ref) 
      : super(ESP32ConnectionState()) {
    // Charger l'IP sauvegardée au démarrage
    _loadSavedIP();
  }

  // ✨ NOUVELLES MÉTHODES ✨

  /// Charger l'IP sauvegardée au démarrage
  Future<void> _loadSavedIP() async {
    try {
      final settingsAsync = ref.watch(esp32SettingsProvider);
      settingsAsync.whenData((settings) {
        state = state.copyWith(
          ipAddress: settings.ipAddress,
          port: settings.port,
        );
      });
    } catch (e) {
      print('Erreur chargement IP: $e');
    }
  }

  /// Connexion avec sauvegarde automatique
  Future<void> connectToESP32(String ip, int port) async {
    state = state.copyWith(statusMessage: 'Connexion en cours...');

    final success = await wifiService.connectToESP32(ip, port: port);

    if (success) {
      // ✅ SAUVEGARDER L'IP ET LE PORT
      await ref.read(esp32SettingsProvider.notifier).saveIPAddress(ip);
      await ref.read(esp32SettingsProvider.notifier).savePort(port);

      // ✅ METTRE À JOUR L'HEURE DE CONNEXION
      await ref
          .read(esp32SettingsProvider.notifier)
          .updateLastConnectedTime();

      state = state.copyWith(
        isConnected: true,
        ipAddress: ip,
        port: port,
        statusMessage: 'Connecté ✅',
        lastUpdate: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isConnected: false,
        statusMessage: 'Erreur connexion',
      );
    }
  }

  /// Reconnecter avec l'IP sauvegardée
  Future<void> reconnectWithSavedIP() async {
    try {
      final settingsAsync = ref.watch(esp32SettingsProvider);
      settingsAsync.whenData((settings) async {
        await connectToESP32(settings.ipAddress, settings.port);
      });
    } catch (e) {
      state = state.copyWith(
        statusMessage: 'Erreur reconnexion: $e',
      );
    }
  }

  /// Obtenir l'URL complète de l'ESP32
  String getESP32URL() {
    return 'http://${state.ipAddress}:${state.port}';
  }

  /// Déconnecter et nettoyer
  Future<void> disconnect() async {
    await wifiService.disconnect();
    state = state.copyWith(
      isConnected: false,
      statusMessage: 'Déconnecté',
    );
  }
}

// ============================================================
// MODIFIER le provider lui-même ainsi:
// ============================================================

/*
ANCIEN CODE:
============

final esp32ConnectionProvider = 
    StateNotifierProvider<ESP32ConnectionNotifier, ESP32ConnectionState>((ref) {
  final wifiService = ref.watch(wifiServiceProvider);
  return ESP32ConnectionNotifier(wifiService);
});


NOUVEAU CODE:
=============
*/

final esp32ConnectionProvider =
    StateNotifierProvider<ESP32ConnectionNotifier, ESP32ConnectionState>((ref) {
  final wifiService = ref.watch(wifiServiceProvider);
  return ESP32ConnectionNotifier(wifiService, ref);  // ← PASSER LE REF
});

// ============================================================
// NOUVEAUX PROVIDERS UTILES
// ============================================================

/// URL complète de l'ESP32 pour les requêtes HTTP
final esp32URLProvider = Provider<String>((ref) {
  final connectionState = ref.watch(esp32ConnectionProvider);
  return 'http://${connectionState.ipAddress}:${connectionState.port}';
});

/// Endpoint de ping pour vérifier la connexion
final esp32PingProvider = FutureProvider<bool>((ref) async {
  try {
    final url = Uri.parse('${ref.watch(esp32URLProvider)}/ping');
    final response = await http.get(url).timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw Exception('Timeout'),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
});

/// Statut de la connexion ESP32 (connecté ou non)
final esp32IsConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(esp32ConnectionProvider);
  return connectionState.isConnected;
});

/// Message de statut de la connexion
final esp32StatusMessageProvider = Provider<String>((ref) {
  final connectionState = ref.watch(esp32ConnectionProvider);
  return connectionState.statusMessage;
});

// ============================================================
// UTILISATION DANS VOS WIDGETS
// ============================================================

// EXEMPLE 1: Dashboard affichant l'IP et le statut
class ESP32DashboardExample extends ConsumerWidget {
  const ESP32DashboardExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(esp32ConnectionProvider);
    final isConnected = ref.watch(esp32IsConnectedProvider);
    final url = ref.watch(esp32URLProvider);
    final pingAsync = ref.watch(esp32PingProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error_circle,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  connectionState.statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('IP: $url'),
            const SizedBox(height: 8),
            pingAsync.when(
              data: (isAlive) => Text(
                'Ping: ${isAlive ? '✅ Actif' : '❌ Inactif'}',
              ),
              loading: () => const Text('Vérification...'),
              error: (_, __) => const Text('Erreur ping'),
            ),
            const SizedBox(height: 8),
            if (connectionState.lastUpdate != null)
              Text(
                'Dernière connexion: ${connectionState.lastUpdate}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

// EXEMPLE 2: Bouton pour reconnecter
class ReconnectButton extends ConsumerWidget {
  const ReconnectButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        await ref.read(esp32ConnectionProvider.notifier).reconnectWithSavedIP();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconnexion en cours...')),
        );
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Reconnecter'),
    );
  }
}

// EXEMPLE 3: Initialiser la connexion au démarrage
class AppInitializer extends ConsumerWidget {
  final Widget child;

  const AppInitializer({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Au démarrage, charger la connexion sauvegardée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(esp32ConnectionProvider.notifier).reconnectWithSavedIP();
    });

    return child;
  }
}

// ============================================================
// INTÉGRATION DANS MAIN.DART
// ============================================================

/*
Mettre à jour votre main() ainsi:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optionnel: pré-initialiser SharedPreferences
  await SharedPreferences.getInstance();
  
  runApp(
    const ProviderScope(
      child: AppInitializer(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
*/

// ============================================================
// RÉSUMÉ DES CHANGEMENTS
// ============================================================

/*
✅ Importer esp32_ip_provider.dart
✅ Passer ref à ESP32ConnectionNotifier
✅ Ajouter _loadSavedIP() dans le constructor
✅ Modifier connectToESP32() pour sauvegarder l'IP
✅ Ajouter des utilitaires (URL, ping, etc.)
✅ Utiliser AppInitializer au démarrage

Cela permet:
- Persistance de l'IP entre les sessions
- Reconnexion automatique
- Pas de besoin de re-configurer l'IP à chaque démarrage
*/
