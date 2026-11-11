import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Typed events received on `ws/driver/location/`.
///
/// Only the three message types documented in `WebSocket_Documentation.md`
/// §1 are modelled. Anything else surfaces as [DriverLocationUnknownEvent]
/// rather than being invented into a shape.
sealed class DriverLocationEvent {
  const DriverLocationEvent();
}

/// `{"type": "connection_established", "message": "Driver <ID> connected"}`
///
/// This is the authoritative signal that the driver is now `online` — the
/// backend has no REST availability endpoint (docs/19_MISSING_REQUIREMENTS.md
/// Conflict 1).
class DriverLocationConnectionEstablished extends DriverLocationEvent {
  const DriverLocationConnectionEstablished(this.message);

  final String message;
}

/// `{"type": "location_updated", "lat": <float>, "lng": <float>}`
///
/// Acknowledgement that the coordinate reached the backend Redis cache.
class DriverLocationUpdated extends DriverLocationEvent {
  const DriverLocationUpdated({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

/// `{"type": "ride_request", "trip_id": <int>, ...}`
///
/// Payload is carried raw: the incoming-request UI is Phase 5, and the
/// documented payload lacks `payment_method` / `distance_km` / expiry fields
/// that the design expects, so no typed model is committed to yet.
class DriverLocationRideRequest extends DriverLocationEvent {
  const DriverLocationRideRequest(this.payload);

  final Map<String, dynamic> payload;

  int? get tripId {
    final raw = payload['trip_id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

/// Any frame whose `type` is absent or undocumented.
class DriverLocationUnknownEvent extends DriverLocationEvent {
  const DriverLocationUnknownEvent(this.type, this.payload);

  final String? type;
  final Map<String, dynamic> payload;
}

/// Raised when the socket cannot be opened because a connect-time query
/// parameter is unavailable.
class DriverLocationConnectException implements Exception {
  const DriverLocationConnectException(this.message);

  final String message;

  @override
  String toString() => 'DriverLocationConnectException: $message';
}

/// Client for the `DriverLocationConsumer` channel (docs/08_REALTIME.md §2).
///
/// The channel takes `token`, `lat` and `lng` as **connect-time query
/// parameters**, so the URL is rebuilt on every attempt — including reconnects —
/// from the live token and the latest fix. A frozen URL would replay a stale
/// position and a possibly-expired JWT.
class DriverLocationConsumer {
  DriverLocationConsumer({
    required Future<String?> Function() tokenReader,
    required LatLng? Function() positionReader,
    String Function()? wsBaseUrlReader,
    WebSocketService Function(WebSocketUrlBuilder urlBuilder)? serviceFactory,
  }) : _tokenReader = tokenReader,
       _positionReader = positionReader,
       _wsBaseUrlReader = wsBaseUrlReader ?? (() => ApiEndpoints.wsBaseUrl) {
    _service = (serviceFactory ?? _defaultServiceFactory)(_buildUrl);

    _messageSubscription = _service.messageStream.listen(_handleMessage);
  }

  static WebSocketService _defaultServiceFactory(WebSocketUrlBuilder builder) =>
      WebSocketService(urlBuilder: builder);

  final Future<String?> Function() _tokenReader;
  final LatLng? Function() _positionReader;
  final String Function() _wsBaseUrlReader;

  late final WebSocketService _service;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  final _eventController = StreamController<DriverLocationEvent>.broadcast();

  /// Decoded, typed inbound events.
  Stream<DriverLocationEvent> get events => _eventController.stream;

  /// Transport-level connection state. Note that "online" is defined by
  /// [DriverLocationConnectionEstablished], not by the socket opening.
  Stream<WebSocketState> get connectionState => _service.stateStream;

  Future<Uri> _buildUrl() async {
    final token = await _tokenReader();
    if (token == null || token.isEmpty) {
      throw const DriverLocationConnectException(
        'No access token available for the driver location socket.',
      );
    }

    final position = _positionReader();
    if (position == null) {
      throw const DriverLocationConnectException(
        'No GPS fix available for the driver location socket.',
      );
    }

    return buildUri(
      wsBaseUrl: _wsBaseUrlReader(),
      token: token,
      lat: position.latitude,
      lng: position.longitude,
    );
  }

  /// Composes `<wsBaseUrl>ws/driver/location/?token=&lat=&lng=`.
  ///
  /// Pure, so URL composition is unit testable. Tolerates a base URL with or
  /// without a trailing slash, and avoids duplicating the `ws/` segment when the
  /// configured base already ends in it (docs/24_ENVIRONMENT_SPECIFICATION.md
  /// shows `WS_BASE_URL` including `/ws`, whereas `.env.example` does not).
  static Uri buildUri({
    required String wsBaseUrl,
    required String token,
    required double lat,
    required double lng,
  }) {
    final base = wsBaseUrl.endsWith('/') ? wsBaseUrl : '$wsBaseUrl/';
    var path = ApiEndpoints.wsDriverLocation;

    final baseUri = Uri.parse(base);
    if (baseUri.path.endsWith('/ws/') && path.startsWith('ws/')) {
      path = path.substring(3);
    }

    return Uri.parse('$base$path').replace(
      queryParameters: <String, String>{
        'token': token,
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );
  }

  void _handleMessage(Map<String, dynamic> payload) {
    if (_eventController.isClosed) return;
    _eventController.add(parseEvent(payload));
  }

  /// Maps a decoded frame to a typed event. Exposed for tests.
  static DriverLocationEvent parseEvent(Map<String, dynamic> payload) {
    final type = payload['type'];
    final typeName = type is String ? type : null;

    switch (typeName) {
      case 'connection_established':
        final message = payload['message'];
        return DriverLocationConnectionEstablished(
          message is String ? message : '',
        );
      case 'location_updated':
        final lat = _asDouble(payload['lat']);
        final lng = _asDouble(payload['lng']);
        if (lat == null || lng == null) {
          return DriverLocationUnknownEvent(typeName, payload);
        }
        return DriverLocationUpdated(lat: lat, lng: lng);
      case 'ride_request':
        return DriverLocationRideRequest(payload);
      default:
        return DriverLocationUnknownEvent(typeName, payload);
    }
  }

  static double? _asDouble(Object? raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  void connect() => _service.connect();

  /// Forwards platform connectivity changes so the underlying transport can
  /// pause futile reconnect attempts while offline and resume instantly when
  /// the network returns (docs/14_ERROR_HANDLING.md:11,18).
  void updateNetworkStatus(bool isOnline) =>
      _service.updateNetworkStatus(isOnline);

  /// Pushes a location frame. The wire format is exactly `{"lat":…,"lng":…}`
  /// per `WebSocket_Documentation.md` §1 — no `bearing`, `speed`, `accuracy` or
  /// `timestamp`, none of which are documented.
  void sendLocation(LatLng position) {
    _service.sendMessage(<String, dynamic>{
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  /// Closing the socket is how the driver goes offline — there is no documented
  /// REST endpoint or client-side "go offline" message.
  void disconnect() => _service.disconnect();

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _service.dispose();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
    AppLogger.d('DriverLocationConsumer disposed');
  }
}
