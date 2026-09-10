import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/chat_message_model.dart';

/// Typed events received on `ws/ride/trip/<id>/chat/`.
sealed class TripChatEvent {
  const TripChatEvent();
}

/// Sample frame: `{"type": "connection_established", "trip_id": <int|string>}`
/// — the chat channel is ready. The documented payload echoes the caller's
/// role (rider on the sample, but this app is the driver); no state change on
/// its own.
class TripChatConnectionEstablished extends TripChatEvent {
  const TripChatConnectionEstablished({this.tripId, this.role, this.message});

  final int? tripId;
  final String? role;
  final String? message;
}

/// Sample frame: `{"type": "message", "id": <int>, "sender_role": "rider"}`
/// — a new chat line from the peer, the system, or (echo) this driver's own
/// outbound message.
class TripChatMessageReceived extends TripChatEvent {
  const TripChatMessageReceived({
    required this.message,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    required this.isSystem,
  });

  /// Pre-decoded chat line so screens can render it without re-parsing.
  final ChatMessageModel message;

  final String? senderRole;
  final String body;
  final String? createdAt;
  final bool isSystem;
}

/// `{"type": "error", "message": <str>}` — the backend rejected an action
/// (e.g. attempting to message after the trip settled).
class TripChatErrorEvent extends TripChatEvent {
  const TripChatErrorEvent(this.message);

  final String message;
}

/// Any frame whose `type` is absent or undocumented.
class TripChatUnknownEvent extends TripChatEvent {
  const TripChatUnknownEvent(this.type, this.payload);

  final String? type;
  final Map<String, dynamic> payload;
}

/// Raised when the socket cannot be opened because a connect-time query
/// parameter (the JWT) is unavailable.
class TripChatConnectException implements Exception {
  const TripChatConnectException(this.message);

  final String message;

  @override
  String toString() => 'TripChatConnectException: $message';
}

/// Client for the per-trip in-app chat channel
/// (`ws/ride/trip/<id>/chat/`, WebSocket_Documentation.md §5).
///
/// The socket is created per open chat screen and torn down when the screen is
/// dismissed or the trip settles. The URL carries only the JWT (the trip id is
/// a path segment) and is rebuilt on every attempt so a reconnect never
/// replays an expired token — same contract as [TripStatusConsumer].
class TripChatConsumer {
  TripChatConsumer({
    required int tripId,
    required Future<String?> Function() tokenReader,
    String Function()? wsBaseUrlReader,
    WebSocketService Function(WebSocketUrlBuilder urlBuilder)? serviceFactory,
  }) : _tripId = tripId,
       _tokenReader = tokenReader,
       _wsBaseUrlReader = wsBaseUrlReader ?? (() => ApiEndpoints.wsBaseUrl) {
    _service = (serviceFactory ?? _defaultServiceFactory)(_buildUrl);
    _messageSubscription = _service.messageStream.listen(_handleMessage);
  }

  static WebSocketService _defaultServiceFactory(WebSocketUrlBuilder builder) =>
      WebSocketService(urlBuilder: builder);

  final int _tripId;
  final Future<String?> Function() _tokenReader;
  final String Function() _wsBaseUrlReader;

  late final WebSocketService _service;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  final _eventController = StreamController<TripChatEvent>.broadcast();

  int get tripId => _tripId;

  /// Decoded, typed inbound events.
  Stream<TripChatEvent> get events => _eventController.stream;

  /// Transport-level connection state.
  Stream<WebSocketState> get connectionState => _service.stateStream;

  Future<Uri> _buildUrl() async {
    final token = await _tokenReader();
    if (token == null || token.isEmpty) {
      throw const TripChatConnectException(
        'No access token available for the trip chat socket.',
      );
    }
    return buildUri(
      wsBaseUrl: _wsBaseUrlReader(),
      tripId: _tripId,
      token: token,
    );
  }

  /// Composes `<wsBaseUrl>ws/ride/trip/<id>/chat/?token=`.
  ///
  /// Pure, so URL composition is unit testable. Tolerates a base URL with or
  /// without a trailing slash and avoids duplicating the `ws/` segment.
  static Uri buildUri({
    required String wsBaseUrl,
    required int tripId,
    required String token,
  }) {
    final base = wsBaseUrl.endsWith('/') ? wsBaseUrl : '$wsBaseUrl/';
    var path = ApiEndpoints.wsTripChat(tripId.toString());

    final baseUri = Uri.parse(base);
    if (baseUri.path.endsWith('/ws/') && path.startsWith('ws/')) {
      path = path.substring(3);
    }

    return Uri.parse(
      '$base$path',
    ).replace(queryParameters: <String, String>{'token': token});
  }

  void _handleMessage(Map<String, dynamic> payload) {
    if (_eventController.isClosed) return;
    _eventController.add(parseEvent(payload));
  }

  /// Maps a decoded frame to a typed event. Exposed for tests.
  static TripChatEvent parseEvent(Map<String, dynamic> payload) {
    final type = payload['type'];
    final typeName = type is String ? type : null;

    switch (typeName) {
      case 'connection_established':
        return TripChatConnectionEstablished(
          tripId: _asInt(payload['trip_id']),
          role: payload['role']?.toString(),
          message: payload['message']?.toString(),
        );
      case 'message':
        final model = ChatMessageModel.fromJson(payload);
        return TripChatMessageReceived(
          message: model,
          senderRole: model.senderRole,
          body: model.body ?? '',
          createdAt: model.createdAt,
          isSystem: model.isSystem,
        );
      case 'error':
        return TripChatErrorEvent(
          payload['message']?.toString() ?? 'Chat action failed.',
        );
      default:
        return TripChatUnknownEvent(typeName, payload);
    }
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  void connect() => _service.connect();

  /// Forwards platform connectivity changes so the transport pauses futile
  /// reconnects while offline and resumes instantly when the network returns.
  void updateNetworkStatus(bool isOnline) =>
      _service.updateNetworkStatus(isOnline);

  /// Sends a chat line. Wire format: `{"action": "send", "body": …}`.
  void sendMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    _service.sendMessage(<String, dynamic>{'action': 'send', 'body': trimmed});
  }

  /// Marks all peer messages as read. Wire format: `{"action": "read_all"}`.
  void markAllRead() {
    _service.sendMessage(<String, dynamic>{'action': 'read_all'});
  }

  void disconnect() => _service.disconnect();

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _service.dispose();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
    AppLogger.d('TripChatConsumer disposed');
  }
}
