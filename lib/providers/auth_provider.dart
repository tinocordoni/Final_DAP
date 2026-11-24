import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

final sessionProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(supabaseProvider).auth;

  // Supabase restaura la sesión al iniciar y emite los cambios de Auth.
  return auth.onAuthStateChange.map((change) => change.session?.user);
});

String? userDisplayName(User user) {
  final name = user.userMetadata?['display_name'];
  return name is String && name.trim().isNotEmpty ? name.trim() : null;
}

final authActionsProvider = AsyncNotifierProvider<AuthActions, void>(
  AuthActions.new,
);

class AuthActions extends AsyncNotifier<void> {
  GoTrueClient get _auth => ref.read(supabaseProvider).auth;

  @override
  void build() {}

  Future<void> signIn(String email, String password) {
    return _run(() async {
      await _auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<bool> register(String name, String email, String password) async {
    var needsEmailConfirmation = false;

    await _run(() async {
      final response = await _auth.signUp(
        email: email,
        password: password,
        // Supabase guarda el nombre en el perfil al crear la cuenta.
        data: {'display_name': name},
        emailRedirectTo: kIsWeb
            ? Uri.base.removeFragment().toString()
            : 'ar.edu.ort.finaldap://auth-callback/',
      );
      needsEmailConfirmation = response.session == null;
    });

    return needsEmailConfirmation;
  }

  Future<void> completeProfile(String name) {
    return _run(() async {
      await _auth.updateUser(UserAttributes(data: {'display_name': name}));
    });
  }

  Future<void> signOut() {
    return _run(() => _auth.signOut(scope: SignOutScope.local));
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}

String authErrorMessage(Object error) {
  if (error is AuthRetryableFetchException) {
    return 'Revisá tu conexión y volvé a intentar.';
  }

  if (error is AuthException) {
    return switch (error.code) {
      'email_address_invalid' ||
      'validation_failed' => 'Revisá los datos ingresados.',
      'email_exists' ||
      'user_already_exists' => 'Ya existe una cuenta con ese email.',
      'weak_password' => 'Probá con una contraseña más segura.',
      'invalid_credentials' => 'El email o la contraseña son incorrectos.',
      'email_not_confirmed' => 'Confirmá tu email antes de iniciar sesión.',
      'email_address_not_authorized' =>
        'Este proyecto todavía no puede enviar correos de confirmación a esa dirección.',
      'user_banned' => 'Esta cuenta está deshabilitada.',
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' => 'Hubo demasiados intentos. Probá más tarde.',
      'email_provider_disabled' || 'signup_disabled' =>
        'El registro con email está deshabilitado en Supabase.',
      _ => 'No se pudo completar la operación. Volvé a intentar.',
    };
  }

  return 'No se pudo completar la operación. Volvé a intentar.';
}
