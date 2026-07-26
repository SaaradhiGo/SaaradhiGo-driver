import '../../../core/config/app_config.dart';

/// An incoming `ride_request` frame from `DriverLocationConsumer`.
///
/// Server payload (WebSocket_Documentation.md §1):
/// ```json
/// {"type":"ride_request","trip_id":101,"rider_name":"…",
///  "pickup_lat":17.385,"pickup_lng":78.486,
///  "destination_lat":17.44,"destination_lng":78.348,
///  "pickup_address":"…","destination_address":"…","estimated_fare":"245.50"}
/// ```
/// Coordinates arrive as strings from the consumer's `str()` calls, so every
/// numeric field is parsed defensively.
class RideOffer {
  RideOffer({
    required this.tripId,
    required this.receivedAt,
    this.riderName,
    this.pickupAddress,
    this.destinationAddress,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.estimatedFare,
  });

  final int tripId;
  final DateTime receivedAt;
  final String? riderName;
  final String? pickupAddress;
  final String? destinationAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? estimatedFare;

  /// Time left before the card self-dismisses. Driven by wall-clock rather
  /// than a tick counter so a paused isolate (screen off, OEM doze) does not
  /// leave a stale offer on screen showing 12 seconds forever.
  Duration get remaining {
    final elapsed = DateTime.now().difference(receivedAt);
    final left = AppConfig.offerTimeout - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isExpired => remaining == Duration.zero;

  double get progress {
    final total = AppConfig.offerTimeout.inMilliseconds;
    if (total == 0) return 0;
    return (remaining.inMilliseconds / total).clamp(0.0, 1.0);
  }

  static double? _num(Object? v) =>
      v == null ? null : double.tryParse(v.toString());

  factory RideOffer.fromEvent(Map<String, dynamic> event) {
    final rawId = event['trip_id'];
    return RideOffer(
      tripId: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      receivedAt: DateTime.now(),
      riderName: event['rider_name']?.toString(),
      pickupAddress: event['pickup_address']?.toString(),
      destinationAddress: event['destination_address']?.toString(),
      pickupLat: _num(event['pickup_lat']),
      pickupLng: _num(event['pickup_lng']),
      destinationLat: _num(event['destination_lat']),
      destinationLng: _num(event['destination_lng']),
      estimatedFare: event['estimated_fare']?.toString(),
    );
  }
}
