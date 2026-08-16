class TripModel {
  final int id;
  final String status;
  final String? estimatedFare;
  final String? createdAt;
  final String? pickupAddress;
  final String? destinationAddress;
  final String? distanceKm;
  final String? durationMin;
  final String? riderName;
  final String? paymentMethod;

  TripModel({
    required this.id,
    required this.status,
    this.estimatedFare,
    this.createdAt,
    this.pickupAddress,
    this.destinationAddress,
    this.distanceKm,
    this.durationMin,
    this.riderName,
    this.paymentMethod,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? json['trip_id'] ?? 0,
      status: json['status'] ?? 'unknown',
      estimatedFare: json['estimated_fare']?.toString(),
      createdAt: json['created_at']?.toString(),
      pickupAddress: json['pickup_address']?.toString() ?? 'Unknown Pickup',
      destinationAddress: json['destination_address']?.toString() ?? 'Unknown Dropoff',
      distanceKm: json['distance_km']?.toString(),
      durationMin: json['duration_min']?.toString(),
      riderName: json['rider_name']?.toString() ?? 'Rider',
      paymentMethod: json['payment_method']?.toString() ?? 'Digital',
    );
  }
}
