// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earnings_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EarningsSummaryModel {

@JsonKey(name: 'total_earned', fromJson: moneyFromJson) String get totalEarned;@JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson) String? get totalCommission;@JsonKey(name: 'total_trips', fromJson: intFromJson) int get totalTrips;@JsonKey(name: 'today_earned', fromJson: moneyFromJson) String get todayEarned;@JsonKey(name: 'today_trips', fromJson: intFromJson) int get todayTrips;@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) num? get commissionPercent;@JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson) bool? get commissionPercentMixed;@JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson) String? get totalNet;@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? get promoPaidByPlatform;@JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? get todayPromoPaidByPlatform;@JsonKey(name: 'promo_paid_label') String? get promoPaidLabel;@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) String? get taxCollected;@JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson) String? get regulatoryFeesCollected;@JsonKey(name: 'tax_collected_label') String? get taxCollectedLabel;@JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson) String? get incentiveRewards;@JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson) String? get referralRewards;@JsonKey(name: 'incentive_commission') String? get incentiveCommission;@JsonKey(name: 'incentive_tax') String? get incentiveTax;
/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningsSummaryModelCopyWith<EarningsSummaryModel> get copyWith => _$EarningsSummaryModelCopyWithImpl<EarningsSummaryModel>(this as EarningsSummaryModel, _$identity);

  /// Serializes this EarningsSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarningsSummaryModel&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.totalCommission, totalCommission) || other.totalCommission == totalCommission)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.todayEarned, todayEarned) || other.todayEarned == todayEarned)&&(identical(other.todayTrips, todayTrips) || other.todayTrips == todayTrips)&&(identical(other.commissionPercent, commissionPercent) || other.commissionPercent == commissionPercent)&&(identical(other.commissionPercentMixed, commissionPercentMixed) || other.commissionPercentMixed == commissionPercentMixed)&&(identical(other.totalNet, totalNet) || other.totalNet == totalNet)&&(identical(other.promoPaidByPlatform, promoPaidByPlatform) || other.promoPaidByPlatform == promoPaidByPlatform)&&(identical(other.todayPromoPaidByPlatform, todayPromoPaidByPlatform) || other.todayPromoPaidByPlatform == todayPromoPaidByPlatform)&&(identical(other.promoPaidLabel, promoPaidLabel) || other.promoPaidLabel == promoPaidLabel)&&(identical(other.taxCollected, taxCollected) || other.taxCollected == taxCollected)&&(identical(other.regulatoryFeesCollected, regulatoryFeesCollected) || other.regulatoryFeesCollected == regulatoryFeesCollected)&&(identical(other.taxCollectedLabel, taxCollectedLabel) || other.taxCollectedLabel == taxCollectedLabel)&&(identical(other.incentiveRewards, incentiveRewards) || other.incentiveRewards == incentiveRewards)&&(identical(other.referralRewards, referralRewards) || other.referralRewards == referralRewards)&&(identical(other.incentiveCommission, incentiveCommission) || other.incentiveCommission == incentiveCommission)&&(identical(other.incentiveTax, incentiveTax) || other.incentiveTax == incentiveTax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEarned,totalCommission,totalTrips,todayEarned,todayTrips,commissionPercent,commissionPercentMixed,totalNet,promoPaidByPlatform,todayPromoPaidByPlatform,promoPaidLabel,taxCollected,regulatoryFeesCollected,taxCollectedLabel,incentiveRewards,referralRewards,incentiveCommission,incentiveTax);

@override
String toString() {
  return 'EarningsSummaryModel(totalEarned: $totalEarned, totalCommission: $totalCommission, totalTrips: $totalTrips, todayEarned: $todayEarned, todayTrips: $todayTrips, commissionPercent: $commissionPercent, commissionPercentMixed: $commissionPercentMixed, totalNet: $totalNet, promoPaidByPlatform: $promoPaidByPlatform, todayPromoPaidByPlatform: $todayPromoPaidByPlatform, promoPaidLabel: $promoPaidLabel, taxCollected: $taxCollected, regulatoryFeesCollected: $regulatoryFeesCollected, taxCollectedLabel: $taxCollectedLabel, incentiveRewards: $incentiveRewards, referralRewards: $referralRewards, incentiveCommission: $incentiveCommission, incentiveTax: $incentiveTax)';
}


}

