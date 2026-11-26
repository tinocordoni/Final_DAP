import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/form_validators.dart';

enum AuthMode { login, register, completeProfile }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});

  final AuthMode mode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    final actions = ref.read(authActionsProvider.notifier);
    await switch (widget.mode) {
      AuthMode.login => actions.signIn(_email.text.trim(), _password.text),
      AuthMode.register => actions.register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      ),
      AuthMode.completeProfile => actions.completeProfile(_name.text.trim()),
    };

    // El router abre la biblioteca cuando Firebase informa una sesión válida.
    if (!mounted) return;
    final error = ref.read(authActionsProvider).error;
    if (error != null) setState(() => _error = authErrorMessage(error));
  }

  Future<void> _signOut() async {
    setState(() => _error = null);
    await ref.read(authActionsProvider.notifier).signOut();
    if (!mounted) return;
    final error = ref.read(authActionsProvider).error;
    if (error != null) setState(() => _error = authErrorMessage(error));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authActionsProvider);
    final busy = authState.isLoading;
    final login = widget.mode == AuthMode.login;
    final register = widget.mode == AuthMode.register;
    final completeProfile = widget.mode == AuthMode.completeProfile;
    final title = switch (widget.mode) {
      AuthMode.login => 'Iniciar sesión',
      AuthMode.register => 'Crear cuenta',
      AuthMode.completeProfile => 'Completar perfil',
    };
    final profileError = authState.error;
    final message =
        _error ??
        (completeProfile && profileError is ProfileSaveException
            ? authErrorMessage(profileError)
            : null);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi biblioteca')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      if (!login)
                        TextFormField(
                          controller: _name,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: completeProfile
                              ? TextInputAction.done
                              : TextInputAction.next,
                          validator: requiredField,
                        ),
                      if (!completeProfile) ...[
                        TextFormField(
                          controller: _email,
                          enabled: !busy,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          validator: emailValidator,
                        ),
                        TextFormField(
                          controller: _password,
                          enabled: !busy,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            suffixIcon: _visibilityButton(
                              hidden: _hidePassword,
                              field: 'contraseña',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                            ),
                          ),
                          obscureText: _hidePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: login
                              ? TextInputAction.done
                              : TextInputAction.next,
                          validator: requiredField,
                        ),
                      ],
                      if (register)
                        TextFormField(
                          controller: _confirmation,
                          enabled: !busy,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            suffixIcon: _visibilityButton(
                              hidden: _hideConfirmation,
                              field: 'confirmación de contraseña',
                              onPressed: () => setState(
                                () => _hideConfirmation = !_hideConfirmation,
                              ),
                            ),
                          ),
                          obscureText: _hideConfirmation,
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (value) {
                            final error = requiredField(value);
                            if (error != null) return error;
                            if (value != _password.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                      if (message != null)
                        Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),

                      if (busy) const LinearProgressIndicator(),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        child: Text(completeProfile ? 'Guardar nombre' : title),
                      ),
                      if (login)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => context.go('/register'),
                          child: const Text('Crear cuenta'),
                        ),

                      if (completeProfile)
                        TextButton(
                          onPressed: busy ? null : _signOut,
                          child: const Text('Cerrar sesión'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconButton _visibilityButton({
    required bool hidden,
    required String field,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: '${hidden ? 'Mostrar' : 'Ocultar'} $field',
      onPressed: onPressed,
      icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
    );
  }
}
