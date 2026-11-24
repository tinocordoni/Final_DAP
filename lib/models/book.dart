class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.description,
    required this.coverUrl,
  });

  final String id;
  final String title;
  final String author;
  final int year;
  final String description;
  final String coverUrl;

  factory Book.fromMap(Map<String, dynamic> data) {
    return Book(
      id: data['id'] as String,
      title: data['title'] as String,
      author: data['author'] as String,
      year: data['year'] as int,
      description: data['description'] as String,
      coverUrl: data['cover_url'] as String,
    );
  }

  // El ID y el dueño los asigna PostgreSQL al crear la fila.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'year': year,
      'description': description,
      'cover_url': coverUrl,
    };
  }
}
