import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'sos_alert_model.freezed.dart';
part 'sos_alert_model.g.dart';

/// Acknowledgement returned by `POST /sos/`.
///
/// The API documentation (6.1) does not specify a response body, so decoding
/// is tolerant: a successful request is the source of truth for the UI, and
/// these fields only enrich the confirmation shown to the driver when the
/// backend happens to echo them.
@freezed
abstract class SosAlertModel with _$SosAlertModel {
  const factory SosAlertModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson) int? tripId,
    String? status,
    @JsonKey(name: 'latitude', fromJson: doubleFromJson) double? latitude,
    @JsonKey(name: 'longitude', fromJson: doubleFromJson) double? longitude,
    String? message,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _SosAlertModel;

  factory SosAlertModel.fromJson(Map<String, dynamic> json) =>
      _$SosAlertModelFromJson(json);
}
