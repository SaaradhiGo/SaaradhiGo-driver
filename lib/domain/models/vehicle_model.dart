import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_model.freezed.dart';
part 'vehicle_model.g.dart';

class VehicleTypeConverter implements JsonConverter<String, dynamic> {
  const VehicleTypeConverter();

  @override
  String fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json['type'] as String? ?? 'unknown';
    }
    if (json is String) {
      return json;
    }
    return 'unknown';
  }

  @override
  dynamic toJson(String object) {
    return object;
  }
}

@freezed
abstract class VehicleModel with _$VehicleModel {
  const factory VehicleModel({
    required int id,
    @JsonKey(name: 'vehicle_number') required String vehicleNumber,
    @VehicleTypeConverter()
    @JsonKey(name: 'vehicle_type')
    required String vehicleType,
    String? brand,
    String? model,
    String? color,
    int? year,
    int? capacity,
    String? status,
    @JsonKey(name: 'rc_doc') String? rcDoc,
    @JsonKey(name: 'vehicle_pic') String? vehiclePic,
    @JsonKey(name: 'fuel_type') String? fuelType,
    @JsonKey(name: 'insurance_doc') String? insuranceDoc,
    @JsonKey(name: 'insurance_expiry') DateTime? insuranceExpiry,
    @JsonKey(name: 'fitness_expiry') DateTime? fitnessExpiry,
  }) = _VehicleModel;

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);
}
