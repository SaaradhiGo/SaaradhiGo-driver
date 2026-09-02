// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_balance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalBalanceModel {

@JsonKey(name: 'available_balance', fromJson: doubleFromJson) double get availableBalance;@JsonKey(fromJson: boolFromJson) bool get blocked;@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) int? get blockRemainingSeconds;@JsonKey(name: 'fee_percent', fromJson: doubleFromJson) double get feePercent;@JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson) double get minimumWithdrawal;
/// Create a copy of WithdrawalBalanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalBalanceModelCopyWith<WithdrawalBalanceModel> get copyWith => _$WithdrawalBalanceModelCopyWithImpl<WithdrawalBalanceModel>(this as WithdrawalBalanceModel, _$identity);

  /// Serializes this WithdrawalBalanceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalBalanceModel&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.blocked, blocked) || other.blocked == blocked)&&(identical(other.blockRemainingSeconds, blockRemainingSeconds) || other.blockRemainingSeconds == blockRemainingSeconds)&&(identical(other.feePercent, feePercent) || other.feePercent == feePercent)&&(identical(other.minimumWithdrawal, minimumWithdrawal) || other.minimumWithdrawal == minimumWithdrawal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,availableBalance,blocked,blockRemainingSeconds,feePercent,minimumWithdrawal);

@override
String toString() {
  return 'WithdrawalBalanceModel(availableBalance: $availableBalance, blocked: $blocked, blockRemainingSeconds: $blockRemainingSeconds, feePercent: $feePercent, minimumWithdrawal: $minimumWithdrawal)';
}


}

/// @nodoc
abstract mixin class $WithdrawalBalanceModelCopyWith<$Res>  {
  factory $WithdrawalBalanceModelCopyWith(WithdrawalBalanceModel value, $Res Function(WithdrawalBalanceModel) _then) = _$WithdrawalBalanceModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'available_balance', fromJson: doubleFromJson) double availableBalance,@JsonKey(fromJson: boolFromJson) bool blocked,@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) int? blockRemainingSeconds,@JsonKey(name: 'fee_percent', fromJson: doubleFromJson) double feePercent,@JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson) double minimumWithdrawal
});




}
/// @nodoc
class _$WithdrawalBalanceModelCopyWithImpl<$Res>
    implements $WithdrawalBalanceModelCopyWith<$Res> {
  _$WithdrawalBalanceModelCopyWithImpl(this._self, this._then);

  final WithdrawalBalanceModel _self;
  final $Res Function(WithdrawalBalanceModel) _then;

/// Create a copy of WithdrawalBalanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? availableBalance = null,Object? blocked = null,Object? blockRemainingSeconds = freezed,Object? feePercent = null,Object? minimumWithdrawal = null,}) {
  return _then(WithdrawalBalanceModel(
availableBalance: null == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as double,blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,blockRemainingSeconds: freezed == blockRemainingSeconds ? _self.blockRemainingSeconds : blockRemainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,feePercent: null == feePercent ? _self.feePercent : feePercent // ignore: cast_nullable_to_non_nullable
as double,minimumWithdrawal: null == minimumWithdrawal ? _self.minimumWithdrawal : minimumWithdrawal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalBalanceModel].
extension WithdrawalBalanceModelPatterns on WithdrawalBalanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalBalanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalBalanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalBalanceModel value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalBalanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalBalanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalBalanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'available_balance', fromJson: doubleFromJson)  double availableBalance, @JsonKey(fromJson: boolFromJson)  bool blocked, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)  int? blockRemainingSeconds, @JsonKey(name: 'fee_percent', fromJson: doubleFromJson)  double feePercent, @JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson)  double minimumWithdrawal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalBalanceModel() when $default != null:
return $default(_that.availableBalance,_that.blocked,_that.blockRemainingSeconds,_that.feePercent,_that.minimumWithdrawal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'available_balance', fromJson: doubleFromJson)  double availableBalance, @JsonKey(fromJson: boolFromJson)  bool blocked, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)  int? blockRemainingSeconds, @JsonKey(name: 'fee_percent', fromJson: doubleFromJson)  double feePercent, @JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson)  double minimumWithdrawal)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalBalanceModel():
return $default(_that.availableBalance,_that.blocked,_that.blockRemainingSeconds,_that.feePercent,_that.minimumWithdrawal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'available_balance', fromJson: doubleFromJson)  double availableBalance, @JsonKey(fromJson: boolFromJson)  bool blocked, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)  int? blockRemainingSeconds, @JsonKey(name: 'fee_percent', fromJson: doubleFromJson)  double feePercent, @JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson)  double minimumWithdrawal)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalBalanceModel() when $default != null:
return $default(_that.availableBalance,_that.blocked,_that.blockRemainingSeconds,_that.feePercent,_that.minimumWithdrawal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalBalanceModel implements WithdrawalBalanceModel {
  const _WithdrawalBalanceModel({@JsonKey(name: 'available_balance', fromJson: doubleFromJson) this.availableBalance = 0.0, @JsonKey(fromJson: boolFromJson) this.blocked = false, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) this.blockRemainingSeconds, @JsonKey(name: 'fee_percent', fromJson: doubleFromJson) this.feePercent = 0.0, @JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson) this.minimumWithdrawal = 500.0});
  factory _WithdrawalBalanceModel.fromJson(Map<String, dynamic> json) => _$WithdrawalBalanceModelFromJson(json);

