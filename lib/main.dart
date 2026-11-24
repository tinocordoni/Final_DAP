import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La clave publicable se puede incluir en el cliente. PostgreSQL aplica RLS.
  // Para usar otro proyecto, pasá las dos variables con --dart-define-from-file.
  const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cmvqamiiqdvzwzhsssvx.supabase.co',
  );
  const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_qD0lTSnbEapNbNlByRUZDg_3SXp551t',
  );
  const hasCustomUrl = bool.hasEnvironment('SUPABASE_URL');
  const hasCustomKey = bool.hasEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (hasCustomUrl != hasCustomKey ||
      url.isEmpty ||
      !publishableKey.startsWith('sb_publishable_')) {
    runApp(
      const _StartupError(
        message:
            'Configurá la URL y la clave publicable de Supabase siguiendo el README.',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    runApp(const ProviderScope(child: LibraryApp()));
  } catch (error) {
    debugPrint('Error al inicializar Supabase: ${error.runtimeType}');
    runApp(
      const _StartupError(
        message:
            'No se pudo iniciar Supabase. Revisá la configuración y volvé a abrir la app.',
      ),
    );
  }
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
