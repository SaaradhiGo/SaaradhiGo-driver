import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';

part 'driver_profile_model.freezed.dart';
part 'driver_profile_model.g.dart';

enum DriverStatus {
  @JsonValue('online')
  online,
  @JsonValue('offline')
  offline,
  @JsonValue('off')
  off,
}

class UserOrIdConverter implements JsonConverter<UserModel?, dynamic> {
  const UserOrIdConverter();

  @override
  UserModel? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return UserModel.fromJson(json);
    }
    if (json is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(json));
    }
    if (json is int) {
      return UserModel(id: json);
    }
    return null;
  }

  @override
  dynamic toJson(UserModel? object) => object?.toJson();
}

class SafeBoolConverter implements JsonConverter<bool, dynamic> {
  const SafeBoolConverter();

  @override
  bool fromJson(dynamic json) {
    if (json == null) return false;
    if (json is bool) return json;
    if (json is num) return json != 0;
    if (json is String) return json.toLowerCase() == 'true' || json == '1';
    return false;
  }

  @override
  dynamic toJson(bool object) => object;
}

class SafeDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const SafeDateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) {
      if (json.isEmpty) return null;
      return DateTime.tryParse(json);
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? object) => object?.toIso8601String();
}

class StringDoubleConverter implements JsonConverter<double?, dynamic> {
  const StringDoubleConverter();

  @override
  double? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is double) return json;
    if (json is int) return json.toDouble();
    if (json is String) {
      if (json == 'N/A') return null;
      return double.tryParse(json);
    }
    return null;
  }

  @override
  dynamic toJson(double? object) {
    if (object == null) return null;
    return object.toString();
  }
}

@freezed
abstract class DriverProfileModel with _$DriverProfileModel {
  const factory DriverProfileModel({
    @Default(0) int id,
    @UserOrIdConverter() UserModel? user,
    @JsonKey(unknownEnumValue: DriverStatus.offline)
    @Default(DriverStatus.offline)
    DriverStatus status,
    @SafeBoolConverter() @Default(false) bool approved,
    /// MAY THIS DRIVER OPERATE RIGHT NOW.
    ///
    /// Not the same question as `approved`, which means a human reviewed
    /// real documents. The backend computes this from the same rule its
    /// dispatch sockets use, so the app and the server stop disagreeing: a
    /// QA test driver with simulated eligibility used to be accepted by the
    /// sockets and sent to the onboarding wizard by this app at the same
    /// time.
    ///
    /// Defaults to false, so a build talking to a backend that does not send
    /// it behaves exactly as before.
    @SafeBoolConverter()
    @Default(false)
    @JsonKey(name: 'dispatch_eligible')
    bool dispatchEligible,
    @JsonKey(name: 'kyc_status') String? kycStatus,
    @JsonKey(name: 'license_doc') String? licenseDoc,
    @JsonKey(name: 'license_doc_back') String? licenseDocBack,
    @SafeDateTimeConverter()
    @JsonKey(name: 'license_expiry')
    DateTime? licenseExpiry,
    @JsonKey(name: 'active_vehicle') int? activeVehicle,
    @JsonKey(name: 'active_vehicle_details')
    Map<String, dynamic>? activeVehicleDetails,
    @JsonKey(name: 'total_trips') int? totalTrips,
    @StringDoubleConverter() double? ratings,
  }) = _DriverProfileModel;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileModelFromJson(json);
}
