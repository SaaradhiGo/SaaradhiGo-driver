// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_block_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalBlockStatusModel {

@JsonKey(fromJson: boolFromJson) bool get blocked;@JsonKey(name: 'last_withdrawal_at') String? get lastWithdrawalAt;@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) int? get blockRemainingSeconds;
/// Create a copy of WithdrawalBlockStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalBlockStatusModelCopyWith<WithdrawalBlockStatusModel> get copyWith => _$WithdrawalBlockStatusModelCopyWithImpl<WithdrawalBlockStatusModel>(this as WithdrawalBlockStatusModel, _$identity);

  /// Serializes this WithdrawalBlockStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalBlockStatusModel&&(identical(other.blocked, blocked) || other.blocked == blocked)&&(identical(other.lastWithdrawalAt, lastWithdrawalAt) || other.lastWithdrawalAt == lastWithdrawalAt)&&(identical(other.blockRemainingSeconds, blockRemainingSeconds) || other.blockRemainingSeconds == blockRemainingSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blocked,lastWithdrawalAt,blockRemainingSeconds);

@override
String toString() {
  return 'WithdrawalBlockStatusModel(blocked: $blocked, lastWithdrawalAt: $lastWithdrawalAt, blockRemainingSeconds: $blockRemainingSeconds)';
}


}

/// @nodoc
abstract mixin class $WithdrawalBlockStatusModelCopyWith<$Res>  {
  factory $WithdrawalBlockStatusModelCopyWith(WithdrawalBlockStatusModel value, $Res Function(WithdrawalBlockStatusModel) _then) = _$WithdrawalBlockStatusModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: boolFromJson) bool blocked,@JsonKey(name: 'last_withdrawal_at') String? lastWithdrawalAt,@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) int? blockRemainingSeconds
});




}
/// @nodoc
class _$WithdrawalBlockStatusModelCopyWithImpl<$Res>
    implements $WithdrawalBlockStatusModelCopyWith<$Res> {
  _$WithdrawalBlockStatusModelCopyWithImpl(this._self, this._then);

  final WithdrawalBlockStatusModel _self;
  final $Res Function(WithdrawalBlockStatusModel) _then;

/// Create a copy of WithdrawalBlockStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? blocked = null,Object? lastWithdrawalAt = freezed,Object? blockRemainingSeconds = freezed,}) {
  return _then(WithdrawalBlockStatusModel(
blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,lastWithdrawalAt: freezed == lastWithdrawalAt ? _self.lastWithdrawalAt : lastWithdrawalAt // ignore: cast_nullable_to_non_nullable
as String?,blockRemainingSeconds: freezed == blockRemainingSeconds ? _self.blockRemainingSeconds : blockRemainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalBlockStatusModel].
extension WithdrawalBlockStatusModelPatterns on WithdrawalBlockStatusModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalBlockStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalBlockStatusModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalBlockStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalBlockStatusModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalBlockStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalBlockStatusModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: boolFromJson)  bool blocked, @JsonKey(name: 'last_withdrawal_at')  String? lastWithdrawalAt, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)  int? blockRemainingSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalBlockStatusModel() when $default != null:
return $default(_that.blocked,_that.lastWithdrawalAt,_that.blockRemainingSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: boolFromJson)  bool blocked, @JsonKey(name: 'last_withdrawal_at')  String? lastWithdrawalAt, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)  int? blockRemainingSeconds)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalBlockStatusModel():
return $default(_that.blocked,_that.lastWithdrawalAt,_that.blockRemainingSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: boolFromJson)  bool blocked, @JsonKey(name: 'last_withdrawal_at')  String? lastWithdrawalAt, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)  int? blockRemainingSeconds)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalBlockStatusModel() when $default != null:
return $default(_that.blocked,_that.lastWithdrawalAt,_that.blockRemainingSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalBlockStatusModel implements WithdrawalBlockStatusModel {
  const _WithdrawalBlockStatusModel({@JsonKey(fromJson: boolFromJson) this.blocked = false, @JsonKey(name: 'last_withdrawal_at') this.lastWithdrawalAt, @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) this.blockRemainingSeconds});
  factory _WithdrawalBlockStatusModel.fromJson(Map<String, dynamic> json) => _$WithdrawalBlockStatusModelFromJson(json);

@override@JsonKey(fromJson: boolFromJson) final  bool blocked;
@override@JsonKey(name: 'last_withdrawal_at') final  String? lastWithdrawalAt;
@override@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) final  int? blockRemainingSeconds;

/// Create a copy of WithdrawalBlockStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalBlockStatusModelCopyWith<_WithdrawalBlockStatusModel> get copyWith => __$WithdrawalBlockStatusModelCopyWithImpl<_WithdrawalBlockStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalBlockStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalBlockStatusModel&&(identical(other.blocked, blocked) || other.blocked == blocked)&&(identical(other.lastWithdrawalAt, lastWithdrawalAt) || other.lastWithdrawalAt == lastWithdrawalAt)&&(identical(other.blockRemainingSeconds, blockRemainingSeconds) || other.blockRemainingSeconds == blockRemainingSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blocked,lastWithdrawalAt,blockRemainingSeconds);

@override
String toString() {
  return 'WithdrawalBlockStatusModel(blocked: $blocked, lastWithdrawalAt: $lastWithdrawalAt, blockRemainingSeconds: $blockRemainingSeconds)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalBlockStatusModelCopyWith<$Res> implements $WithdrawalBlockStatusModelCopyWith<$Res> {
  factory _$WithdrawalBlockStatusModelCopyWith(_WithdrawalBlockStatusModel value, $Res Function(_WithdrawalBlockStatusModel) _then) = __$WithdrawalBlockStatusModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: boolFromJson) bool blocked,@JsonKey(name: 'last_withdrawal_at') String? lastWithdrawalAt,@JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson) int? blockRemainingSeconds
});




}
/// @nodoc
class __$WithdrawalBlockStatusModelCopyWithImpl<$Res>
    implements _$WithdrawalBlockStatusModelCopyWith<$Res> {
  __$WithdrawalBlockStatusModelCopyWithImpl(this._self, this._then);

  final _WithdrawalBlockStatusModel _self;
  final $Res Function(_WithdrawalBlockStatusModel) _then;

/// Create a copy of WithdrawalBlockStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? blocked = null,Object? lastWithdrawalAt = freezed,Object? blockRemainingSeconds = freezed,}) {
  return _then(_WithdrawalBlockStatusModel(
blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,lastWithdrawalAt: freezed == lastWithdrawalAt ? _self.lastWithdrawalAt : lastWithdrawalAt // ignore: cast_nullable_to_non_nullable
as String?,blockRemainingSeconds: freezed == blockRemainingSeconds ? _self.blockRemainingSeconds : blockRemainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
