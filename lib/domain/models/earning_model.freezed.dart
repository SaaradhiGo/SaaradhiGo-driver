// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earning_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EarningModel {

@JsonKey(fromJson: intFromJson) int get id;@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId) int? get tripId;@JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross) String? get amountCollected;@JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission) String? get platformFee;@JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet) String? get netEarning;@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) num? get commissionPercent;@JsonKey(name: 'created_at') String? get createdAt;/// `cash`/`online`, as the API labels the trip.
 String? get method;@JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson) bool? get cashInHand;/// What a cash driver collects from the rider (the fare less a promo, plus
/// a US trip's tax and fee). Null on an online trip.
@JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson) String? get cashToCollect;@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? get promoPaidByPlatform;@JsonKey(name: 'promo_paid_label') String? get promoPaidLabel;@JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson) bool? get promoCreditedToWallet;/// US only: collected for remittance, never earnings.
@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) String? get taxCollected;@JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson) String? get regulatoryFeeCollected;@JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson) List<EarningDeduction> get deductions;
/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningModelCopyWith<EarningModel> get copyWith => _$EarningModelCopyWithImpl<EarningModel>(this as EarningModel, _$identity);

  /// Serializes this EarningModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.amountCollected, amountCollected) || other.amountCollected == amountCollected)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.netEarning, netEarning) || other.netEarning == netEarning)&&(identical(other.commissionPercent, commissionPercent) || other.commissionPercent == commissionPercent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.method, method) || other.method == method)&&(identical(other.cashInHand, cashInHand) || other.cashInHand == cashInHand)&&(identical(other.cashToCollect, cashToCollect) || other.cashToCollect == cashToCollect)&&(identical(other.promoPaidByPlatform, promoPaidByPlatform) || other.promoPaidByPlatform == promoPaidByPlatform)&&(identical(other.promoPaidLabel, promoPaidLabel) || other.promoPaidLabel == promoPaidLabel)&&(identical(other.promoCreditedToWallet, promoCreditedToWallet) || other.promoCreditedToWallet == promoCreditedToWallet)&&(identical(other.taxCollected, taxCollected) || other.taxCollected == taxCollected)&&(identical(other.regulatoryFeeCollected, regulatoryFeeCollected) || other.regulatoryFeeCollected == regulatoryFeeCollected)&&const DeepCollectionEquality().equals(other.deductions, deductions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,amountCollected,platformFee,netEarning,commissionPercent,createdAt,method,cashInHand,cashToCollect,promoPaidByPlatform,promoPaidLabel,promoCreditedToWallet,taxCollected,regulatoryFeeCollected,const DeepCollectionEquality().hash(deductions));

@override
String toString() {
  return 'EarningModel(id: $id, tripId: $tripId, amountCollected: $amountCollected, platformFee: $platformFee, netEarning: $netEarning, commissionPercent: $commissionPercent, createdAt: $createdAt, method: $method, cashInHand: $cashInHand, cashToCollect: $cashToCollect, promoPaidByPlatform: $promoPaidByPlatform, promoPaidLabel: $promoPaidLabel, promoCreditedToWallet: $promoCreditedToWallet, taxCollected: $taxCollected, regulatoryFeeCollected: $regulatoryFeeCollected, deductions: $deductions)';
}


}

