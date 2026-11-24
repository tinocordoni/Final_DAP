import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.showErrorMessage = false,
  });

  final String url;
  final double width;
  final double height;
  final bool showErrorMessage;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surfaceContainerHighest;
    const errorMessage = 'No se pudo cargar la portada.';
    final placeholder = ColoredBox(
      color: background,
      child: const Center(child: Icon(Icons.menu_book_outlined)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          // En web, permite mostrar portadas de servidores que no habilitan CORS.
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          semanticLabel: 'Portada del libro',
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return wasSynchronouslyLoaded || frame != null
                ? child
                : placeholder;
          },
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: background,
            child: Center(
              child: showErrorMessage
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(errorMessage, textAlign: TextAlign.center),
                    )
                  : const Icon(
                      Icons.broken_image_outlined,
                      semanticLabel: errorMessage,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
