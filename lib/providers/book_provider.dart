import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book.dart';
import 'supabase_provider.dart';

final bookListProvider = StreamProvider.autoDispose.family<List<Book>, String>((
  ref,
  userId,
) {
  final supabase = ref.watch(supabaseProvider);

  final refresh = StreamController<void>();

  void reload() {
    if (!refresh.isClosed) refresh.add(null);
  }

  final channel = supabase
      .channel('books:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'books',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'owner_id',
          value: userId,
        ),
        callback: (_) => reload(),
      )
      .subscribe((status, _) {
        if (status == RealtimeSubscribeStatus.subscribed) reload();
      });
  ref.onDispose(() {
    unawaited(refresh.close());
    unawaited(supabase.removeChannel(channel));
  });

  reload();
  // Realtime pide otra consulta. PostgreSQL devuelve una sola fila por libro.
  return refresh.stream.asyncMap((_) async {
    final rows = await supabase
        .from('books')
        .select()
        .eq('owner_id', userId)
        .order('title', ascending: true);
    return rows.map(Book.fromMap).toList();
  });
});

final bookProvider = Provider.autoDispose
    .family<AsyncValue<Book?>, ({String userId, String bookId})>((ref, ids) {
      // El detalle usa el mismo listado en tiempo real que la pantalla principal.
      return ref.watch(bookListProvider(ids.userId)).whenData((books) {
        for (final book in books) {
          if (book.id == ids.bookId) return book;
        }
        return null;
      });
    });

final bookActionsProvider = AsyncNotifierProvider<BookActions, void>(
  BookActions.new,
);

class BookActions extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> add(Book book) {
    return _write((supabase, userId) async {
      // PostgreSQL genera el UUID y toma el dueño de la sesión autenticada.
      await supabase.from('books').insert(book.toMap());
    });
  }

  Future<void> updateBook(Book book) {
    return _write((supabase, userId) async {
      final updated = await supabase
          .from('books')
          .update(book.toMap())
          .eq('id', book.id)
          .eq('owner_id', userId)
          .select('id')
          .maybeSingle();
      if (updated == null) throw const _BookNotFound();
    });
  }

  Future<void> delete(String bookId) {
    return _write((supabase, userId) async {
      await supabase
          .from('books')
          .delete()
          .eq('id', bookId)
          .eq('owner_id', userId);
    });
  }

  Future<void> _write(
    Future<void> Function(SupabaseClient supabase, String userId) action,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw StateError('No hay una sesión activa.');
      }

      await action(supabase, user.id);
      // Vuelve a consultar después de guardar, incluso si Realtime se desconectó.
      ref.invalidate(bookListProvider(user.id));
    });
  }
}

class _BookNotFound implements Exception {
  const _BookNotFound();
}

String bookErrorMessage(Object error, String operation) {
  if (error is _BookNotFound) {
    return 'Este libro ya no está en la biblioteca.';
  }
  if (error is PostgrestException) {
    return switch (error.code) {
      '42501' => 'Supabase rechazó el acceso a la biblioteca.',
      '23514' => 'Revisá los datos del libro y volvé a intentar.',
      _ => 'No se pudo $operation. Volvé a intentar.',
    };
  }
  return 'No se pudo $operation. Volvé a intentar.';
}