/// @nodoc
abstract mixin class $EarningsSummaryModelCopyWith<$Res>  {
  factory $EarningsSummaryModelCopyWith(EarningsSummaryModel value, $Res Function(EarningsSummaryModel) _then) = _$EarningsSummaryModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_earned', fromJson: moneyFromJson) String totalEarned,@JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson) String? totalCommission,@JsonKey(name: 'total_trips', fromJson: intFromJson) int totalTrips,@JsonKey(name: 'today_earned', fromJson: moneyFromJson) String todayEarned,@JsonKey(name: 'today_trips', fromJson: intFromJson) int todayTrips,@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) num? commissionPercent,@JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson) bool? commissionPercentMixed,@JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson) String? totalNet,@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? promoPaidByPlatform,@JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? todayPromoPaidByPlatform,@JsonKey(name: 'promo_paid_label') String? promoPaidLabel,@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) String? taxCollected,@JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson) String? regulatoryFeesCollected,@JsonKey(name: 'tax_collected_label') String? taxCollectedLabel,@JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson) String? incentiveRewards,@JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson) String? referralRewards,@JsonKey(name: 'incentive_commission') String? incentiveCommission,@JsonKey(name: 'incentive_tax') String? incentiveTax
});




}
/// @nodoc
class _$EarningsSummaryModelCopyWithImpl<$Res>
    implements $EarningsSummaryModelCopyWith<$Res> {
  _$EarningsSummaryModelCopyWithImpl(this._self, this._then);

  final EarningsSummaryModel _self;
  final $Res Function(EarningsSummaryModel) _then;

/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalEarned = null,Object? totalCommission = freezed,Object? totalTrips = null,Object? todayEarned = null,Object? todayTrips = null,Object? commissionPercent = freezed,Object? commissionPercentMixed = freezed,Object? totalNet = freezed,Object? promoPaidByPlatform = freezed,Object? todayPromoPaidByPlatform = freezed,Object? promoPaidLabel = freezed,Object? taxCollected = freezed,Object? regulatoryFeesCollected = freezed,Object? taxCollectedLabel = freezed,Object? incentiveRewards = freezed,Object? referralRewards = freezed,Object? incentiveCommission = freezed,Object? incentiveTax = freezed,}) {
  return _then(EarningsSummaryModel(
totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as String,totalCommission: freezed == totalCommission ? _self.totalCommission : totalCommission // ignore: cast_nullable_to_non_nullable
as String?,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,todayEarned: null == todayEarned ? _self.todayEarned : todayEarned // ignore: cast_nullable_to_non_nullable
as String,todayTrips: null == todayTrips ? _self.todayTrips : todayTrips // ignore: cast_nullable_to_non_nullable
as int,commissionPercent: freezed == commissionPercent ? _self.commissionPercent : commissionPercent // ignore: cast_nullable_to_non_nullable
as num?,commissionPercentMixed: freezed == commissionPercentMixed ? _self.commissionPercentMixed : commissionPercentMixed // ignore: cast_nullable_to_non_nullable
as bool?,totalNet: freezed == totalNet ? _self.totalNet : totalNet // ignore: cast_nullable_to_non_nullable
as String?,promoPaidByPlatform: freezed == promoPaidByPlatform ? _self.promoPaidByPlatform : promoPaidByPlatform // ignore: cast_nullable_to_non_nullable
as String?,todayPromoPaidByPlatform: freezed == todayPromoPaidByPlatform ? _self.todayPromoPaidByPlatform : todayPromoPaidByPlatform // ignore: cast_nullable_to_non_nullable
as String?,promoPaidLabel: freezed == promoPaidLabel ? _self.promoPaidLabel : promoPaidLabel // ignore: cast_nullable_to_non_nullable
as String?,taxCollected: freezed == taxCollected ? _self.taxCollected : taxCollected // ignore: cast_nullable_to_non_nullable
as String?,regulatoryFeesCollected: freezed == regulatoryFeesCollected ? _self.regulatoryFeesCollected : regulatoryFeesCollected // ignore: cast_nullable_to_non_nullable
as String?,taxCollectedLabel: freezed == taxCollectedLabel ? _self.taxCollectedLabel : taxCollectedLabel // ignore: cast_nullable_to_non_nullable
as String?,incentiveRewards: freezed == incentiveRewards ? _self.incentiveRewards : incentiveRewards // ignore: cast_nullable_to_non_nullable
as String?,referralRewards: freezed == referralRewards ? _self.referralRewards : referralRewards // ignore: cast_nullable_to_non_nullable
as String?,incentiveCommission: freezed == incentiveCommission ? _self.incentiveCommission : incentiveCommission // ignore: cast_nullable_to_non_nullable
as String?,incentiveTax: freezed == incentiveTax ? _self.incentiveTax : incentiveTax // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EarningsSummaryModel].
extension EarningsSummaryModelPatterns on EarningsSummaryModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarningsSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarningsSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _EarningsSummaryModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarningsSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_earned', fromJson: moneyFromJson)  String totalEarned, @JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson)  String? totalCommission, @JsonKey(name: 'total_trips', fromJson: intFromJson)  int totalTrips, @JsonKey(name: 'today_earned', fromJson: moneyFromJson)  String todayEarned, @JsonKey(name: 'today_trips', fromJson: intFromJson)  int todayTrips, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)  num? commissionPercent, @JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson)  bool? commissionPercentMixed, @JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson)  String? totalNet, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? promoPaidByPlatform, @JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? todayPromoPaidByPlatform, @JsonKey(name: 'promo_paid_label')  String? promoPaidLabel, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)  String? taxCollected, @JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson)  String? regulatoryFeesCollected, @JsonKey(name: 'tax_collected_label')  String? taxCollectedLabel, @JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson)  String? incentiveRewards, @JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson)  String? referralRewards, @JsonKey(name: 'incentive_commission')  String? incentiveCommission, @JsonKey(name: 'incentive_tax')  String? incentiveTax)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
return $default(_that.totalEarned,_that.totalCommission,_that.totalTrips,_that.todayEarned,_that.todayTrips,_that.commissionPercent,_that.commissionPercentMixed,_that.totalNet,_that.promoPaidByPlatform,_that.todayPromoPaidByPlatform,_that.promoPaidLabel,_that.taxCollected,_that.regulatoryFeesCollected,_that.taxCollectedLabel,_that.incentiveRewards,_that.referralRewards,_that.incentiveCommission,_that.incentiveTax);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_earned', fromJson: moneyFromJson)  String totalEarned, @JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson)  String? totalCommission, @JsonKey(name: 'total_trips', fromJson: intFromJson)  int totalTrips, @JsonKey(name: 'today_earned', fromJson: moneyFromJson)  String todayEarned, @JsonKey(name: 'today_trips', fromJson: intFromJson)  int todayTrips, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)  num? commissionPercent, @JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson)  bool? commissionPercentMixed, @JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson)  String? totalNet, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? promoPaidByPlatform, @JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? todayPromoPaidByPlatform, @JsonKey(name: 'promo_paid_label')  String? promoPaidLabel, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)  String? taxCollected, @JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson)  String? regulatoryFeesCollected, @JsonKey(name: 'tax_collected_label')  String? taxCollectedLabel, @JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson)  String? incentiveRewards, @JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson)  String? referralRewards, @JsonKey(name: 'incentive_commission')  String? incentiveCommission, @JsonKey(name: 'incentive_tax')  String? incentiveTax)  $default,) {final _that = this;
switch (_that) {
case _EarningsSummaryModel():
return $default(_that.totalEarned,_that.totalCommission,_that.totalTrips,_that.todayEarned,_that.todayTrips,_that.commissionPercent,_that.commissionPercentMixed,_that.totalNet,_that.promoPaidByPlatform,_that.todayPromoPaidByPlatform,_that.promoPaidLabel,_that.taxCollected,_that.regulatoryFeesCollected,_that.taxCollectedLabel,_that.incentiveRewards,_that.referralRewards,_that.incentiveCommission,_that.incentiveTax);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_earned', fromJson: moneyFromJson)  String totalEarned, @JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson)  String? totalCommission, @JsonKey(name: 'total_trips', fromJson: intFromJson)  int totalTrips, @JsonKey(name: 'today_earned', fromJson: moneyFromJson)  String todayEarned, @JsonKey(name: 'today_trips', fromJson: intFromJson)  int todayTrips, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)  num? commissionPercent, @JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson)  bool? commissionPercentMixed, @JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson)  String? totalNet, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? promoPaidByPlatform, @JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? todayPromoPaidByPlatform, @JsonKey(name: 'promo_paid_label')  String? promoPaidLabel, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)  String? taxCollected, @JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson)  String? regulatoryFeesCollected, @JsonKey(name: 'tax_collected_label')  String? taxCollectedLabel, @JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson)  String? incentiveRewards, @JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson)  String? referralRewards, @JsonKey(name: 'incentive_commission')  String? incentiveCommission, @JsonKey(name: 'incentive_tax')  String? incentiveTax)?  $default,) {final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
return $default(_that.totalEarned,_that.totalCommission,_that.totalTrips,_that.todayEarned,_that.todayTrips,_that.commissionPercent,_that.commissionPercentMixed,_that.totalNet,_that.promoPaidByPlatform,_that.todayPromoPaidByPlatform,_that.promoPaidLabel,_that.taxCollected,_that.regulatoryFeesCollected,_that.taxCollectedLabel,_that.incentiveRewards,_that.referralRewards,_that.incentiveCommission,_that.incentiveTax);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarningsSummaryModel implements EarningsSummaryModel {
  const _EarningsSummaryModel({@JsonKey(name: 'total_earned', fromJson: moneyFromJson) this.totalEarned = '0.00', @JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson) this.totalCommission, @JsonKey(name: 'total_trips', fromJson: intFromJson) this.totalTrips = 0, @JsonKey(name: 'today_earned', fromJson: moneyFromJson) this.todayEarned = '0.00', @JsonKey(name: 'today_trips', fromJson: intFromJson) this.todayTrips = 0, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) this.commissionPercent, @JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson) this.commissionPercentMixed, @JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson) this.totalNet, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) this.promoPaidByPlatform, @JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson) this.todayPromoPaidByPlatform, @JsonKey(name: 'promo_paid_label') this.promoPaidLabel, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) this.taxCollected, @JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson) this.regulatoryFeesCollected, @JsonKey(name: 'tax_collected_label') this.taxCollectedLabel, @JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson) this.incentiveRewards, @JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson) this.referralRewards, @JsonKey(name: 'incentive_commission') this.incentiveCommission, @JsonKey(name: 'incentive_tax') this.incentiveTax});
  factory _EarningsSummaryModel.fromJson(Map<String, dynamic> json) => _$EarningsSummaryModelFromJson(json);

