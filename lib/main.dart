import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final app = await _initializeFirebase();
    runApp(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(
            FirebaseAuth.instanceFor(app: app),
          ),
          firestoreProvider.overrideWithValue(
            FirebaseFirestore.instanceFor(app: app),
          ),
        ],
        child: const LibraryApp(),
      ),
    );
  } on UnsupportedError {
    runApp(
      const _StartupError(
        message: 'Abrí Mi biblioteca en Android, iOS o Chrome.',
      ),
    );
  } catch (error) {
    debugPrint('Error al inicializar Firebase: $error');
    runApp(
      const _StartupError(
        message:
            'No se pudo iniciar Firebase. Revisá la configuración y volvé a abrir la app.',
      ),
    );
  }
}

Future<FirebaseApp> _initializeFirebase() async {
  const useEmulators =
      kDebugMode && bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  if (!useEmulators) {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // El emulador de Android usa 10.0.2.2 para acceder a la computadora.
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
  final app = await Firebase.initializeApp(demoProjectId: 'demo-final-dap');
  await FirebaseAuth.instanceFor(app: app).useAuthEmulator(host, 9099);
  final firestore = FirebaseFirestore.instanceFor(app: app);
  firestore.settings = const Settings(persistenceEnabled: false);
  firestore.useFirestoreEmulator(host, 8080);
  return app;
}

class LibraryApp extends ConsumerWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mi biblioteca',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA35F24)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Mi biblioteca')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
