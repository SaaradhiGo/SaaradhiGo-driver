import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'ws_channel.dart';

/// Connection state, surfaced to the UI so a driver can see *why* they are
/// not getting rides. "Connecting…" is a very different message from
/// "You're offline".
enum WsStatus { idle, connecting, connected, reconnecting, closed }

/// A self-healing WebSocket.
///
/// Ride dispatch arrives over this socket, so a silent disconnect is a driver
/// sitting in traffic wondering why nobody is booking them. Everything here
/// exists to make a drop visible and temporary:
///
///   * exponential backoff with jitter, capped at [AppConfig.wsMaxBackoff]
///   * an app-level ping so a half-open TCP connection (extremely common when
///     moving between towers) is detected rather than trusted
///   * a fresh token on every reconnect, because access tokens live 15 minutes
///     and the socket outlives them
///   * a broadcast stream, so several controllers can watch one socket
class WsClient {
  WsClient({
    required this.path,
    required this.tokenProvider,
    this.pingInterval = const Duration(seconds: 25),
    this.connector = RealWsChannel.connect,
  });

  /// Builds the path (including a fresh `?token=`) for each connect attempt.
  final Future<String> Function() path;

  /// Used only to decide whether a reconnect is worth attempting.
  final Future<String?> Function() tokenProvider;

  final Duration pingInterval;

  /// Injectable so tests can supply a fake channel without a network.
  final WsChannel Function(Uri uri) connector;

  WsChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _attempt = 0;
  bool _disposed = false;
  bool _intentionallyClosed = false;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<WsStatus>.broadcast();

  /// Decoded server frames. Malformed frames are dropped, never thrown — a
  /// single bad message must not take down dispatch.
  Stream<Map<String, dynamic>> get events => _events.stream;
  Stream<WsStatus> get status => _status.stream;

  WsStatus _current = WsStatus.idle;
  WsStatus get currentStatus => _current;

  bool get isConnected => _current == WsStatus.connected;

  void _setStatus(WsStatus value) {
    if (_current == value) return;
    _current = value;
    if (!_status.isClosed) _status.add(value);
  }

  Future<void> connect() async {
    if (_disposed) return;
    _intentionallyClosed = false;
    _reconnectTimer?.cancel();

    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      _setStatus(WsStatus.closed);
      return;
    }

    _setStatus(_attempt == 0 ? WsStatus.connecting : WsStatus.reconnecting);

    try {
      final uri = Uri.parse('${AppConfig.wsBaseUrl}${await path()}');
      final channel = connector(uri);
      _channel = channel;

      _sub = channel.stream.listen(
        _onFrame,
        onError: (Object error, StackTrace _) => _scheduleReconnect(error),
        onDone: () => _scheduleReconnect('closed by server'),
        cancelOnError: true,
      );

      _attempt = 0;
      _setStatus(WsStatus.connected);
      _startPing();
    } on Object catch (e) {
      _scheduleReconnect(e);
    }
  }

  void _onFrame(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && !_events.isClosed) {
        _events.add(decoded);
      }
    } on FormatException catch (e) {
      debugPrint('WsClient: dropped malformed frame: $e');
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      // Django Channels answers unknown actions with an error frame, which is
      // all we need: any response proves the pipe is alive. A silent socket
      // triggers the onDone/onError path and a reconnect.
      send({'action': 'ping'});
    });
  }

  void _scheduleReconnect(Object? reason) {
    _pingTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    _channel = null;

    if (_disposed || _intentionallyClosed) {
      _setStatus(WsStatus.closed);
      return;
    }

    _setStatus(WsStatus.reconnecting);
    _attempt++;

    // Exponential backoff with jitter. Without jitter, every driver in a city
    // that just lost a Daphne pod reconnects on the same tick and knocks the
    // replacement over too.
    final base = AppConfig.wsMinBackoff.inMilliseconds * math.pow(2, _attempt - 1);
    final capped = math.min(base.toDouble(), AppConfig.wsMaxBackoff.inMilliseconds.toDouble());
    final jitter = math.Random().nextDouble() * 0.3 + 0.85;
    final delay = Duration(milliseconds: (capped * jitter).round());

    debugPrint('WsClient: reconnecting in ${delay.inSeconds}s ($reason)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  void send(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.send(jsonEncode(message));
    } on Object catch (e) {
      debugPrint('WsClient: send failed: $e');
      _scheduleReconnect(e);
    }
  }

  /// Close without reconnecting — the driver went off duty or signed out.
  Future<void> close() async {
    _intentionallyClosed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _channel?.close();
    _channel = null;
    _attempt = 0;
    _setStatus(WsStatus.closed);
  }

  Future<void> dispose() async {
    _disposed = true;
    await close();
    await _events.close();
    await _status.close();
  }
}