/// @nodoc
abstract mixin class $EarningModelCopyWith<$Res>  {
  factory $EarningModelCopyWith(EarningModel value, $Res Function(EarningModel) _then) = _$EarningModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id,@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId) int? tripId,@JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross) String? amountCollected,@JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission) String? platformFee,@JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet) String? netEarning,@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) num? commissionPercent,@JsonKey(name: 'created_at') String? createdAt, String? method,@JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson) bool? cashInHand,@JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson) String? cashToCollect,@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? promoPaidByPlatform,@JsonKey(name: 'promo_paid_label') String? promoPaidLabel,@JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson) bool? promoCreditedToWallet,@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) String? taxCollected,@JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson) String? regulatoryFeeCollected,@JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson) List<EarningDeduction> deductions
});




}
/// @nodoc
class _$EarningModelCopyWithImpl<$Res>
    implements $EarningModelCopyWith<$Res> {
  _$EarningModelCopyWithImpl(this._self, this._then);

  final EarningModel _self;
  final $Res Function(EarningModel) _then;

/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = freezed,Object? amountCollected = freezed,Object? platformFee = freezed,Object? netEarning = freezed,Object? commissionPercent = freezed,Object? createdAt = freezed,Object? method = freezed,Object? cashInHand = freezed,Object? cashToCollect = freezed,Object? promoPaidByPlatform = freezed,Object? promoPaidLabel = freezed,Object? promoCreditedToWallet = freezed,Object? taxCollected = freezed,Object? regulatoryFeeCollected = freezed,Object? deductions = null,}) {
  return _then(EarningModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as int?,amountCollected: freezed == amountCollected ? _self.amountCollected : amountCollected // ignore: cast_nullable_to_non_nullable
as String?,platformFee: freezed == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as String?,netEarning: freezed == netEarning ? _self.netEarning : netEarning // ignore: cast_nullable_to_non_nullable
as String?,commissionPercent: freezed == commissionPercent ? _self.commissionPercent : commissionPercent // ignore: cast_nullable_to_non_nullable
as num?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,cashInHand: freezed == cashInHand ? _self.cashInHand : cashInHand // ignore: cast_nullable_to_non_nullable
as bool?,cashToCollect: freezed == cashToCollect ? _self.cashToCollect : cashToCollect // ignore: cast_nullable_to_non_nullable
as String?,promoPaidByPlatform: freezed == promoPaidByPlatform ? _self.promoPaidByPlatform : promoPaidByPlatform // ignore: cast_nullable_to_non_nullable
as String?,promoPaidLabel: freezed == promoPaidLabel ? _self.promoPaidLabel : promoPaidLabel // ignore: cast_nullable_to_non_nullable
as String?,promoCreditedToWallet: freezed == promoCreditedToWallet ? _self.promoCreditedToWallet : promoCreditedToWallet // ignore: cast_nullable_to_non_nullable
as bool?,taxCollected: freezed == taxCollected ? _self.taxCollected : taxCollected // ignore: cast_nullable_to_non_nullable
as String?,regulatoryFeeCollected: freezed == regulatoryFeeCollected ? _self.regulatoryFeeCollected : regulatoryFeeCollected // ignore: cast_nullable_to_non_nullable
as String?,deductions: null == deductions ? _self.deductions : deductions // ignore: cast_nullable_to_non_nullable
as List<EarningDeduction>,
  ));
}

}


/// Adds pattern-matching-related methods to [EarningModel].
extension EarningModelPatterns on EarningModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarningModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarningModel value)  $default,){
final _that = this;
switch (_that) {
case _EarningModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarningModel value)?  $default,){
final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId)  int? tripId, @JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross)  String? amountCollected, @JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission)  String? platformFee, @JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet)  String? netEarning, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)  num? commissionPercent, @JsonKey(name: 'created_at')  String? createdAt,  String? method, @JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson)  bool? cashInHand, @JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson)  String? cashToCollect, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? promoPaidByPlatform, @JsonKey(name: 'promo_paid_label')  String? promoPaidLabel, @JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson)  bool? promoCreditedToWallet, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)  String? taxCollected, @JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson)  String? regulatoryFeeCollected, @JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson)  List<EarningDeduction> deductions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
return $default(_that.id,_that.tripId,_that.amountCollected,_that.platformFee,_that.netEarning,_that.commissionPercent,_that.createdAt,_that.method,_that.cashInHand,_that.cashToCollect,_that.promoPaidByPlatform,_that.promoPaidLabel,_that.promoCreditedToWallet,_that.taxCollected,_that.regulatoryFeeCollected,_that.deductions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId)  int? tripId, @JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross)  String? amountCollected, @JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission)  String? platformFee, @JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet)  String? netEarning, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)  num? commissionPercent, @JsonKey(name: 'created_at')  String? createdAt,  String? method, @JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson)  bool? cashInHand, @JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson)  String? cashToCollect, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? promoPaidByPlatform, @JsonKey(name: 'promo_paid_label')  String? promoPaidLabel, @JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson)  bool? promoCreditedToWallet, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)  String? taxCollected, @JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson)  String? regulatoryFeeCollected, @JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson)  List<EarningDeduction> deductions)  $default,) {final _that = this;
switch (_that) {
case _EarningModel():
return $default(_that.id,_that.tripId,_that.amountCollected,_that.platformFee,_that.netEarning,_that.commissionPercent,_that.createdAt,_that.method,_that.cashInHand,_that.cashToCollect,_that.promoPaidByPlatform,_that.promoPaidLabel,_that.promoCreditedToWallet,_that.taxCollected,_that.regulatoryFeeCollected,_that.deductions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId)  int? tripId, @JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross)  String? amountCollected, @JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission)  String? platformFee, @JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet)  String? netEarning, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)  num? commissionPercent, @JsonKey(name: 'created_at')  String? createdAt,  String? method, @JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson)  bool? cashInHand, @JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson)  String? cashToCollect, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)  String? promoPaidByPlatform, @JsonKey(name: 'promo_paid_label')  String? promoPaidLabel, @JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson)  bool? promoCreditedToWallet, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)  String? taxCollected, @JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson)  String? regulatoryFeeCollected, @JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson)  List<EarningDeduction> deductions)?  $default,) {final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
return $default(_that.id,_that.tripId,_that.amountCollected,_that.platformFee,_that.netEarning,_that.commissionPercent,_that.createdAt,_that.method,_that.cashInHand,_that.cashToCollect,_that.promoPaidByPlatform,_that.promoPaidLabel,_that.promoCreditedToWallet,_that.taxCollected,_that.regulatoryFeeCollected,_that.deductions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarningModel implements EarningModel {
  const _EarningModel({@JsonKey(fromJson: intFromJson) this.id = 0, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId) this.tripId, @JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross) this.amountCollected, @JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission) this.platformFee, @JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet) this.netEarning, @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) this.commissionPercent, @JsonKey(name: 'created_at') this.createdAt, this.method, @JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson) this.cashInHand, @JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson) this.cashToCollect, @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) this.promoPaidByPlatform, @JsonKey(name: 'promo_paid_label') this.promoPaidLabel, @JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson) this.promoCreditedToWallet, @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) this.taxCollected, @JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson) this.regulatoryFeeCollected, @JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson)  List<EarningDeduction> deductions = const <EarningDeduction>[]}): _deductions = deductions;
  factory _EarningModel.fromJson(Map<String, dynamic> json) => _$EarningModelFromJson(json);

