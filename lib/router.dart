import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'widgets/screen_message.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouteRefresh();

  // Las rutas se reevalúan cuando cambia la sesión de Supabase.
  ref.listen(sessionProvider, (_, _) => refresh.update());

  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.uri.path;

      if (session.isLoading || session.hasError) {
        return path == '/session' ? null : '/session';
      }

      final user = session.value;
      if (user == null) {
        return path == '/' || path == '/register' ? null : '/';
      }

      if (userDisplayName(user) == null) {
        return path == '/profile' ? null : '/profile';
      }

      return path == '/books' || path.startsWith('/books/') ? null : '/books';
    },
    routes: [
      GoRoute(
        path: '/session',
        builder: (context, state) => const _SessionScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthScreen(mode: AuthMode.login),
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) =>
                const AuthScreen(mode: AuthMode.register),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const AuthScreen(mode: AuthMode.completeProfile),
      ),
      GoRoute(
        path: '/books',
        builder: (context, state) => const BookListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const BookFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                BookDetailScreen(bookId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    BookFormScreen(bookId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  ref.onDispose(refresh.dispose);
  return router;
});

class _RouteRefresh extends ChangeNotifier {
  void update() => notifyListeners();
}

class _SessionScreen extends ConsumerWidget {
  const _SessionScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi biblioteca')),
      body: session.hasError
          ? ScreenMessage(
              'No se pudo comprobar la sesión.',
              onRetry: () => ref.invalidate(sessionProvider),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
