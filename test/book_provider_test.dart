import 'package:final_dap/models/book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la portada se conserva al leer y escribir un documento', () {
    const data = {
      'title': 'Ficciones',
      'author': 'Jorge Luis Borges',
      'year': 1944,
      'description': 'Cuentos',
      'coverUrl': 'https://example.com/cover.jpg',
    };
    final book = Book.fromMap('book-123', data);
    expect(book.id, 'book-123');
    expect(book.toMap(), data);
  });
}
