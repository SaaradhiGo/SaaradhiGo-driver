import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
// `status.goingAway` is 1001, which dart:io's WebSocket.close() REFUSES:
// "close code must be 1000 or in the range 3000-4999". Every teardown threw
// an unhandled exception because of it. Observed on QA after a driver
// accepted trip #94: the accept acked, the app then tore down its socket,
// the throw aborted the flow, `/ride/active/` answered NO_ACTIVE_TRIP and
// the driver was left with no trip at all.
//
// 1000 (normal closure) is the right code for a client hanging up anyway --
// 1001 means "the server is going away", which is not what is happening.
import '../utils/app_logger.dart';

enum WebSocketState { disconnected, connecting, connected, error }

/// Builds the connection [Uri] for a socket.
///
/// Invoked once per connection attempt (including every reconnect) so that
/// connect-time credentials and query parameters are always fresh. The driver
/// location channel carries `token`, `lat` and `lng` as query parameters, so a
/// frozen URL would replay a stale position and a possibly-expired JWT.
typedef WebSocketUrlBuilder = Future<Uri> Function();

/// Creates the underlying channel. Injectable for tests.
typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

/// Query parameters that must never reach the logs.
const _sensitiveQueryKeys = {'token', 'access_token', 'refresh_token'};

/// Returns [uri] as a string with sensitive query parameter values masked.
String redactUri(Uri uri) {
  if (uri.queryParameters.isEmpty) return uri.toString();

  final redacted = <String, String>{};
  for (final entry in uri.queryParameters.entries) {
    redacted[entry.key] = _sensitiveQueryKeys.contains(entry.key.toLowerCase())
        ? '***'
        : entry.value;
  }
  return uri.replace(queryParameters: redacted).toString();
}

class WebSocketService {
  WebSocketService({
    required WebSocketUrlBuilder urlBuilder,
    WebSocketChannelFactory? channelFactory,
    int maxReconnectAttempts = 6,
    Duration Function(int attempt)? reconnectDelayBuilder,
  }) : _urlBuilder = urlBuilder,
       _channelFactory = channelFactory ?? WebSocketChannel.connect,
       _maxReconnectAttempts = maxReconnectAttempts,
       _reconnectDelayBuilder = reconnectDelayBuilder ?? _defaultReconnectDelay;

  final WebSocketUrlBuilder _urlBuilder;
  final WebSocketChannelFactory _channelFactory;
  final int _maxReconnectAttempts;
  final Duration Function(int attempt) _reconnectDelayBuilder;

  /// Backoff ceiling per docs/08_REALTIME.md: 1s, 2s, 4s, 8s, 16s, max 30s.
  static const Duration _maxBackoff = Duration(seconds: 30);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;
  bool _connecting = false;
  bool _disposed = false;
  int _session = 0;

  /// Last known transport availability. Optimistic (assumes online) so a slow
  /// first connectivity probe never blocks the initial connection.
  bool _networkOnline = true;

  /// True while a reconnect is pending but paused because the device is
  /// offline. Prevents the backoff budget being consumed by futile attempts
  /// during airplane mode (docs/14_ERROR_HANDLING.md:11,18).
  bool _waitingForNetwork = false;

  final _stateController = StreamController<WebSocketState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<WebSocketState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _channel != null;

  static Duration _defaultReconnectDelay(int attempt) {
    final seconds = pow(2, attempt).toInt();
    return Duration(seconds: min(seconds, _maxBackoff.inSeconds));
  }

  void connect() {
    if (_disposed || _connecting || _channel != null) return;
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    _waitingForNetwork = false;
    _reconnectTimer?.cancel();
    _session++;
    _connectInternal(_session);
  }

