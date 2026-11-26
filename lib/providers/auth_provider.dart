import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final sessionProvider = StreamProvider<User?>((ref) {
  // Firebase emite la sesión restaurada y los cambios de perfil, ingreso y salida.
  return ref.watch(firebaseAuthProvider).userChanges();
});

final authActionsProvider = AsyncNotifierProvider<AuthActions, void>(
  AuthActions.new,
);

class AuthActions extends AsyncNotifier<void> {
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  @override
  void build() {}

  Future<void> signIn(String email, String password) {
    return _run(() async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    });
  }

  Future<void> register(String name, String email, String password) {
    return _run(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // El nombre vive en el perfil de Firebase Authentication.
      try {
        await credential.user!.updateDisplayName(name);
      } on FirebaseAuthException catch (error) {
        throw ProfileSaveException(error);
      }
    });
  }

  Future<void> completeProfile(String name) {
    return _run(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw StateError('No hay una sesión activa.');
      }
      await user.updateDisplayName(name);
    });
  }

  Future<void> signOut() => _run(_auth.signOut);

  // AsyncValue permite deshabilitar los botones y mostrar errores de Firebase.
  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}

class ProfileSaveException implements Exception {
  const ProfileSaveException(this.cause);

  final FirebaseAuthException cause;
}

String authErrorMessage(Object error) {
  if (error is ProfileSaveException) {
    return 'Tu cuenta se creó. No pudimos guardar el nombre. ${authErrorMessage(error.cause)}';
  }

  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Ingresá un email válido.',
      'email-already-in-use' => 'Ya existe una cuenta con ese email.',
      'weak-password' =>
        'Firebase rechazó la contraseña. Probá con una más segura.',
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'user-not-found' ||
      'wrong-password' => 'El email o la contraseña son incorrectos.',
      'user-disabled' => 'Esta cuenta está deshabilitada.',
      'network-request-failed' => 'Revisá tu conexión y volvé a intentar.',
      'too-many-requests' => 'Hubo demasiados intentos. Probá más tarde.',
      'operation-not-allowed' =>
        'El ingreso con email y contraseña está deshabilitado en Firebase.',
      _ => 'No se pudo completar la operación. Volvé a intentar.',
    };
  }

  return 'No se pudo completar la operación. Volvé a intentar.';
}
