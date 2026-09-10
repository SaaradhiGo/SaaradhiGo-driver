class TripModel {
  final int id;
  final String status;
  final String? estimatedFare;
  final String? finalFare;
  final String? surgeMultiplier;
  final String? createdAt;
  final String? pickupAddress;
  final String? destinationAddress;
  final String? distanceKm;
  final String? durationMin;
  final String? riderName;
  final String? paymentMethod;
  final String? paymentStatus;
  final Map<String, dynamic>? fareBreakdown;

  TripModel({
    required this.id,
    required this.status,
    this.estimatedFare,
    this.finalFare,
    this.surgeMultiplier,
    this.createdAt,
    this.pickupAddress,
    this.destinationAddress,
    this.distanceKm,
    this.durationMin,
    this.riderName,
    this.paymentMethod,
    this.paymentStatus,
    this.fareBreakdown,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? json['trip_id'] ?? 0,
      status: json['status'] ?? 'unknown',
      estimatedFare: json['estimated_fare']?.toString(),
      finalFare: json['final_fare']?.toString(),
      surgeMultiplier: json['surge_multiplier']?.toString(),
      createdAt:
          json['requested_at']?.toString() ?? json['created_at']?.toString(),
      pickupAddress: json['pickup_address']?.toString() ?? 'Unknown Pickup',
      destinationAddress:
          json['destination_address']?.toString() ?? 'Unknown Dropoff',
      distanceKm:
          json['actual_distance_km']?.toString() ??
          json['estimated_distance_km']?.toString(),
      durationMin:
          json['actual_duration_min']?.toString() ??
          json['estimated_duration_min']?.toString(),
      riderName: json['user']?.toString() ?? 'Rider',
      paymentMethod: json['payment_method']?.toString() ?? 'Digital',
      paymentStatus: json['payment_status']?.toString(),
      fareBreakdown: json['fare_breakdown'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'estimated_fare': estimatedFare,
      'final_fare': finalFare,
      'surge_multiplier': surgeMultiplier,
      'requested_at': createdAt,
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'actual_distance_km': distanceKm,
      'actual_duration_min': durationMin,
      'user': riderName,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'fare_breakdown': fareBreakdown,
    };
  }
}
