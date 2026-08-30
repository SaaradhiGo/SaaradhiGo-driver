// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningModel _$EarningModelFromJson(Map<String, dynamic> json) =>
    _EarningModel(
      id: (json['id'] as num).toInt(),
      tripId: (json['trip_id'] as num?)?.toInt(),
      amountCollected: json['amount_collected'] as String? ?? '0.00',
      platformFee: json['platform_fee'] as String? ?? '0.00',
      netEarning: json['net_earning'] as String? ?? '0.00',
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$EarningModelToJson(_EarningModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'amount_collected': instance.amountCollected,
      'platform_fee': instance.platformFee,
      'net_earning': instance.netEarning,
      'created_at': instance.createdAt,
    };
