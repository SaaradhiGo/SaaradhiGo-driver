// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningModel _$EarningModelFromJson(Map<String, dynamic> json) =>
    _EarningModel(
      id: json['id'] == null ? 0 : intFromJson(json['id']),
      tripId: nullableIntFromJson(_readTripId(json, 'trip_id')),
      amountCollected: nullableMoneyFromJson(
        _readGross(json, 'amount_collected'),
      ),
      platformFee: nullableMoneyFromJson(_readCommission(json, 'platform_fee')),
      netEarning: nullableMoneyFromJson(_readNet(json, 'net_earning')),
      commissionPercent: nullableNumFromJson(json['commission_percent']),
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$EarningModelToJson(_EarningModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'amount_collected': instance.amountCollected,
      'platform_fee': instance.platformFee,
      'net_earning': instance.netEarning,
      'commission_percent': instance.commissionPercent,
      'created_at': instance.createdAt,
    };
