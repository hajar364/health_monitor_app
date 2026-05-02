# 🔌 Guide d'Intégration du Provider ESP32 IP

## 📋 Résumé

Vous avez maintenant un système complet de gestion d'IP pour l'ESP32 avec:
- ✅ Sauvegarde persistante avec SharedPreferences
- ✅ Provider Riverpod pour accès facile
- ✅ Écran de configuration complet
- ✅ Exemples d'utilisation

---

## 🚀 Étapes d'Intégration

### 1️⃣ Installer les dépendances

```bash
flutter pub get
```

**Ou**, si vous êtes dans VS Code:
```
Ctrl+Shift+P > Flutter: Get Packages
```

---

### 2️⃣ Importer le Provider dans votre app

Dans `lib/main.dart`, mettez à jour vos imports:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/providers/esp32_ip_provider.dart';
```

Assurez-vous que votre app utilise `ProviderScope`:

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

### 3️⃣ Ajouter l'écran de configuration à votre Navigation

**Option A: Via l'AppBar Settings Button**

```dart
AppBar(
  actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ESP32ConnectionScreen(),
          ),
        );
      },
    ),
  ],
)
```

**Option B: Via Menu ou Settings Page**

```dart
ListTile(
  leading: const Icon(Icons.router),
  title: const Text('Configuration ESP32'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ESP32ConnectionScreen(),
      ),
    );
  },
)
```

---

## 📱 Utilisation dans vos Pages

### 📌 Cas 1: Afficher l'IP dans un Dashboard

```dart
class MyDashboard extends ConsumerWidget {
  const MyDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(esp32SettingsProvider);

    return settingsAsync.when(
      data: (settings) => Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: ListTile(
            title: const Text('ESP32 Connecté'),
            subtitle: Text('${settings.ipAddress}:${settings.port}'),
            leading: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Erreur: $error'),
    );
  }
}
```

---

### 📌 Cas 2: Utiliser l'IP dans un Service HTTP

```dart
class SensorService {
  final Ref ref;

  SensorService(this.ref);

  Future<Map<String, dynamic>> fetchSensors() async {
    final settingsAsync = ref.watch(esp32SettingsProvider);

    return settingsAsync.when(
      data: (settings) async {
        final url = Uri.http(
          settings.ipAddress,
          '/sensors',
          {'port': settings.port.toString()},
        );
        
        try {
          final response = await http.get(url, timeout: Duration(seconds: 5));
          if (response.statusCode == 200) {
            return jsonDecode(response.body);
          } else {
            throw Exception('Erreur HTTP: ${response.statusCode}');
          }
        } catch (e) {
          throw Exception('Erreur réseau: $e');
        }
      },
      loading: () => throw Exception('Paramètres en cours de chargement'),
      error: (error, _) => throw Exception('Erreur: $error'),
    );
  }
}

// Utilisation dans un Provider Riverpod:
final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService(ref);
});

final sensorsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(sensorServiceProvider);
  return service.fetchSensors();
});
```

---

### 📌 Cas 3: Sauvegarder l'IP après une Connexion

```dart
Future<void> connectToESP32(String ip, int port, WidgetRef ref) async {
  try {
    // Tenter la connexion
    final url = Uri.http(ip, '/ping', {'port': port.toString()});
    final response = await http.get(url, timeout: Duration(seconds: 5));

    if (response.statusCode == 200) {
      // Connexion réussie - sauvegarder l'IP
      await ref.read(esp32SettingsProvider.notifier).saveIPAddress(ip);
      await ref.read(esp32SettingsProvider.notifier).savePort(port);
      
      // Mettre à jour l'heure de connexion
      await ref
          .read(esp32SettingsProvider.notifier)
          .updateLastConnectedTime();

      return 'Connecté avec succès ✅';
    } else {
      throw Exception('Pas de réponse du serveur');
    }
  } catch (e) {
    throw Exception('Erreur de connexion: $e');
  }
}
```

---

### 📌 Cas 4: Écouter les Changements d'IP

```dart
class IPChangeListener extends ConsumerWidget {
  const IPChangeListener({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écouter les changements
    ref.listen(esp32SettingsProvider, (previous, next) {
      next.whenData((settings) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('IP mise à jour: ${settings.ipAddress}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    });

    return const SizedBox();
  }
}
```

---

## 🔧 Intégration avec votre Code Existant

### Si vous utilisez déjà `ESP32ConnectionNotifier`

Mettez à jour votre `app_providers.dart`:

```dart
// Avant la classe ESP32ConnectionNotifier, ajouter:
import 'esp32_ip_provider.dart';

// Modifier la connexion pour utiliser les settings sauvegardés:
class ESP32ConnectionNotifier extends StateNotifier<ESP32ConnectionState> {
  final WifiTcpService wifiService;

  ESP32ConnectionNotifier(this.wifiService, Ref ref) 
      : super(ESP32ConnectionState());

  Future<void> connectToESP32(String ip, int port) async {
    state = state.copyWith(statusMessage: 'Connexion en cours...');
    
    final success = await wifiService.connectToESP32(ip, port: port);
    
    if (success) {
      // ✅ Sauvegarder les paramètres
      // await ref.read(esp32SettingsProvider.notifier).saveIPAddress(ip);
      
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
```

---

## 📊 Structure des Données Sauvegardées

Les données sont stockées dans SharedPreferences au format JSON:

```json
{
  "ipAddress": "192.168.39.105",
  "port": 80,
  "deviceName": "ESP32 Health Monitor",
  "lastConnectedAt": "2024-04-26T17:23:00.000",
  "rememberDevice": true
}
```

**Clés SharedPreferences utilisées:**
- `esp32_settings` - Objet complet des paramètres (JSON)
- `esp32_ip` - L'adresse IP seule (pour accès rapide)

---

## ⚠️ Gestion des Erreurs

### Erreur: "Device not found" en Web

Si vous testez en web et que l'IP n'est pas accessible:

```dart
// Ajouter un timeout
final response = await http.get(url).timeout(
  const Duration(seconds: 5),
  onTimeout: () => throw Exception('Timeout de connexion'),
);
```

### Erreur: SharedPreferences non initialisé

Assurez-vous que `SharedPreferences.getInstance()` est appelé dans `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optionnel: pré-initialiser SharedPreferences
  await SharedPreferences.getInstance();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 🎯 Prochaines Étapes

1. **Tester avec votre ESP32 réel**
   ```
   Entrez l'IP: 192.168.39.105 (selon votre écran)
   Port: 80
   Cliquez sur "Sauvegarder"
   ```

2. **Intégrer dans vos pages existantes**
   - Health Dashboard
   - Settings Screen
   - Device Discovery

3. **Ajouter la détection automatique (optionnel)**
   - Scanner WiFi pour trouver l'ESP32 automatiquement

---

## 📚 Fichiers Créés/Modifiés

| Fichier | Description |
|---------|-------------|
| `lib/providers/esp32_ip_provider.dart` | ✨ **NOUVEAU** - Provider principal |
| `lib/screens/esp32_connection_screen.dart` | ✨ **NOUVEAU** - Écran de configuration |
| `lib/providers/ESP32_PROVIDER_EXAMPLES.dart` | 📚 Exemples d'utilisation |
| `pubspec.yaml` | ⚙️ Ajouté `shared_preferences` |

---

## 🔐 Sécurité

Pour la production, considérez:
- Chiffrer l'IP stockée
- Ajouter une authentification
- Valider l'IP avant de la sauvegarder

```dart
// Exemple: validation avant sauvegarde
Future<bool> validateIPAndSave(String ip) async {
  if (!_isValidIP(ip)) return false;
  
  await ref.read(esp32SettingsProvider.notifier).saveIPAddress(ip);
  return true;
}

bool _isValidIP(String ip) {
  return RegExp(
    r'^(\d{1,3}\.){3}\d{1,3}$'
  ).hasMatch(ip);
}
```

---

## ✅ Checklist d'Intégration

- [ ] `flutter pub get` exécuté
- [ ] `SharedPreferences` ajouté à `pubspec.yaml`
- [ ] Provider importé dans `main.dart`
- [ ] `ProviderScope` enveloppe l'app
- [ ] Écran de configuration créé
- [ ] Navigation vers cet écran ajoutée
- [ ] Tests avec IP réelle de l'ESP32

---

**Questions?** Consultez les exemples dans `ESP32_PROVIDER_EXAMPLES.dart`
