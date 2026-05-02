# ✅ CHECKLIST D'INTÉGRATION DU PROVIDER ESP32 IP

## 📋 Fichiers Créés

- ✅ `lib/providers/esp32_ip_provider.dart` - Provider principal avec SharedPreferences
- ✅ `lib/screens/esp32_connection_screen.dart` - Écran de configuration
- ✅ `lib/providers/ESP32_PROVIDER_EXAMPLES.dart` - Exemples d'utilisation
- ✅ `lib/providers/INTEGRATION_GUIDE.dart` - Guide d'intégration complet
- ✅ `GUIDE_ESP32_PROVIDER.md` - Documentation détaillée

---

## 🔧 MODIFICATIONS À FAIRE

### 1. **PUBSPEC.YAML** ✏️

**Vérifier que vous avez:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  shared_preferences: ^2.2.0  # ← VÉRIFIER QUE C'EST AJOUTÉ
  http: ^1.2.0
  # ... autres dépendances
```

**Puis exécuter:**
```bash
flutter pub get
```

---

### 2. **lib/main.dart** ✏️

Mettez à jour votre fichier `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pré-initialiser SharedPreferences (optionnel mais recommandé)
  await SharedPreferences.getInstance();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

### 3. **lib/providers/app_providers.dart** ✏️

Ajoutez cette ligne EN HAUT du fichier:

```dart
// ============================================================
// IMPORTS
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wifi_tcp_service.dart';
import '../models/threshold_settings.dart';
import '../models/patient_profile.dart';
import '../models/alert_event.dart';
import '../models/fall_detection_data.dart';
import 'esp32_ip_provider.dart';  // ← AJOUTER CETTE LIGNE
```

**Puis modifiez la classe `ESP32ConnectionNotifier`:**

```dart
class ESP32ConnectionNotifier extends StateNotifier<ESP32ConnectionState> {
  final WifiTcpService wifiService;
  final Ref ref;  // ← AJOUTER CETTE LIGNE

  ESP32ConnectionNotifier(this.wifiService, this.ref)   // ← MODIFIER LA SIGNATURE
      : super(ESP32ConnectionState());

  // ... autres méthodes existantes ...

  // ✨ AJOUTER CETTE MÉTHODE ✨
  Future<void> connectToESP32(String ip, int port) async {
    state = state.copyWith(statusMessage: 'Connexion en cours...');
    
    final success = await wifiService.connectToESP32(ip, port: port);
    
    if (success) {
      // 🎯 SAUVEGARDER L'IP ET LE PORT
      await ref.read(esp32SettingsProvider.notifier).saveIPAddress(ip);
      await ref.read(esp32SettingsProvider.notifier).savePort(port);
      await ref.read(esp32SettingsProvider.notifier).updateLastConnectedTime();

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

  // ✨ AJOUTER CETTE MÉTHODE UTILE ✨
  String getESP32URL() {
    return 'http://${state.ipAddress}:${state.port}';
  }
}
```

**Puis modifiez le provider lui-même:**

```dart
// AVANT:
// final esp32ConnectionProvider = 
//     StateNotifierProvider<ESP32ConnectionNotifier, ESP32ConnectionState>((ref) {
//   final wifiService = ref.watch(wifiServiceProvider);
//   return ESP32ConnectionNotifier(wifiService);  // ← SANS REF
// });

// APRÈS:
final esp32ConnectionProvider = 
    StateNotifierProvider<ESP32ConnectionNotifier, ESP32ConnectionState>((ref) {
  final wifiService = ref.watch(wifiServiceProvider);
  return ESP32ConnectionNotifier(wifiService, ref);  // ← AVEC REF
});
```

---

### 4. **Ajouter le lien vers l'écran de Configuration** ✏️

**Dans votre Settings Screen ou AppBar:**

```dart
// Option A: Via un bouton dans l'AppBar
AppBar(
  title: const Text('Health Monitor'),
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

// Option B: Via un ListTile dans Settings
ListTile(
  leading: const Icon(Icons.router),
  title: const Text('Configuration ESP32'),
  subtitle: const Text('IP et port de connexion'),
  trailing: const Icon(Icons.arrow_forward),
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

## 🎯 UTILISATION RAPIDE

### **A. Afficher l'IP dans un Widget:**

```dart
class IPWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(esp32SettingsProvider);
    
    return settings.when(
      data: (s) => Text('IP: ${s.ipAddress}:${s.port}'),
      loading: () => const Text('Chargement...'),
      error: (e, _) => Text('Erreur: $e'),
    );
  }
}
```

### **B. Utiliser l'IP dans un Service:**

```dart
Future<void> fetchData(WidgetRef ref) async {
  final settings = ref.watch(esp32SettingsProvider);
  
  settings.whenData((s) async {
    final url = Uri.http('${s.ipAddress}:${s.port}', '/sensors');
    final response = await http.get(url);
    // ...
  });
}
```

### **C. Sauvegarder une nouvelle IP:**

```dart
await ref.read(esp32SettingsProvider.notifier)
    .saveIPAddress('192.168.39.105');