@override@JsonKey(name: 'total_earned', fromJson: moneyFromJson) final  String totalEarned;
@override@JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson) final  String? totalCommission;
@override@JsonKey(name: 'total_trips', fromJson: intFromJson) final  int totalTrips;
@override@JsonKey(name: 'today_earned', fromJson: moneyFromJson) final  String todayEarned;
@override@JsonKey(name: 'today_trips', fromJson: intFromJson) final  int todayTrips;
@override@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) final  num? commissionPercent;
@override@JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson) final  bool? commissionPercentMixed;
@override@JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson) final  String? totalNet;
@override@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) final  String? promoPaidByPlatform;
@override@JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson) final  String? todayPromoPaidByPlatform;
@override@JsonKey(name: 'promo_paid_label') final  String? promoPaidLabel;
@override@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) final  String? taxCollected;
@override@JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson) final  String? regulatoryFeesCollected;
@override@JsonKey(name: 'tax_collected_label') final  String? taxCollectedLabel;
@override@JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson) final  String? incentiveRewards;
@override@JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson) final  String? referralRewards;
@override@JsonKey(name: 'incentive_commission') final  String? incentiveCommission;
@override@JsonKey(name: 'incentive_tax') final  String? incentiveTax;

/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningsSummaryModelCopyWith<_EarningsSummaryModel> get copyWith => __$EarningsSummaryModelCopyWithImpl<_EarningsSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarningsSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarningsSummaryModel&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.totalCommission, totalCommission) || other.totalCommission == totalCommission)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.todayEarned, todayEarned) || other.todayEarned == todayEarned)&&(identical(other.todayTrips, todayTrips) || other.todayTrips == todayTrips)&&(identical(other.commissionPercent, commissionPercent) || other.commissionPercent == commissionPercent)&&(identical(other.commissionPercentMixed, commissionPercentMixed) || other.commissionPercentMixed == commissionPercentMixed)&&(identical(other.totalNet, totalNet) || other.totalNet == totalNet)&&(identical(other.promoPaidByPlatform, promoPaidByPlatform) || other.promoPaidByPlatform == promoPaidByPlatform)&&(identical(other.todayPromoPaidByPlatform, todayPromoPaidByPlatform) || other.todayPromoPaidByPlatform == todayPromoPaidByPlatform)&&(identical(other.promoPaidLabel, promoPaidLabel) || other.promoPaidLabel == promoPaidLabel)&&(identical(other.taxCollected, taxCollected) || other.taxCollected == taxCollected)&&(identical(other.regulatoryFeesCollected, regulatoryFeesCollected) || other.regulatoryFeesCollected == regulatoryFeesCollected)&&(identical(other.taxCollectedLabel, taxCollectedLabel) || other.taxCollectedLabel == taxCollectedLabel)&&(identical(other.incentiveRewards, incentiveRewards) || other.incentiveRewards == incentiveRewards)&&(identical(other.referralRewards, referralRewards) || other.referralRewards == referralRewards)&&(identical(other.incentiveCommission, incentiveCommission) || other.incentiveCommission == incentiveCommission)&&(identical(other.incentiveTax, incentiveTax) || other.incentiveTax == incentiveTax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEarned,totalCommission,totalTrips,todayEarned,todayTrips,commissionPercent,commissionPercentMixed,totalNet,promoPaidByPlatform,todayPromoPaidByPlatform,promoPaidLabel,taxCollected,regulatoryFeesCollected,taxCollectedLabel,incentiveRewards,referralRewards,incentiveCommission,incentiveTax);