@override@JsonKey(fromJson: intFromJson) final  int id;
@override@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId) final  int? tripId;
@override@JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross) final  String? amountCollected;
@override@JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission) final  String? platformFee;
@override@JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet) final  String? netEarning;
@override@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) final  num? commissionPercent;
@override@JsonKey(name: 'created_at') final  String? createdAt;
/// `cash`/`online`, as the API labels the trip.
@override final  String? method;
@override@JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson) final  bool? cashInHand;
/// What a cash driver collects from the rider (the fare less a promo, plus
/// a US trip's tax and fee). Null on an online trip.
@override@JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson) final  String? cashToCollect;
@override@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) final  String? promoPaidByPlatform;
@override@JsonKey(name: 'promo_paid_label') final  String? promoPaidLabel;
@override@JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson) final  bool? promoCreditedToWallet;
/// US only: collected for remittance, never earnings.
@override@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) final  String? taxCollected;
@override@JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson) final  String? regulatoryFeeCollected;
 final  List<EarningDeduction> _deductions;
@override@JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson) List<EarningDeduction> get deductions {
  if (_deductions is EqualUnmodifiableListView) return _deductions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deductions);
}


/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningModelCopyWith<_EarningModel> get copyWith => __$EarningModelCopyWithImpl<_EarningModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarningModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.amountCollected, amountCollected) || other.amountCollected == amountCollected)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.netEarning, netEarning) || other.netEarning == netEarning)&&(identical(other.commissionPercent, commissionPercent) || other.commissionPercent == commissionPercent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.method, method) || other.method == method)&&(identical(other.cashInHand, cashInHand) || other.cashInHand == cashInHand)&&(identical(other.cashToCollect, cashToCollect) || other.cashToCollect == cashToCollect)&&(identical(other.promoPaidByPlatform, promoPaidByPlatform) || other.promoPaidByPlatform == promoPaidByPlatform)&&(identical(other.promoPaidLabel, promoPaidLabel) || other.promoPaidLabel == promoPaidLabel)&&(identical(other.promoCreditedToWallet, promoCreditedToWallet) || other.promoCreditedToWallet == promoCreditedToWallet)&&(identical(other.taxCollected, taxCollected) || other.taxCollected == taxCollected)&&(identical(other.regulatoryFeeCollected, regulatoryFeeCollected) || other.regulatoryFeeCollected == regulatoryFeeCollected)&&const DeepCollectionEquality().equals(other._deductions, _deductions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,amountCollected,platformFee,netEarning,commissionPercent,createdAt,method,cashInHand,cashToCollect,promoPaidByPlatform,promoPaidLabel,promoCreditedToWallet,taxCollected,regulatoryFeeCollected,const DeepCollectionEquality().hash(_deductions));

