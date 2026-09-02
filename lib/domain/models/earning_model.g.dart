// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningModel _$EarningModelFromJson(Map<String, dynamic> json) =>
    _EarningModel(
      id: json['id'] == null ? 0 : intFromJson(json['id']),
      tripId: nullableIntFromJson(json['trip_id']),
      amountCollected: json['amount_collected'] == null
          ? '0.00'
          : moneyFromJson(json['amount_collected']),
      platformFee: json['platform_fee'] == null
          ? '0.00'
          : moneyFromJson(json['platform_fee']),
      netEarning: json['net_earning'] == null
          ? '0.00'
          : moneyFromJson(json['net_earning']),
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