```

---

## ✨ NOUVEAUTÉS

| Avant | Après |
|-------|-------|
| IP codée en dur | IP sauvegardée automatiquement |
| Reconfiguré à chaque démarrage | Mémorisation entre sessions |
| IP non partagée facilement | Provider Riverpod accessible partout |
| Pas de UI de configuration | Écran complet + interface intuitive |
| Port fixe | Port configurable aussi |

---

## 🧪 TESTER

### Test 1: Entrer l'IP de votre ESP32

```
1. Allez dans Settings → Configuration ESP32
2. Entrez IP: 192.168.39.105 (votre IP)
3. Port: 80
4. Cliquez "Sauvegarder"
5. Vérifiez que ✅ s'affiche
```

### Test 2: Vérifier la Persistance

```
1. Entrez l'IP comme ci-dessus
2. Fermez l'app complètement
3. Relancez l'app
4. L'IP doit être toujours affichée
```

### Test 3: Utiliser l'IP dans un Widget

```dart
// Dans n'importe quel ConsumerWidget:
final settings = ref.watch(esp32SettingsProvider);

settings.when(
  data: (s) => print('IP sauvegardée: ${s.ipAddress}'),
  loading: () => print('Chargement'),
  error: (e, _) => print('Erreur'),
);
```

---

## ❌ ERREURS COURANTES

### ❌ Erreur: "esp32_ip_provider not found"

**Solution:**
```dart
// Vérifier que l'import existe en haut de app_providers.dart:
import 'esp32_ip_provider.dart';
```

### ❌ Erreur: "SharedPreferences not initialized"

**Solution:**
```dart
// Dans main.dart, ajouter:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(...);
}
```

### ❌ Erreur: "Ref not provided to Notifier"

**Solution:**
```dart
// S'assurer que ESP32ConnectionNotifier reçoit le ref:
ESP32ConnectionNotifier(wifiService, ref);  // ← ref doit être là
```

### ❌ L'IP n'est pas sauvegardée

**Vérifier:**
```dart
// 1. Que saveIPAddress est appelé:
await ref.read(esp32SettingsProvider.notifier)
    .saveIPAddress('192.168.39.105');

// 2. Que SharedPreferences a les permissions
// 3. Que l'appareil n'est pas en lecture seule
```

---

## 📱 FLUX UTILISATEUR COMPLET

```
Démarrage App
    ↓
Main charge les providers
    ↓
esp32SettingsProvider charge IP sauvegardée
    ↓
L'IP est disponible partout dans l'app
    ↓
Utilisateur clique sur Settings
    ↓
Affiche ESP32ConnectionScreen
    ↓
Utilisateur entre nouvelle IP → Clique Sauvegarder
    ↓
SharedPreferences sauvegarde l'IP
    ↓
Provider notifie tous les widgets
    ↓
Tous les widgets se mettent à jour
    ↓
Retour aux autres pages
    ↓
L'IP persiste jusqu'à la prochaine modification
```

---

## 🎓 RESSOURCES

- **Riverpod Docs:** https://riverpod.dev
- **SharedPreferences:** https://pub.dev/packages/shared_preferences
- **Flutter Patterns:** https://codewithandrea.com/articles/flutter-state-management-riverpod/

---

## 📞 SUPPORT

Si vous avez des problèmes:

1. **Vérifier les imports** - S'assurer que tous les fichiers sont importés
2. **Exécuter `flutter pub get`** - Pour mettre à jour les dépendances
3. **Nettoyer le build** - `flutter clean && flutter pub get`
4. **Vérifier la structure** - Les fichiers doivent être dans `lib/providers/` et `lib/screens/`

---

## 🎉 C'est tout!

Vous avez maintenant:
✅ Provider pour l'IP persistante
✅ SharedPreferences intégré
✅ Écran de configuration
✅ Exemples d'utilisation
✅ Integration avec votre système existant

**Prochaines étapes:**
→ Intégrer dans votre Dashboard
→ Ajouter la détection automatique d'IP (optionnel)
→ Tester avec votre ESP32 réel
