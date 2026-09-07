// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'elite_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EliteStatusModel _$EliteStatusModelFromJson(Map<String, dynamic> json) =>
    _EliteStatusModel(
      tier: json['tier'] as String? ?? 'Silver',
      totalTrips: json['total_trips'] == null
          ? 0
          : intFromJson(json['total_trips']),
      rating: json['rating'] as String? ?? '5.0',
      acceptanceRate: json['acceptance_rate'] as String? ?? '100%',
      cancellationRate: json['cancellation_rate'] as String? ?? '0%',
      nextTier: json['next_tier'] as String?,
      tripsToNextTier: nullableIntFromJson(json['trips_to_next_tier']),
    );

Map<String, dynamic> _$EliteStatusModelToJson(_EliteStatusModel instance) =>
    <String, dynamic>{
      'tier': instance.tier,
      'total_trips': instance.totalTrips,
      'rating': instance.rating,
      'acceptance_rate': instance.acceptanceRate,
      'cancellation_rate': instance.cancellationRate,
      'next_tier': instance.nextTier,
      'trips_to_next_tier': instance.tripsToNextTier,
    };