@override@JsonKey(name: 'available_balance', fromJson: doubleFromJson) final  double availableBalance;
@override@JsonKey(fromJson: boolFromJson) final  bool blocked;
@override@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) final  int? blockRemainingSeconds;
@override@JsonKey(name: 'fee_percent', fromJson: doubleFromJson) final  double feePercent;
@override@JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson) final  double minimumWithdrawal;

/// Create a copy of WithdrawalBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalBalanceModelCopyWith<_WithdrawalBalanceModel> get copyWith => __$WithdrawalBalanceModelCopyWithImpl<_WithdrawalBalanceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalBalanceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalBalanceModel&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.blocked, blocked) || other.blocked == blocked)&&(identical(other.blockRemainingSeconds, blockRemainingSeconds) || other.blockRemainingSeconds == blockRemainingSeconds)&&(identical(other.feePercent, feePercent) || other.feePercent == feePercent)&&(identical(other.minimumWithdrawal, minimumWithdrawal) || other.minimumWithdrawal == minimumWithdrawal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,availableBalance,blocked,blockRemainingSeconds,feePercent,minimumWithdrawal);

@override
String toString() {
  return 'WithdrawalBalanceModel(availableBalance: $availableBalance, blocked: $blocked, blockRemainingSeconds: $blockRemainingSeconds, feePercent: $feePercent, minimumWithdrawal: $minimumWithdrawal)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalBalanceModelCopyWith<$Res> implements $WithdrawalBalanceModelCopyWith<$Res> {
  factory _$WithdrawalBalanceModelCopyWith(_WithdrawalBalanceModel value, $Res Function(_WithdrawalBalanceModel) _then) = __$WithdrawalBalanceModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'available_balance', fromJson: doubleFromJson) double availableBalance,@JsonKey(fromJson: boolFromJson) bool blocked,@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) int? blockRemainingSeconds,@JsonKey(name: 'fee_percent', fromJson: doubleFromJson) double feePercent,@JsonKey(name: 'minimum_withdrawal', fromJson: doubleFromJson) double minimumWithdrawal
});




}
/// @nodoc
class __$WithdrawalBalanceModelCopyWithImpl<$Res>
    implements _$WithdrawalBalanceModelCopyWith<$Res> {
  __$WithdrawalBalanceModelCopyWithImpl(this._self, this._then);

  final _WithdrawalBalanceModel _self;
  final $Res Function(_WithdrawalBalanceModel) _then;

/// Create a copy of WithdrawalBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? availableBalance = null,Object? blocked = null,Object? blockRemainingSeconds = freezed,Object? feePercent = null,Object? minimumWithdrawal = null,}) {
  return _then(_WithdrawalBalanceModel(
availableBalance: null == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as double,blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,blockRemainingSeconds: freezed == blockRemainingSeconds ? _self.blockRemainingSeconds : blockRemainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,feePercent: null == feePercent ? _self.feePercent : feePercent // ignore: cast_nullable_to_non_nullable
as double,minimumWithdrawal: null == minimumWithdrawal ? _self.minimumWithdrawal : minimumWithdrawal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
