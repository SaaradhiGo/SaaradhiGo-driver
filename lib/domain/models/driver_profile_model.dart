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
    required int id,
    UserModel? user,
    required DriverStatus status,
    required bool approved,
    @JsonKey(name: 'kyc_status') String? kycStatus,
    @JsonKey(name: 'license_doc') String? licenseDoc,
    @JsonKey(name: 'license_expiry') DateTime? licenseExpiry,
    @JsonKey(name: 'active_vehicle') int? activeVehicle,
    @JsonKey(name: 'active_vehicle_details')
    Map<String, dynamic>? activeVehicleDetails,
    @JsonKey(name: 'total_trips') int? totalTrips,
    @StringDoubleConverter() double? ratings,
  }) = _DriverProfileModel;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileModelFromJson(json);
}
