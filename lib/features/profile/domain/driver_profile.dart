/// A vehicle on the driver's account, from `DriverProfileSerializer`'s
/// `active_vehicle_details` and `GET /driver/vehicles/`.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    this.vehicleType,
    this.brand,
    this.model,
    this.color,
    this.year,
    this.capacity,
    this.status,
    this.vehiclePic,
    this.insuranceExpiry,
    this.permitExpiry,
    this.fitnessExpiry,
    this.pucExpiry,
  });

  final int id;
  final String vehicleNumber;
  final String? vehicleType;
  final String? brand;
  final String? model;
  final String? color;
  final int? year;
  final int? capacity;
  final String? status;
  final String? vehiclePic;

  // MVA 2020 requires all four to be current. The backend's daily sweeper
  // blocks the driver when any of them lapses, so the app surfaces them
  // before that happens — a driver blocked at 2am with no warning is a
  // support call and a lost shift.
  final DateTime? insuranceExpiry;
  final DateTime? permitExpiry;
  final DateTime? fitnessExpiry;
  final DateTime? pucExpiry;

  String get displayName {
    final parts = [brand, model].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? vehicleNumber : parts.join(' ');
  }

  /// Credentials expiring within [days], soonest first. Drives the amber
  /// warning banner on the profile screen.
  List<({String label, DateTime expiry})> expiringWithin(int days) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    final all = <({String label, DateTime? expiry})>[
      (label: 'Insurance', expiry: insuranceExpiry),
      (label: 'Permit', expiry: permitExpiry),
      (label: 'Fitness certificate', expiry: fitnessExpiry),
      (label: 'PUC', expiry: pucExpiry),
    ];
    final due = <({String label, DateTime expiry})>[];
    for (final item in all) {
      final expiry = item.expiry;
      if (expiry != null && expiry.isBefore(cutoff)) {
        due.add((label: item.label, expiry: expiry));
      }
    }
    due.sort((a, b) => a.expiry.compareTo(b.expiry));
    return due;
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // The serializer nests the type as an object on some routes and a bare
    // string on others; accept both rather than guessing.
    final typeField = json['vehicle_type'] ?? json['vehicle_type_id'];
    final String? type;
    if (typeField is Map) {
      type = typeField['type']?.toString();
    } else {
      type = typeField?.toString();
    }

    return Vehicle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      vehicleType: type,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      year: (json['year'] as num?)?.toInt(),
      capacity: (json['capacity'] as num?)?.toInt(),
      status: json['status'] as String?,
      vehiclePic: json['vehicle_pic']?.toString(),
      insuranceExpiry: _date(json['insurance_expiry']),
      permitExpiry: _date(json['permit_expiry']),
      fitnessExpiry: _date(json['fitness_expiry']),
      pucExpiry: _date(json['puc_expiry']),
    );
  }
}

/// Where the driver stands with onboarding. Drives what the home screen is
/// allowed to offer: an unapproved driver must not see a "Go online" button
/// that the server will refuse anyway.
enum KycState { approved, pendingReview, documentsMissing, blocked }

/// `GET /driver/driver/profile/` — DriverProfileSerializer.
class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.approved,
    required this.status,
    this.totalTrips = 0,
    this.rating = 0,
    this.licenseDoc,
    this.licenseExpiry,
    this.activeVehicle,
    this.upiId,
    this.fatigueLockoutUntil,
  });

  final int id;
  final bool approved;

  /// Server-side status: online / off / active / on ride / off ride / blocked.
  final String status;
  final int totalTrips;
  final double rating;
  final String? licenseDoc;
  final DateTime? licenseExpiry;
  final Vehicle? activeVehicle;
  final String? upiId;

  /// Set while the driver is inside an MVA-2020 fatigue lockout (12h in 24h)
  /// or a cancellation cooldown. The server refuses `accept` until it passes.
  final DateTime? fatigueLockoutUntil;

  bool get isBlocked => status.toLowerCase() == 'blocked';
  bool get hasVehicle => activeVehicle != null;
  bool get hasLicense => licenseDoc != null && licenseDoc!.isNotEmpty;

  bool get isLockedOut {
    final until = fatigueLockoutUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  Duration? get lockoutRemaining {
    final until = fatigueLockoutUntil;
    if (until == null || !until.isAfter(DateTime.now())) return null;
    return until.difference(DateTime.now());
  }

  KycState get kycState {
    if (isBlocked) return KycState.blocked;
    if (approved) return KycState.approved;
    if (!hasLicense || !hasVehicle) return KycState.documentsMissing;
    return KycState.pendingReview;
  }

  /// Everything the server checks inside the accept transaction, checked here
  /// too so the app can explain *why* the toggle is disabled instead of
  /// letting the driver flip it and get a rejection.
  String? get blockingReason {
    if (isBlocked) {
      return 'Your account is blocked. Contact support.';
    }
    if (!approved) {
      return 'Your documents are still being verified. You will be able to '
          'go online once they are approved.';
    }
    if (!hasVehicle) {
      return 'Add and activate a vehicle before going online.';
    }
    if (isLockedOut) {
      return 'You are in a cooldown. You can go back online shortly.';
    }
    return null;
  }

  bool get canGoOnline => blockingReason == null;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final vehicleJson = json['active_vehicle_details'];
    return DriverProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      approved: json['approved'] == true,
      status: json['status']?.toString() ?? 'off',
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
      rating: double.tryParse(json['ratings']?.toString() ?? '') ?? 0,
      licenseDoc: json['license_doc']?.toString(),
      licenseExpiry: json['license_expiry'] == null
          ? null
          : DateTime.tryParse(json['license_expiry'].toString()),
      activeVehicle: vehicleJson is Map<String, dynamic>
          ? Vehicle.fromJson(vehicleJson)
          : null,
      upiId: json['upi_id'] as String?,
      fatigueLockoutUntil: json['fatigue_lockout_until'] == null
          ? null
          : DateTime.tryParse(json['fatigue_lockout_until'].toString()),
    );
  }
}
