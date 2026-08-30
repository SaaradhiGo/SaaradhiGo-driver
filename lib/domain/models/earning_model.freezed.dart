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

 int get id;@JsonKey(name: 'trip_id') int? get tripId;@JsonKey(name: 'amount_collected') String get amountCollected;@JsonKey(name: 'platform_fee') String get platformFee;@JsonKey(name: 'net_earning') String get netEarning;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningModelCopyWith<EarningModel> get copyWith => _$EarningModelCopyWithImpl<EarningModel>(this as EarningModel, _$identity);

  /// Serializes this EarningModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.amountCollected, amountCollected) || other.amountCollected == amountCollected)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.netEarning, netEarning) || other.netEarning == netEarning)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,amountCollected,platformFee,netEarning,createdAt);

@override
String toString() {
  return 'EarningModel(id: $id, tripId: $tripId, amountCollected: $amountCollected, platformFee: $platformFee, netEarning: $netEarning, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EarningModelCopyWith<$Res>  {
  factory $EarningModelCopyWith(EarningModel value, $Res Function(EarningModel) _then) = _$EarningModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'trip_id') int? tripId,@JsonKey(name: 'amount_collected') String amountCollected,@JsonKey(name: 'platform_fee') String platformFee,@JsonKey(name: 'net_earning') String netEarning,@JsonKey(name: 'created_at') String? createdAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = freezed,Object? amountCollected = null,Object? platformFee = null,Object? netEarning = null,Object? createdAt = freezed,}) {
  return _then(EarningModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as int?,amountCollected: null == amountCollected ? _self.amountCollected : amountCollected // ignore: cast_nullable_to_non_nullable
as String,platformFee: null == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as String,netEarning: null == netEarning ? _self.netEarning : netEarning // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'trip_id')  int? tripId, @JsonKey(name: 'amount_collected')  String amountCollected, @JsonKey(name: 'platform_fee')  String platformFee, @JsonKey(name: 'net_earning')  String netEarning, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
return $default(_that.id,_that.tripId,_that.amountCollected,_that.platformFee,_that.netEarning,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'trip_id')  int? tripId, @JsonKey(name: 'amount_collected')  String amountCollected, @JsonKey(name: 'platform_fee')  String platformFee, @JsonKey(name: 'net_earning')  String netEarning, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _EarningModel():
return $default(_that.id,_that.tripId,_that.amountCollected,_that.platformFee,_that.netEarning,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'trip_id')  int? tripId, @JsonKey(name: 'amount_collected')  String amountCollected, @JsonKey(name: 'platform_fee')  String platformFee, @JsonKey(name: 'net_earning')  String netEarning, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
return $default(_that.id,_that.tripId,_that.amountCollected,_that.platformFee,_that.netEarning,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarningModel implements EarningModel {
  const _EarningModel({required this.id, @JsonKey(name: 'trip_id') this.tripId, @JsonKey(name: 'amount_collected') this.amountCollected = '0.00', @JsonKey(name: 'platform_fee') this.platformFee = '0.00', @JsonKey(name: 'net_earning') this.netEarning = '0.00', @JsonKey(name: 'created_at') this.createdAt});
  factory _EarningModel.fromJson(Map<String, dynamic> json) => _$EarningModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'trip_id') final  int? tripId;
@override@JsonKey(name: 'amount_collected') final  String amountCollected;
@override@JsonKey(name: 'platform_fee') final  String platformFee;
@override@JsonKey(name: 'net_earning') final  String netEarning;
@override@JsonKey(name: 'created_at') final  String? createdAt;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.amountCollected, amountCollected) || other.amountCollected == amountCollected)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.netEarning, netEarning) || other.netEarning == netEarning)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,amountCollected,platformFee,netEarning,createdAt);

@override
String toString() {
  return 'EarningModel(id: $id, tripId: $tripId, amountCollected: $amountCollected, platformFee: $platformFee, netEarning: $netEarning, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EarningModelCopyWith<$Res> implements $EarningModelCopyWith<$Res> {
  factory _$EarningModelCopyWith(_EarningModel value, $Res Function(_EarningModel) _then) = __$EarningModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'trip_id') int? tripId,@JsonKey(name: 'amount_collected') String amountCollected,@JsonKey(name: 'platform_fee') String platformFee,@JsonKey(name: 'net_earning') String netEarning,@JsonKey(name: 'created_at') String? createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = freezed,Object? amountCollected = null,Object? platformFee = null,Object? netEarning = null,Object? createdAt = freezed,}) {
  return _then(_EarningModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as int?,amountCollected: null == amountCollected ? _self.amountCollected : amountCollected // ignore: cast_nullable_to_non_nullable
as String,platformFee: null == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as String,netEarning: null == netEarning ? _self.netEarning : netEarning // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