@override
String toString() {
  return 'EarningsSummaryModel(totalEarned: $totalEarned, totalCommission: $totalCommission, totalTrips: $totalTrips, todayEarned: $todayEarned, todayTrips: $todayTrips, commissionPercent: $commissionPercent, commissionPercentMixed: $commissionPercentMixed, totalNet: $totalNet, promoPaidByPlatform: $promoPaidByPlatform, todayPromoPaidByPlatform: $todayPromoPaidByPlatform, promoPaidLabel: $promoPaidLabel, taxCollected: $taxCollected, regulatoryFeesCollected: $regulatoryFeesCollected, taxCollectedLabel: $taxCollectedLabel, incentiveRewards: $incentiveRewards, referralRewards: $referralRewards, incentiveCommission: $incentiveCommission, incentiveTax: $incentiveTax)';
}


}

/// @nodoc
abstract mixin class _$EarningsSummaryModelCopyWith<$Res> implements $EarningsSummaryModelCopyWith<$Res> {
  factory _$EarningsSummaryModelCopyWith(_EarningsSummaryModel value, $Res Function(_EarningsSummaryModel) _then) = __$EarningsSummaryModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_earned', fromJson: moneyFromJson) String totalEarned,@JsonKey(name: 'total_commission', fromJson: nullableMoneyFromJson) String? totalCommission,@JsonKey(name: 'total_trips', fromJson: intFromJson) int totalTrips,@JsonKey(name: 'today_earned', fromJson: moneyFromJson) String todayEarned,@JsonKey(name: 'today_trips', fromJson: intFromJson) int todayTrips,@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) num? commissionPercent,@JsonKey(name: 'commission_percent_mixed', fromJson: nullableBoolFromJson) bool? commissionPercentMixed,@JsonKey(name: 'total_net', fromJson: nullableMoneyFromJson) String? totalNet,@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? promoPaidByPlatform,@JsonKey(name: 'today_promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? todayPromoPaidByPlatform,@JsonKey(name: 'promo_paid_label') String? promoPaidLabel,@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) String? taxCollected,@JsonKey(name: 'regulatory_fees_collected', fromJson: nullableMoneyFromJson) String? regulatoryFeesCollected,@JsonKey(name: 'tax_collected_label') String? taxCollectedLabel,@JsonKey(name: 'incentive_rewards', fromJson: nullableMoneyFromJson) String? incentiveRewards,@JsonKey(name: 'referral_rewards', fromJson: nullableMoneyFromJson) String? referralRewards,@JsonKey(name: 'incentive_commission') String? incentiveCommission,@JsonKey(name: 'incentive_tax') String? incentiveTax
});




}
/// @nodoc
class __$EarningsSummaryModelCopyWithImpl<$Res>
    implements _$EarningsSummaryModelCopyWith<$Res> {
  __$EarningsSummaryModelCopyWithImpl(this._self, this._then);

  final _EarningsSummaryModel _self;
  final $Res Function(_EarningsSummaryModel) _then;

/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalEarned = null,Object? totalCommission = freezed,Object? totalTrips = null,Object? todayEarned = null,Object? todayTrips = null,Object? commissionPercent = freezed,Object? commissionPercentMixed = freezed,Object? totalNet = freezed,Object? promoPaidByPlatform = freezed,Object? todayPromoPaidByPlatform = freezed,Object? promoPaidLabel = freezed,Object? taxCollected = freezed,Object? regulatoryFeesCollected = freezed,Object? taxCollectedLabel = freezed,Object? incentiveRewards = freezed,Object? referralRewards = freezed,Object? incentiveCommission = freezed,Object? incentiveTax = freezed,}) {
  return _then(_EarningsSummaryModel(
totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as String,totalCommission: freezed == totalCommission ? _self.totalCommission : totalCommission // ignore: cast_nullable_to_non_nullable
as String?,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,todayEarned: null == todayEarned ? _self.todayEarned : todayEarned // ignore: cast_nullable_to_non_nullable
as String,todayTrips: null == todayTrips ? _self.todayTrips : todayTrips // ignore: cast_nullable_to_non_nullable
as int,commissionPercent: freezed == commissionPercent ? _self.commissionPercent : commissionPercent // ignore: cast_nullable_to_non_nullable
as num?,commissionPercentMixed: freezed == commissionPercentMixed ? _self.commissionPercentMixed : commissionPercentMixed // ignore: cast_nullable_to_non_nullable
as bool?,totalNet: freezed == totalNet ? _self.totalNet : totalNet // ignore: cast_nullable_to_non_nullable
as String?,promoPaidByPlatform: freezed == promoPaidByPlatform ? _self.promoPaidByPlatform : promoPaidByPlatform // ignore: cast_nullable_to_non_nullable
as String?,todayPromoPaidByPlatform: freezed == todayPromoPaidByPlatform ? _self.todayPromoPaidByPlatform : todayPromoPaidByPlatform // ignore: cast_nullable_to_non_nullable
as String?,promoPaidLabel: freezed == promoPaidLabel ? _self.promoPaidLabel : promoPaidLabel // ignore: cast_nullable_to_non_nullable
as String?,taxCollected: freezed == taxCollected ? _self.taxCollected : taxCollected // ignore: cast_nullable_to_non_nullable
as String?,regulatoryFeesCollected: freezed == regulatoryFeesCollected ? _self.regulatoryFeesCollected : regulatoryFeesCollected // ignore: cast_nullable_to_non_nullable
as String?,taxCollectedLabel: freezed == taxCollectedLabel ? _self.taxCollectedLabel : taxCollectedLabel // ignore: cast_nullable_to_non_nullable
as String?,incentiveRewards: freezed == incentiveRewards ? _self.incentiveRewards : incentiveRewards // ignore: cast_nullable_to_non_nullable
as String?,referralRewards: freezed == referralRewards ? _self.referralRewards : referralRewards // ignore: cast_nullable_to_non_nullable
as String?,incentiveCommission: freezed == incentiveCommission ? _self.incentiveCommission : incentiveCommission // ignore: cast_nullable_to_non_nullable
as String?,incentiveTax: freezed == incentiveTax ? _self.incentiveTax : incentiveTax // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
