import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:final_dap/models/book.dart';
import 'package:final_dap/providers/book_provider.dart';
import 'package:final_dap/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('un alta que ya está en PostgreSQL aparece una sola vez', () async {
    final row = {
      'id': 'book-123',
      'title': 'Ficciones',
      'author': 'Jorge Luis Borges',
      'year': 1944,
      'description': 'Cuentos',
      'cover_url': 'https://example.com/cover.jpg',
    };
    final rows = [row];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(rows));
      await request.response.close();
    });

    final client = _TestSupabase('http://127.0.0.1:${server.port}');
    final container = ProviderContainer(
      overrides: [supabaseProvider.overrideWithValue(client)],
    );
    final updates = StreamController<List<Book>>();
    final results = StreamIterator(updates.stream);
    addTearDown(() async {
      container.dispose();
      await results.cancel();
      await updates.close();
      await client.dispose();
      await server.close(force: true);
    });

    container.listen(bookListProvider('test-user'), (_, next) {
      if (next case AsyncData(:final value)) updates.add(value);
    });

    Future<List<String>> nextBookIds() async {
      expect(
        await results.moveNext().timeout(const Duration(seconds: 5)),
        true,
      );
      return results.current.map((book) => book.id).toList();
    }

    // La consulta ya devolvió el libro cuando llega su evento de alta.
    expect(await nextBookIds(), ['book-123']);
    final book = results.current.single;
    expect(book.coverUrl, row['cover_url']);
    expect(book.toMap()['cover_url'], row['cover_url']);
    client.testChannel.emit(PostgresChangeEvent.insert, row);
    expect(await nextBookIds(), ['book-123']);

    rows.clear();
    client.testChannel.emit(PostgresChangeEvent.delete, row);
    expect(await nextBookIds(), isEmpty);
  });
}

class _TestSupabase extends SupabaseClient {
  _TestSupabase(String url) : super(url, 'test-publishable-key');

  final testChannel = _TestChannel();

  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) => testChannel;

  @override
  Future<String> removeChannel(RealtimeChannel channel) async => 'ok';
}

class _TestChannel extends Fake implements RealtimeChannel {
  late void Function(PostgresChangePayload) _onChange;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload) callback,
  }) {
    _onChange = callback;
    return this;
  }

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus, Object?)? callback,
    Duration? timeout,
  ]) => this;

  void emit(PostgresChangeEvent event, Map<String, dynamic> row) {
    _onChange(
      PostgresChangePayload(
        schema: 'public',
        table: 'books',
        commitTimestamp: DateTime.now(),
        eventType: event,
        newRecord: event == PostgresChangeEvent.insert ? row : {},
        oldRecord: event == PostgresChangeEvent.delete ? row : {},
        errors: null,
      ),
    );
  }
}