  Future<void> _connectInternal(int session) async {
    if (_disposed || session != _session || _connecting || _channel != null) {
      return;
    }
    _connecting = true;

    _emitState(WebSocketState.connecting);

    Uri uri;
    try {
      uri = await _urlBuilder();
    } catch (e) {
      AppLogger.e('WS URL build failed: ${e.runtimeType}');
      _handleDisconnect(session);
      if (session == _session) _connecting = false;
      return;
    }

    if (_disposed || !_shouldReconnect || session != _session) {
      _connecting = false;
      return;
    }

    AppLogger.d('WS Connecting to: ${redactUri(uri)}');

    try {
      final channel = _channelFactory(uri);
      _channel = channel;

      _subscription = channel.stream.listen(
        (message) {
          if (session != _session || !identical(_channel, channel)) return;
          _reconnectAttempts = 0;
          _emitState(WebSocketState.connected);

          if (message is! String) {
            AppLogger.w('WS Ignoring non-text frame');
            return;
          }

          try {
            final decoded = jsonDecode(message);
            if (decoded is Map<String, dynamic>) {
              if (!_messageController.isClosed) {
                _messageController.add(decoded);
              }
            } else {
              AppLogger.w('WS Ignoring non-object payload');
            }
          } catch (e) {
            AppLogger.e('WS message decode failed: ${e.runtimeType}');
          }
        },
        onDone: () {
          AppLogger.d('WS Connection Closed (code: ${channel.closeCode})');
          _handleDisconnect(session, channel);
        },
        onError: (Object error) {
          AppLogger.e('WS transport error: ${error.runtimeType}');
          _handleDisconnect(session, channel);
        },
        cancelOnError: true,
      );

      // Surfaces handshake rejection (e.g. server refusing the JWT) and gives a
      // truthful `connected` signal instead of waiting for the first frame.
      unawaited(
        channel.ready.then(
          (_) {
            if (session == _session && identical(_channel, channel)) {
              _emitState(WebSocketState.connected);
            }
          },
          onError: (Object e) {
            AppLogger.e('WS handshake failed: ${e.runtimeType}');
            _handleDisconnect(session, channel);
          },
        ),
      );
    } catch (e) {
      AppLogger.e('WS setup failed: ${e.runtimeType}');
      _handleDisconnect(session);
    } finally {
      if (session == _session) _connecting = false;
    }
  }

  void _handleDisconnect(int session, [WebSocketChannel? source]) {
    if (_disposed || session != _session) return;
    if (source != null && !identical(_channel, source)) return;
    if (_channel == null && _subscription == null && !_connecting) return;

    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _emitState(WebSocketState.disconnected);

    if (_shouldReconnect && !_disposed) {
      _scheduleReconnect(session);
    }
  }

  /// Reports a change in platform connectivity (from
  /// `isOnlineNetworkProvider`).
  ///
  /// While offline, a live channel is torn down and any pending reconnect is
  /// paused instead of burning the exponential-backoff budget on futile
  /// attempts; when connectivity returns the next reconnect runs immediately
  /// (no extra backoff wait).
  void updateNetworkStatus(bool isOnline) {
    if (_networkOnline == isOnline) return;
    _networkOnline = isOnline;

    if (_disposed) return;

    if (!isOnline) {
      _waitingForNetwork = true;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      final channel = _channel;
      if (channel != null) {
        // The transport is no longer usable (e.g. airplane mode toggled while
        // a socket appeared healthy). Tear it down so the disconnected handler
        // schedules a reconnect which will then be paused for the network.
        AppLogger.d('WS Closing channel: no network');
        _subscription?.cancel();
        _subscription = null;
        _channel = null;
        channel.sink.close(status.normalClosure);
        _emitState(WebSocketState.disconnected);
        if (_shouldReconnect) _scheduleReconnect(_session);
      }
      return;
    }

    // Back online: resume any in-progress session immediately.
    final wasWaiting = _waitingForNetwork;
    _waitingForNetwork = false;
    if (wasWaiting &&
        _shouldReconnect &&
        !_connecting &&
        _channel == null &&
        _session > 0) {
      AppLogger.d('WS Network restored — reconnecting now');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _connectInternal(_session);
    }
  }

  void _scheduleReconnect(int session) {
    if (session != _session || !_shouldReconnect || _disposed) return;

    // Do not burn backoff attempts while the platform reports no transport.
    if (!_networkOnline) {
      _waitingForNetwork = true;
      AppLogger.d('WS Reconnect deferred: no network');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.e('WS Max reconnect attempts reached');
      _emitState(WebSocketState.error);
      return;
    }

    var delay = _reconnectDelayBuilder(_reconnectAttempts);
    if (delay < Duration.zero) delay = Duration.zero;
    if (delay > _maxBackoff) delay = _maxBackoff;
    _reconnectAttempts++;

    AppLogger.d(
      'WS Reconnecting in ${delay.inSeconds}s (Attempt $_reconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => _connectInternal(session));
  }

  void sendMessage(Map<String, dynamic> data) {
    final channel = _channel;
    if (channel != null) {
      channel.sink.add(jsonEncode(data));
    } else {
      AppLogger.w('WS Cannot send message, channel is null');
    }
  }

  void disconnect() {
    if (_disposed && _channel == null && _subscription == null) return;
    final hadConnection =
        _channel != null || _subscription != null || _reconnectTimer != null;
    _shouldReconnect = false;
    _session++;
    _connecting = false;
    _waitingForNetwork = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close(status.normalClosure);
    _channel = null;
    if (hadConnection) _emitState(WebSocketState.disconnected);
  }

  void _emitState(WebSocketState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void dispose() {
    if (_disposed) return;
    disconnect();
    _disposed = true;
    _stateController.close();
    _messageController.close();
  }
}
