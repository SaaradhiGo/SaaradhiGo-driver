import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

class TestWebSocketChannel implements WebSocketChannel {
  TestWebSocketChannel({Future<void>? ready})
    : _ready = ready ?? Future<void>.value(),
      sink = TestWebSocketSink();

  final StreamController<Object?> incoming =
      StreamController<Object?>.broadcast();
  final Future<void> _ready;

  @override
  final TestWebSocketSink sink;

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  String? protocol;

  @override
  Future<void> get ready => _ready;

  @override
  Stream<Object?> get stream => incoming.stream;

  Future<void> closeIncoming([int? code]) async {
    closeCode = code;
    await incoming.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestWebSocketSink implements WebSocketSink {
  final List<Object?> sent = [];
  final Completer<void> _done = Completer<void>();
  bool closed = false;
  int? closeCode;

  @override
  void add(Object? data) => sent.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final item in stream) {
      add(item);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    this.closeCode = closeCode;
    closed = true;
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> get done => _done.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
