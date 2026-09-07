import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_type_converters.dart';

part 'elite_status_model.freezed.dart';
part 'elite_status_model.g.dart';

enum EliteTier {
  silver,
  gold,
  platinum,
  diamond;

  String get displayName {
    switch (this) {
      case EliteTier.silver:
        return 'Silver Partner';
      case EliteTier.gold:
        return 'Gold Partner';
      case EliteTier.platinum:
        return 'Platinum Partner';
      case EliteTier.diamond:
        return 'Diamond Partner';
    }
  }

  Color get accentColor {
    switch (this) {
      case EliteTier.silver:
        return const Color(0xFFC0C0C0);
      case EliteTier.gold:
        return const Color(0xFFD4AF37);
      case EliteTier.platinum:
        return const Color(0xFFE5E4E2);
      case EliteTier.diamond:
        return const Color(0xFF70D6FF);
    }
  }

  static EliteTier fromString(String? raw) {
    final t = (raw ?? '').toLowerCase().trim();
    if (t.contains('diamond')) return EliteTier.diamond;
    if (t.contains('platinum')) return EliteTier.platinum;
    if (t.contains('gold')) return EliteTier.gold;
    return EliteTier.silver;
  }
}

@freezed
abstract class EliteStatusModel with _$EliteStatusModel {
  const EliteStatusModel._();

  const factory EliteStatusModel({
    @Default('Silver') String tier,
    @JsonKey(name: 'total_trips', fromJson: intFromJson)
    @Default(0)
    int totalTrips,
    @Default('5.0') String rating,
    @JsonKey(name: 'acceptance_rate') @Default('100%') String acceptanceRate,
    @JsonKey(name: 'cancellation_rate') @Default('0%') String cancellationRate,
    @JsonKey(name: 'next_tier') String? nextTier,
    @JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson)
    int? tripsToNextTier,
  }) = _EliteStatusModel;

  factory EliteStatusModel.fromJson(Map<String, dynamic> json) =>
      _$EliteStatusModelFromJson(json);

  EliteTier get tierEnum => EliteTier.fromString(tier);

  Color get accentColor => tierEnum.accentColor;

  double get ratingDouble => double.tryParse(rating.trim()) ?? 5.0;

  double get acceptanceRatePercent {
    final clean = acceptanceRate.replaceAll('%', '').trim();
    return double.tryParse(clean) ?? 100.0;
  }

  double get cancellationRatePercent {
    final clean = cancellationRate.replaceAll('%', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  bool get isRatingQualified => ratingDouble >= 4.7;
  bool get isAcceptanceQualified => acceptanceRatePercent >= 90.0;
  bool get isCancellationQualified => cancellationRatePercent <= 4.0;
}
