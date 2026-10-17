/// A ride offer that arrived over push, parsed from the server's own payload.
///
/// THE PAYLOAD IS NOT NEGOTIABLE
/// -----------------------------
/// `servers/ride/dispatch.py::_enqueue_offer_pushes` sends exactly:
///
///     title: 'New Ride Request'
///     body:  'New ride request from <rider name>'
///     data:  {'trip_id': '<id>', 'type': 'ride_request'}
///
/// and `send_push_notification_task` stringifies every value
/// (`{str(k): str(v) for ...}`), so `trip_id` arrives as a **String** even
/// though the WebSocket frame carries it as an int. Parsing has to accept
/// both, which is the kind of difference that is invisible until a driver
/// taps a notification and nothing happens.
library;

/// Where an offer came from. Determines what the app is allowed to assume.
enum PushOfferSource {
  /// `onMessage` — the app was in the foreground when it arrived.
  foreground,

  /// `onMessageOpenedApp` — the driver tapped the notification while the app
  /// was backgrounded.
  openedFromBackground,

  /// `getInitialMessage` — the driver tapped the notification and the app
  /// was not running at all.
  openedFromTerminated,
}

class PushOffer {
  const PushOffer({
    required this.tripId,
    required this.source,
    this.title,
    this.body,
    this.sentAt,
    this.expiresAt,
  });

  final int tripId;
  final PushOfferSource source;
  final String? title;
  final String? body;

  /// When FCM says the server sent this, when it says anything.
  ///
  /// The only way to tell a fresh offer from one that has been sitting in a
  /// notification shade: the payload carries no expiry field, and a push can
  /// be delivered minutes late or tapped hours later. Compared against the
  /// backend's own `TRIP_ACCEPT_TIMEOUT_SECONDS` (90s), after which
  /// `auto_cancel_trip` has closed the trip regardless.
  final DateTime? sentAt;

  /// When the server says this offer stops being acceptable.
  ///
  /// Added to the dispatch payload so this app stops guessing. It used to
  /// compare [sentAt] against a hard-coded 90 seconds copied from the
  /// backend's `TRIP_ACCEPT_TIMEOUT_SECONDS` -- a guess about server
  /// behaviour living in a client, which goes quietly wrong the moment the
  /// timeout is retuned. When present this is authoritative; when absent the
  /// old heuristic still applies, so an older server build keeps working.
  final DateTime? expiresAt;

  /// True when the driver got here by tapping the notification, so the app
  /// should take them to the offer rather than waiting for them to notice it.
  bool get wasTapped => source != PushOfferSource.foreground;

  /// Parse a dispatch payload, or null when it is not a ride offer.
  ///
  /// Returns null rather than throwing: an unrecognised push must never be
  /// able to crash the app, and the server sends other notification types
  /// through the same channel (trip updates, ops alerts, marketing).
  static PushOffer? tryParse(
    Map<String, dynamic> data, {
    required PushOfferSource source,
    String? title,
    String? body,
    DateTime? sentAt,
  }) {
    if (data['type'] != 'ride_request') return null;

    final tripId = _asInt(data['trip_id']);
    if (tripId == null) return null;

    return PushOffer(
      tripId: tripId,
      source: source,
      title: title,
      body: body,
      sentAt: sentAt,
      expiresAt: _asUtcDate(data['expires_at']),
    );
  }

  /// True when the server's own expiry has passed. Null when it said nothing.
  bool? hasExpiredAt(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) return null;
    return now.isAfter(expiry);
  }

  static DateTime? _asUtcDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim())?.toUtc();
    }
    return null;
  }

  /// How old this offer is, or null when FCM gave no send time.
  Duration? ageAt(DateTime now) {
    final sent = sentAt;
    if (sent == null) return null;
    final age = now.difference(sent);
    return age.isNegative ? Duration.zero : age;
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    // The server stringifies every data value, so this is the real case.
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  @override
  String toString() => 'PushOffer(trip $tripId, ${source.name})';
}
