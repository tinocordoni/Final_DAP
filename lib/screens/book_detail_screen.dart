import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../widgets/book_cover.dart';
import '../widgets/screen_message.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const Scaffold();

    final selectedBook = ref.watch(
      bookProvider((userId: user.uid, bookId: bookId)),
    );
    final busy = ref.watch(bookActionsProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del libro')),
      body: selectedBook.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ScreenMessage(
          bookErrorMessage(error, 'cargar el libro'),
          onRetry: () => ref.invalidate(bookListProvider(user.uid)),
        ),
        data: (book) {
          if (book == null) {
            return const ScreenMessage(
              'Este libro ya no está en la biblioteca.',
            );
          }
          final textTheme = Theme.of(context).textTheme;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: BookCover(
                        url: book.coverUrl,
                        width: 156,
                        height: 222,
                        showErrorMessage: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(book.title, style: textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Autor: ${book.author}'),
                    Text('Año de publicación: ${book.year}'),
                    const SizedBox(height: 20),
                    Text('Descripción', style: textTheme.titleMedium),
                    Text(book.description),
                    const SizedBox(height: 16),
                    SelectableText(
                      'ID: ${book.id}',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    if (busy) const LinearProgressIndicator(),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: busy
                              ? null
                              : () => context.go('/books/$bookId/edit'),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => _delete(context, ref, book),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Querés eliminar «${book.title}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(bookActionsProvider.notifier).delete(book.id);
    if (!context.mounted) return;

    final error = ref.read(bookActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookErrorMessage(error, 'eliminar el libro'))),
      );
      return;
    }
    context.pop();
  }
}