@override
String toString() {
  return 'EarningModel(id: $id, tripId: $tripId, amountCollected: $amountCollected, platformFee: $platformFee, netEarning: $netEarning, commissionPercent: $commissionPercent, createdAt: $createdAt, method: $method, cashInHand: $cashInHand, cashToCollect: $cashToCollect, promoPaidByPlatform: $promoPaidByPlatform, promoPaidLabel: $promoPaidLabel, promoCreditedToWallet: $promoCreditedToWallet, taxCollected: $taxCollected, regulatoryFeeCollected: $regulatoryFeeCollected, deductions: $deductions)';
}


}

/// @nodoc
abstract mixin class _$EarningModelCopyWith<$Res> implements $EarningModelCopyWith<$Res> {
  factory _$EarningModelCopyWith(_EarningModel value, $Res Function(_EarningModel) _then) = __$EarningModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id,@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson, readValue: _readTripId) int? tripId,@JsonKey(name: 'amount_collected', fromJson: nullableMoneyFromJson, readValue: _readGross) String? amountCollected,@JsonKey(name: 'platform_fee', fromJson: nullableMoneyFromJson, readValue: _readCommission) String? platformFee,@JsonKey(name: 'net_earning', fromJson: nullableMoneyFromJson, readValue: _readNet) String? netEarning,@JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson) num? commissionPercent,@JsonKey(name: 'created_at') String? createdAt, String? method,@JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson) bool? cashInHand,@JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson) String? cashToCollect,@JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson) String? promoPaidByPlatform,@JsonKey(name: 'promo_paid_label') String? promoPaidLabel,@JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson) bool? promoCreditedToWallet,@JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson) String? taxCollected,@JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson) String? regulatoryFeeCollected,@JsonKey(name: 'deductions', fromJson: deductionsFromJson, toJson: deductionsToJson) List<EarningDeduction> deductions
});




}
/// @nodoc
class __$EarningModelCopyWithImpl<$Res>
    implements _$EarningModelCopyWith<$Res> {
  __$EarningModelCopyWithImpl(this._self, this._then);

  final _EarningModel _self;
  final $Res Function(_EarningModel) _then;

/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = freezed,Object? amountCollected = freezed,Object? platformFee = freezed,Object? netEarning = freezed,Object? commissionPercent = freezed,Object? createdAt = freezed,Object? method = freezed,Object? cashInHand = freezed,Object? cashToCollect = freezed,Object? promoPaidByPlatform = freezed,Object? promoPaidLabel = freezed,Object? promoCreditedToWallet = freezed,Object? taxCollected = freezed,Object? regulatoryFeeCollected = freezed,Object? deductions = null,}) {
  return _then(_EarningModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as int?,amountCollected: freezed == amountCollected ? _self.amountCollected : amountCollected // ignore: cast_nullable_to_non_nullable
as String?,platformFee: freezed == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as String?,netEarning: freezed == netEarning ? _self.netEarning : netEarning // ignore: cast_nullable_to_non_nullable
as String?,commissionPercent: freezed == commissionPercent ? _self.commissionPercent : commissionPercent // ignore: cast_nullable_to_non_nullable
as num?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,cashInHand: freezed == cashInHand ? _self.cashInHand : cashInHand // ignore: cast_nullable_to_non_nullable
as bool?,cashToCollect: freezed == cashToCollect ? _self.cashToCollect : cashToCollect // ignore: cast_nullable_to_non_nullable
as String?,promoPaidByPlatform: freezed == promoPaidByPlatform ? _self.promoPaidByPlatform : promoPaidByPlatform // ignore: cast_nullable_to_non_nullable
as String?,promoPaidLabel: freezed == promoPaidLabel ? _self.promoPaidLabel : promoPaidLabel // ignore: cast_nullable_to_non_nullable
as String?,promoCreditedToWallet: freezed == promoCreditedToWallet ? _self.promoCreditedToWallet : promoCreditedToWallet // ignore: cast_nullable_to_non_nullable
as bool?,taxCollected: freezed == taxCollected ? _self.taxCollected : taxCollected // ignore: cast_nullable_to_non_nullable
as String?,regulatoryFeeCollected: freezed == regulatoryFeeCollected ? _self.regulatoryFeeCollected : regulatoryFeeCollected // ignore: cast_nullable_to_non_nullable
as String?,deductions: null == deductions ? _self._deductions : deductions // ignore: cast_nullable_to_non_nullable
as List<EarningDeduction>,
  ));
}


}

// dart format on
