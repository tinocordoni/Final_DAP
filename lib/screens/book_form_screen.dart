import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../widgets/form_validators.dart';
import '../widgets/screen_message.dart';

class BookFormScreen extends ConsumerWidget {
  const BookFormScreen({super.key, this.bookId});

  final String? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = bookId;
    if (id == null) return const _BookForm();

    final user = ref.watch(sessionProvider).value;
    if (user == null) return const Scaffold();

    return ref
        .watch(bookProvider((userId: user.id, bookId: id)))
        .when(
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Editar libro')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Editar libro')),
            body: ScreenMessage(
              bookErrorMessage(error, 'cargar el libro'),
              onRetry: () => ref.invalidate(bookListProvider(user.id)),
            ),
          ),
          data: (book) => book == null
              ? Scaffold(
                  appBar: AppBar(title: const Text('Editar libro')),
                  body: const ScreenMessage(
                    'Este libro ya no está en la biblioteca.',
                  ),
                )
              : _BookForm(key: ValueKey(book.id), book: book),
        );
  }
}

class _BookForm extends ConsumerStatefulWidget {
  const _BookForm({super.key, this.book});

  final Book? book;

  @override
  ConsumerState<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends ConsumerState<_BookForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.book?.title);
  late final _author = TextEditingController(text: widget.book?.author);
  late final _year = TextEditingController(text: widget.book?.year.toString());
  late final _description = TextEditingController(
    text: widget.book?.description,
  );
  late final _coverUrl = TextEditingController(text: widget.book?.coverUrl);
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _year.dispose();
    _description.dispose();
    _coverUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (ref.read(bookActionsProvider).isLoading ||
        !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    final book = Book(
      id: widget.book?.id ?? '',
      title: _title.text.trim(),
      author: _author.text.trim(),
      year: int.parse(_year.text.trim()),
      description: _description.text.trim(),
      coverUrl: _coverUrl.text.trim(),
    );
    final actions = ref.read(bookActionsProvider.notifier);
    if (widget.book == null) {
      await actions.add(book);
    } else {
      await actions.updateBook(book);
    }

    if (!mounted) return;
    final error = ref.read(bookActionsProvider).error;
    if (error != null) {
      setState(() => _error = bookErrorMessage(error, 'guardar el libro'));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(bookActionsProvider).isLoading;
    final editing = widget.book != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar libro' : 'Agregar libro')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _title,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Título'),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    validator: requiredField,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _author,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Autor'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: requiredField,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _year,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Año de publicación',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: yearValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    validator: requiredField,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _coverUrl,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'URL de la portada',
                      hintText: 'https://…',
                      helperText: 'Usá el enlace directo a una imagen pública.',
                      helperMaxLines: 2,
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: coverUrlValidator,
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (busy) const LinearProgressIndicator(),
                  FilledButton(
                    onPressed: busy ? null : _save,
                    child: Text(editing ? 'Guardar cambios' : 'Guardar libro'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
