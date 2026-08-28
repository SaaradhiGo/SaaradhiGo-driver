import 'package:freezed_annotation/freezed_annotation.dart';

import 'picked_document.dart';

part 'vehicle_request_dto.freezed.dart';
part 'vehicle_request_dto.g.dart';

@freezed
abstract class VehicleRequestDto with _$VehicleRequestDto {
  const factory VehicleRequestDto({
    // Wire name is `vehicle_number` (API_Documentation_V2 §3.6); kept as
    // registrationNumber in the client for readability.
    @JsonKey(name: 'registration_number') required String registrationNumber,
    @JsonKey(name: 'vehicle_type') required String vehicleType,
    required String make,
    required String model,
    required int year,
    required String color,
    // The picked RC file is uploaded via presigned PUT and never serialized.
    @JsonKey(includeToJson: false, includeFromJson: false)
    PickedDocument? rcDocument,
    // Object key returned by the presign flow, submitted as `rc_doc`.
    @JsonKey(name: 'rc_doc') String? rcDocKey,
    // Optional vehicle photo (`vehicle_pic`, API_Documentation_V2 §3.6).
    // Picked on the form and uploaded after creation; never serialized with
    // the create payload.
    @JsonKey(includeToJson: false, includeFromJson: false)
    PickedDocument? vehiclePicDocument,
    // Client-only control: when false the repository skips the
    // `active_vehicle` PATCH after creation (null behaves as true).
    @JsonKey(includeToJson: false, includeFromJson: false) bool? setAsActive,
  }) = _VehicleRequestDto;

  factory VehicleRequestDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleRequestDtoFromJson(json);
}
