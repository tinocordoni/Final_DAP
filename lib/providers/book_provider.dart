import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import 'auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final _bookCollectionProvider = Provider.autoDispose
    .family<CollectionReference<Map<String, dynamic>>, String>((ref, userId) {
      // Cada usuario tiene su propia subcolección de libros en Firestore.
      return ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(userId)
          .collection('books');
    });

final bookListProvider = StreamProvider.autoDispose.family<List<Book>, String>((
  ref,
  userId,
) {
  final collection = ref.watch(_bookCollectionProvider(userId));

  // snapshots emite el listado inicial y vuelve a emitir después de cada cambio.
  return collection.orderBy('title').snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => Book.fromMap(doc.id, doc.data()))
        .toList();
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
    return _write((collection) async {
      // add genera el ID del documento automáticamente.
      await collection.add(book.toMap());
    });
  }

  Future<void> updateBook(Book book) {
    return _write((collection) => collection.doc(book.id).update(book.toMap()));
  }

  Future<void> delete(String bookId) {
    return _write((collection) => collection.doc(bookId).delete());
  }

  Future<void> _write(
    Future<void> Function(CollectionReference<Map<String, dynamic>>) action,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw StateError('No hay una sesión activa.');
      }
      await action(ref.read(_bookCollectionProvider(user.uid)));
    });
  }
}

String bookErrorMessage(Object error, String operation) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Firestore rechazó el acceso. Revisá la sesión y las reglas de la base.',
      'unavailable' =>
        'Firestore no está disponible. Revisá tu conexión y volvé a intentar.',
      'not-found' => 'Este libro ya no está en la biblioteca.',
      _ => 'No se pudo $operation. Volvé a intentar.',
    };
  }
  return 'No se pudo $operation. Volvé a intentar.';
}
