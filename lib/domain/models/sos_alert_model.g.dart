// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_alert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SosAlertModel _$SosAlertModelFromJson(Map<String, dynamic> json) =>
    _SosAlertModel(
      id: json['id'] == null ? 0 : intFromJson(json['id']),
      tripId: nullableIntFromJson(json['trip_id']),
      status: json['status'] as String?,
      latitude: doubleFromJson(json['latitude']),
      longitude: doubleFromJson(json['longitude']),
      message: json['message'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$SosAlertModelToJson(_SosAlertModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'status': instance.status,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'message': instance.message,
      'created_at': instance.createdAt,
    };
