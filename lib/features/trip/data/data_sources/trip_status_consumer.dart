import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/trip_model.dart';

/// Maps a `trip_status_update` **action verb** to the canonical [TripStatus].
///
/// The backend `TripStatusConsumer` group-sends the raw action verb in the
/// broadcast `status` field (docs/08_REALTIME.md documents model codes, but the
/// consumer code sends verbs — verified against
/// servers/ride/consumers.py). This is the single translation point.
TripStatus? tripStatusFromWsAction(String? action) {
  switch (action) {
    case 'accept':
    case 'accepted':
      return TripStatus.accepted;
    case 'reached':
      return TripStatus.reached;
    case 'start':
    case 'in_progress':
      return TripStatus.inProgress;
    case 'complete':
    case 'completed':
      return TripStatus.completed;
    case 'cancel':
    case 'cancelled':
      return TripStatus.cancelled;
    default:
      return null;
  }
}

/// Typed events received on `ws/ride/trip/<id>/`.
sealed class TripStatusEvent {
  const TripStatusEvent();
}

/// `{"type": "connection_established", "trip_id": <int>, ...}` — subscribed to
/// the trip channel; no state change on its own.
class TripConnectionEstablished extends TripStatusEvent {
  const TripConnectionEstablished({required this.tripId, this.message});

  final int? tripId;
  final String? message;
}

/// `{"type": "trip_status_update", "status": <verb>, ...}`.
///
/// On `accept` the broadcast additionally carries `otp`, `driver_info` and
/// `vehicle_info`. [status] is the mapped model status; unmappable verbs surface
/// as [TripStatusUnknownEvent] instead.
class TripStatusChanged extends TripStatusEvent {
  const TripStatusChanged({
    required this.status,
    required this.raw,
    this.message,
    this.otp,
    this.driverInfo,
    this.vehicleInfo,
  });

  final TripStatus status;
  final String? message;
  final String? otp;
  final Map<String, dynamic>? driverInfo;
  final Map<String, dynamic>? vehicleInfo;
  final Map<String, dynamic> raw;
}

/// `{"type": "trip_status_update", "status": "confirm_cash", ...}` — the backend
/// acknowledged a `confirm_cash` action. This is NOT a lifecycle transition (the
/// trip stays `completed`), so it is surfaced as its own event rather than mapped
/// through [tripStatusFromWsAction].
class TripCashConfirmed extends TripStatusEvent {
  const TripCashConfirmed({this.message});

  final String? message;
}

/// `{"type": "trip_taken", "trip_id": <int>, "message": ...}` — this offer was
/// won by another driver.
class TripTakenEvent extends TripStatusEvent {
  const TripTakenEvent({this.tripId, this.message});

  final int? tripId;
  final String? message;
}

/// `{"type": "error", "message": <str>}` — a rejected action (invalid OTP,
/// invalid transition, brute-force lockout, …).
class TripStatusErrorEvent extends TripStatusEvent {
  const TripStatusErrorEvent(this.message);

  final String message;

  /// True for the OTP-specific rejections so the UI can surface them inline on
  /// the OTP field rather than as a generic banner.
  bool get isOtpError {
    final m = message.toLowerCase();
    return m.contains('otp');
  }
}

/// Any frame whose `type` is absent or undocumented.
class TripStatusUnknownEvent extends TripStatusEvent {
  const TripStatusUnknownEvent(this.type, this.payload);

  final String? type;
  final Map<String, dynamic> payload;
}

/// Raised when the socket cannot be opened because a connect-time query
/// parameter (the JWT) is unavailable.
class TripStatusConnectException implements Exception {
  const TripStatusConnectException(this.message);

  final String message;

  @override
  String toString() => 'TripStatusConnectException: $message';
}

/// Client for the per-trip `TripStatusConsumer` channel.
///
/// Unlike the driver-location socket the URL carries only the JWT (the trip id
/// is a path segment), but it is still rebuilt on every attempt so a reconnect
/// never replays an expired token.
class TripStatusConsumer {
  TripStatusConsumer({
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

  final _eventController = StreamController<TripStatusEvent>.broadcast();

  int get tripId => _tripId;

  /// Decoded, typed inbound events.
  Stream<TripStatusEvent> get events => _eventController.stream;

  /// Transport-level connection state.
  Stream<WebSocketState> get connectionState => _service.stateStream;

  Future<Uri> _buildUrl() async {
    final token = await _tokenReader();
    if (token == null || token.isEmpty) {
      throw const TripStatusConnectException(
        'No access token available for the trip status socket.',
      );
    }
    return buildUri(
      wsBaseUrl: _wsBaseUrlReader(),
      tripId: _tripId,
      token: token,
    );
  }

  /// Composes `<wsBaseUrl>ws/ride/trip/<id>/?token=`.
  ///
  /// Pure, so URL composition is unit testable. Tolerates a base URL with or
  /// without a trailing slash and avoids duplicating the `ws/` segment (see
  /// [DriverLocationConsumer.buildUri] for the same reasoning).
  static Uri buildUri({
    required String wsBaseUrl,
    required int tripId,
    required String token,
  }) {
    final base = wsBaseUrl.endsWith('/') ? wsBaseUrl : '$wsBaseUrl/';
    var path = ApiEndpoints.wsTripStatus(tripId.toString());

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
  static TripStatusEvent parseEvent(Map<String, dynamic> payload) {
    final type = payload['type'];
    final typeName = type is String ? type : null;

    switch (typeName) {
      case 'connection_established':
        return TripConnectionEstablished(
          tripId: _asInt(payload['trip_id']),
          message: payload['message']?.toString(),
        );
      case 'trip_status_update':
        // `confirm_cash` acknowledges a cash collection; it is not a lifecycle
        // transition, so intercept it before the action→status mapping.
        if (payload['status']?.toString() == 'confirm_cash') {
          return TripCashConfirmed(message: payload['message']?.toString());
        }
        final status = tripStatusFromWsAction(payload['status']?.toString());
        if (status == null) {
          return TripStatusUnknownEvent(typeName, payload);
        }
        return TripStatusChanged(
          status: status,
          raw: payload,
          message: payload['message']?.toString(),
          otp: payload['otp']?.toString(),
          driverInfo: payload['driver_info'] is Map<String, dynamic>
              ? payload['driver_info'] as Map<String, dynamic>
              : null,
          vehicleInfo: payload['vehicle_info'] is Map<String, dynamic>
              ? payload['vehicle_info'] as Map<String, dynamic>
              : null,
        );
      case 'trip_taken':
        return TripTakenEvent(
          tripId: _asInt(payload['trip_id']),
          message: payload['message']?.toString(),
        );
      case 'error':
        return TripStatusErrorEvent(
          payload['message']?.toString() ?? 'Trip action failed.',
        );
      default:
        return TripStatusUnknownEvent(typeName, payload);
    }
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  void connect() => _service.connect();

  /// Sends a driver action frame. The wire format is `{"action": <verb>}` with
  /// `otp` on `start` and an optional `reason` on `cancel`.
  void sendAction(String action, {String? otp, String? reason}) {
    final message = <String, dynamic>{'action': action};
    if (otp != null) message['otp'] = otp;
    if (reason != null) message['reason'] = reason;
    _service.sendMessage(message);
  }

  void disconnect() => _service.disconnect();

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _service.dispose();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
    AppLogger.d('TripStatusConsumer disposed');
  }
}
