/// The server's trip state machine, mirrored client-side.
///
/// The backend keeps a single `cancelled` status code and records *who*
/// cancelled in `Trip.cancelled_by`, so this enum matches the server's
/// vocabulary exactly rather than inventing client-only states.
enum TripStatus {
  requested,
  accepted,
  reached,
  inProgress,
  completed,
  cancelled,
  unknown;

  static TripStatus parse(Object? raw) {
    switch (raw?.toString().toLowerCase().replaceAll(' ', '_')) {
      case 'requested':
        return TripStatus.requested;
      case 'accepted':
      case 'accept':
        return TripStatus.accepted;
      case 'reached':
        return TripStatus.reached;
      case 'in_progress':
      case 'start':
        return TripStatus.inProgress;
      case 'completed':
      case 'complete':
        return TripStatus.completed;
      case 'cancelled':
      case 'cancel':
        return TripStatus.cancelled;
      default:
        return TripStatus.unknown;
    }
  }

  bool get isActive =>
      this == TripStatus.accepted ||
      this == TripStatus.reached ||
      this == TripStatus.inProgress;

  bool get isFinished =>
      this == TripStatus.completed || this == TripStatus.cancelled;

  /// What the driver should be doing right now — drives the primary action
  /// button on the active-trip screen.
  String get driverLabel {
    switch (this) {
      case TripStatus.accepted:
        return 'Head to pickup';
      case TripStatus.reached:
        return 'Waiting for rider';
      case TripStatus.inProgress:
        return 'Trip in progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.requested:
        return 'Awaiting driver';
      case TripStatus.unknown:
        return 'Unknown';
    }
  }
}

/// A trip as the driver app needs it.
///
/// Built from three sources that carry overlapping fields: `GET /ride/active/`,
/// the `ride_request` WebSocket offer, and `trip_status_update` frames.
/// [merge] exists because a WS frame is partial by design — it must never
/// blank out fields the REST payload already gave us.
class Trip {
  const Trip({
    required this.id,
    required this.status,
    this.riderName,
    this.riderPhone,
    this.pickupAddress,
    this.destinationAddress,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.estimatedFare,
    this.finalFare,
    this.distanceKm,
    this.paymentMethod,
    this.paymentStatus,
    this.otpVerified = false,
    this.acceptedAt,
    this.reachedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
  });

  final int id;
  final TripStatus status;
  final String? riderName;

  /// Only present once the trip is assigned. Used for the OS dialer — the
  /// number is never rendered as text, matching the platform's phone-privacy
  /// posture.
  final String? riderPhone;

  final String? pickupAddress;
  final String? destinationAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? estimatedFare;
  final String? finalFare;
  final double? distanceKm;
  final String? paymentMethod;
  final String? paymentStatus;
  final bool otpVerified;

  final DateTime? acceptedAt;
  final DateTime? reachedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;

  bool get isCash => (paymentMethod ?? '').toLowerCase() == 'cash';
  bool get isPaid => (paymentStatus ?? '').toLowerCase() == 'completed';

  String get fareToCollect => finalFare ?? estimatedFare ?? '0';

  static double? _num(Object? v) =>
      v == null ? null : double.tryParse(v.toString());

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Field names differ slightly across the endpoints that produce trips
    // (`/ride/active/` vs `/ride/trip/<id>/` vs a WS offer). Accept every
    // spelling the backend actually emits.
    return Trip(
      id: (json['trip_id'] ?? json['id'] as Object?) is num
          ? ((json['trip_id'] ?? json['id']) as num).toInt()
          : int.tryParse('${json['trip_id'] ?? json['id']}') ?? 0,
      status: TripStatus.parse(json['status'] ?? json['status_code']),
      riderName: json['rider_name']?.toString() ?? json['user_name']?.toString(),
      riderPhone: json['rider_phone']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      destinationAddress: json['destination_address']?.toString(),
      pickupLat: _num(json['pickup_lat']),
      pickupLng: _num(json['pickup_lng'] ?? json['pickup_long']),
      destinationLat: _num(json['destination_lat']),
      destinationLng: _num(json['destination_lng'] ?? json['destination_long']),
      estimatedFare: json['estimated_fare']?.toString(),
      finalFare: json['final_fare']?.toString(),
      distanceKm: _num(json['estimated_distance_km'] ?? json['distance_km']),
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      acceptedAt: _date(json['accepted_at']),
      reachedAt: _date(json['reached_at']),
      startedAt: _date(json['started_at']),
      completedAt: _date(json['completed_at']),
      cancelledAt: _date(json['cancelled_at']),
      cancelledBy: json['cancelled_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'rider_name': riderName,
        'rider_phone': riderPhone,
        'pickup_address': pickupAddress,
        'destination_address': destinationAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
        'estimated_fare': estimatedFare,
        'final_fare': finalFare,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
      };

  Trip copyWith({
    TripStatus? status,
    String? finalFare,
    String? paymentStatus,
    String? riderPhone,
    bool? otpVerified,
    DateTime? reachedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
  }) =>
      Trip(
        id: id,
        status: status ?? this.status,
        riderName: riderName,
        riderPhone: riderPhone ?? this.riderPhone,
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        estimatedFare: estimatedFare,
        finalFare: finalFare ?? this.finalFare,
        distanceKm: distanceKm,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        otpVerified: otpVerified ?? this.otpVerified,
        acceptedAt: acceptedAt,
        reachedAt: reachedAt ?? this.reachedAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        cancelledBy: cancelledBy ?? this.cancelledBy,
      );

  /// Fold a partial update (typically a WS frame) over this trip.
  ///
  /// A `trip_status_update` carries little more than a status, so a naive
  /// replace would wipe the rider's name and the pickup address mid-ride.
  Trip merge(Map<String, dynamic> patch) {
    final incoming = Trip.fromJson({...toJson(), ...patch});
    return incoming;
  }
}
