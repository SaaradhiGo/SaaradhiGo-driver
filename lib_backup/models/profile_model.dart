class UserProfileModel {
  final int id;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? dob;
  final String? city;
  final String? houseNo;
  final String? street;
  final String? zipCode;
  final String? avatar;
  final String? createdAt;

  UserProfileModel({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.dob,
    this.city,
    this.houseNo,
    this.street,
    this.zipCode,
    this.avatar,
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final avatarStr = json['avatar']?.toString();
    return UserProfileModel(
      id: json['id'] ?? 0,
      fullName: json['full_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      email: json['email']?.toString(),
      dob: json['dob']?.toString(),
      city: json['city']?.toString(),
      houseNo: json['house_no']?.toString(),
      street: json['street']?.toString(),
      zipCode: json['zip_code']?.toString(),
      avatar: (avatarStr == null || avatarStr.trim().isEmpty)
          ? null
          : avatarStr,
      createdAt: json['created_at']?.toString(),
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (houseNo != null && houseNo!.isNotEmpty) parts.add(houseNo!);
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.join(', ');
  }
}

class DriverProfileModel {
  final int id;
  final String status;
  final bool approved;
  final String? licenseExpiry;
  final String? ratings;
  final String? licenseDoc;
  final dynamic activeVehicleDetails;

  DriverProfileModel({
    required this.id,
    required this.status,
    required this.approved,
    this.licenseExpiry,
    this.ratings,
    this.licenseDoc,
    this.activeVehicleDetails,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      id: json['id'] ?? 0,
      status: json['status']?.toString() ?? 'offline',
      approved: json['approved'] ?? false,
      licenseExpiry: json['license_expiry']?.toString(),
      ratings: json['ratings']?.toString(),
      licenseDoc: json['license_doc']?.toString(),
      activeVehicleDetails:
          json['active_vehicle_details'] ?? json['active_vehicle'],
    );
  }

  bool get hasActiveVehicle => activeVehicleDetails != null;
  bool get hasLicense => licenseDoc != null && licenseDoc!.isNotEmpty;
}
