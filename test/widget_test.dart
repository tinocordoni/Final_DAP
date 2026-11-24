import 'dart:async';

import 'package:final_dap/main.dart';
import 'package:final_dap/models/book.dart';
import 'package:final_dap/providers/auth_provider.dart';
import 'package:final_dap/providers/book_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'el registro valida la contraseña y avisa si falta confirmar el email',
    (tester) async {
      final sessions = StreamController<User?>.broadcast();
      final actions = _RegistrationActions();
      addTearDown(sessions.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith((ref) => sessions.stream),
            authActionsProvider.overrideWith(() => actions),
            bookListProvider.overrideWith((ref, userId) => Stream.value([])),
          ],
          child: const LibraryApp(),
        ),
      );
      sessions.add(null);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final passwordInput = find.descendant(
        of: fields.at(2),
        matching: find.byType(EditableText),
      );
      final confirmationInput = find.descendant(
        of: fields.at(3),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(passwordInput).obscureText, true);
      expect(tester.widget<EditableText>(confirmationInput).obscureText, true);

      final showConfirmation = find.byTooltip(
        'Mostrar confirmación de contraseña',
      );
      await tester.ensureVisible(showConfirmation);
      await tester.tap(showConfirmation);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(passwordInput).obscureText, true);
      expect(tester.widget<EditableText>(confirmationInput).obscureText, false);

      await tester.tap(find.byTooltip('Ocultar confirmación de contraseña'));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(confirmationInput).obscureText, true);
      await tester.enterText(fields.at(0), 'Ana');
      await tester.enterText(fields.at(1), 'ana@example.com');
      await tester.enterText(fields.at(2), 'secreta123');
      await tester.enterText(fields.at(3), 'diferente');
      final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

      await tester.enterText(fields.at(3), 'secreta123');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Revisá tu correo. Confirmá tu email para iniciar sesión.'),
        findsOneWidget,
      );
      expect(find.text('Hola, Ana'), findsNothing);

      final loginLink = find.text('Ir a iniciar sesión');
      await tester.ensureVisible(loginLink);
      await tester.tap(loginLink);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FilledButton, 'Iniciar sesión'),
        findsOneWidget,
      );
      sessions.add(_testUser('Ana'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
    },
  );

  testWidgets('el detalle y el listado reflejan cambios en el mismo libro', (
    tester,
  ) async {
    const id = 'book-123';
    final books = StreamController<List<Book>>.broadcast();
    addTearDown(books.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => Stream.value(_testUser('Ana'))),
          bookListProvider.overrideWith((ref, userId) => books.stream),
        ],
        child: const LibraryApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    books.add([_book(id, 'Título original')]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Título original'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del libro'), findsOneWidget);

    books.add([_book(id, 'Título editado')]);
    await tester.pumpAndSettle();
    expect(find.text('Título editado'), findsOneWidget);
    expect(find.text('ID: $id'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Título editado'), findsOneWidget);

    books.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Título editado'), findsNothing);
  });
}

Book _book(String id, String title) => Book(
  id: id,
  title: title,
  author: 'Autor',
  year: 2026,
  description: 'Descripción',
  coverUrl: 'https://example.com/cover.jpg',
);

class _RegistrationActions extends AuthActions {
  @override
  Future<bool> register(String name, String email, String password) async {
    return true;
  }
}

User _testUser(String name) {
  return User(
    id: 'test-user',
    appMetadata: const {},
    userMetadata: {'display_name': name},
    aud: 'authenticated',
    createdAt: '2026-11-24T00:00:00Z',
  );
}
