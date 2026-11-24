import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../widgets/book_cover.dart';
import '../widgets/screen_message.dart';

class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const Scaffold();

    final booksState = ref.watch(bookListProvider(user.id));
    final authBusy = ref.watch(authActionsProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi biblioteca'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: authBusy ? null : () => _signOut(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: booksState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ScreenMessage(
          bookErrorMessage(error, 'cargar los libros'),
          onRetry: () => ref.invalidate(bookListProvider(user.id)),
        ),
        data: (books) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Hola, ${userDisplayName(user)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: books.isEmpty
                  ? const ScreenMessage(
                      'Tu biblioteca está vacía. Agregá tu primer libro.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: books.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Card(
                          child: ListTile(
                            minTileHeight: 76,
                            leading: BookCover(
                              url: book.coverUrl,
                              width: 40,
                              height: 54,
                            ),
                            title: Text(book.title),
                            subtitle: Text('${book.author} · ${book.year}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go('/books/${book.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: authBusy ? null : () => context.go('/books/new'),
        icon: const Icon(Icons.add),
        label: const Text('Agregar libro'),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authActionsProvider.notifier).signOut();
    if (!context.mounted) return;

    final error = ref.read(authActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }
}
