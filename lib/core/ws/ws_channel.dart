import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// The narrow slice of a WebSocket that [WsClient] actually uses.
///
/// Introduced so the client depends on three methods rather than on
/// `package:web_socket_channel`'s full `StreamChannel` surface. That makes a
/// test double a dozen lines instead of a re-implementation of the whole
/// channel contract, and it means swapping the transport later (sockets over
/// a background isolate, say) touches one adapter.
abstract class WsChannel {
  Stream<dynamic> get stream;
  void send(String data);
  Future<void> close();
}

/// Real implementation, backed by `WebSocketChannel.connect`.
class RealWsChannel implements WsChannel {
  RealWsChannel(this._channel);

  factory RealWsChannel.connect(Uri uri) =>
      RealWsChannel(WebSocketChannel.connect(uri));

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close() => _channel.sink.close();
}
