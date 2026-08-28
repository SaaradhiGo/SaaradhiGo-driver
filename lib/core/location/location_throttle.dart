import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Gate for outbound location frames on the driver location WebSocket.
///
/// Implements docs/10_LOCATION.md §2 verbatim — a frame is sent only if:
///   * distance shifted > 10 meters, **OR**
///   * time interval > 5 seconds elapsed.
///
/// Pure and side-effect free apart from the retained last-sent sample, so the
/// rule can be unit tested without a socket or a GPS stream.
class LocationThrottle {
  LocationThrottle({
    this.minDistanceMeters = 10,
    this.minInterval = const Duration(seconds: 5),
  });

  final double minDistanceMeters;
  final Duration minInterval;

  LatLng? _lastSent;
  DateTime? _lastSentAt;

  LatLng? get lastSent => _lastSent;
  DateTime? get lastSentAt => _lastSentAt;

  /// Whether [next] should be pushed to the backend at [now].
  ///
  /// The first sample always passes. Does **not** mutate state — call
  /// [recordSent] once the frame has actually been handed to the socket.
  bool shouldSend(LatLng next, DateTime now) {
    final lastSent = _lastSent;
    final lastSentAt = _lastSentAt;
    if (lastSent == null || lastSentAt == null) return true;

    if (now.difference(lastSentAt) >= minInterval) return true;

    return distanceBetweenMeters(lastSent, next) > minDistanceMeters;
  }

  /// Marks [sent] as delivered at [now].
  void recordSent(LatLng sent, DateTime now) {
    _lastSent = sent;
    _lastSentAt = now;
  }

  /// Convenience: [shouldSend] followed by [recordSent] when it passes.
  bool tryConsume(LatLng next, DateTime now) {
    if (!shouldSend(next, now)) return false;
    recordSent(next, now);
    return true;
  }

  void reset() {
    _lastSent = null;
    _lastSentAt = null;
  }

  /// Great-circle distance in meters between [a] and [b] (haversine).
  static double distanceBetweenMeters(LatLng a, LatLng b) {
    const earthRadius = 6371008.8; // IUGG mean earth radius, meters.
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
