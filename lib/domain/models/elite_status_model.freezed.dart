// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'elite_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EliteStatusModel {

 String get tier;@JsonKey(name: 'total_trips', fromJson: intFromJson) int get totalTrips; String get rating;@JsonKey(name: 'acceptance_rate') String get acceptanceRate;@JsonKey(name: 'cancellation_rate') String get cancellationRate;@JsonKey(name: 'next_tier') String? get nextTier;@JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson) int? get tripsToNextTier;
/// Create a copy of EliteStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EliteStatusModelCopyWith<EliteStatusModel> get copyWith => _$EliteStatusModelCopyWithImpl<EliteStatusModel>(this as EliteStatusModel, _$identity);

  /// Serializes this EliteStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EliteStatusModel&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.acceptanceRate, acceptanceRate) || other.acceptanceRate == acceptanceRate)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.nextTier, nextTier) || other.nextTier == nextTier)&&(identical(other.tripsToNextTier, tripsToNextTier) || other.tripsToNextTier == tripsToNextTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier,totalTrips,rating,acceptanceRate,cancellationRate,nextTier,tripsToNextTier);

@override
String toString() {
  return 'EliteStatusModel(tier: $tier, totalTrips: $totalTrips, rating: $rating, acceptanceRate: $acceptanceRate, cancellationRate: $cancellationRate, nextTier: $nextTier, tripsToNextTier: $tripsToNextTier)';
}


}

/// @nodoc
abstract mixin class $EliteStatusModelCopyWith<$Res>  {
  factory $EliteStatusModelCopyWith(EliteStatusModel value, $Res Function(EliteStatusModel) _then) = _$EliteStatusModelCopyWithImpl;
@useResult
$Res call({
 String tier,@JsonKey(name: 'total_trips', fromJson: intFromJson) int totalTrips, String rating,@JsonKey(name: 'acceptance_rate') String acceptanceRate,@JsonKey(name: 'cancellation_rate') String cancellationRate,@JsonKey(name: 'next_tier') String? nextTier,@JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson) int? tripsToNextTier
});




}
/// @nodoc
class _$EliteStatusModelCopyWithImpl<$Res>
    implements $EliteStatusModelCopyWith<$Res> {
  _$EliteStatusModelCopyWithImpl(this._self, this._then);

  final EliteStatusModel _self;
  final $Res Function(EliteStatusModel) _then;

/// Create a copy of EliteStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,Object? totalTrips = null,Object? rating = null,Object? acceptanceRate = null,Object? cancellationRate = null,Object? nextTier = freezed,Object? tripsToNextTier = freezed,}) {
  return _then(EliteStatusModel(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String,acceptanceRate: null == acceptanceRate ? _self.acceptanceRate : acceptanceRate // ignore: cast_nullable_to_non_nullable
as String,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as String,nextTier: freezed == nextTier ? _self.nextTier : nextTier // ignore: cast_nullable_to_non_nullable
as String?,tripsToNextTier: freezed == tripsToNextTier ? _self.tripsToNextTier : tripsToNextTier // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [EliteStatusModel].
extension EliteStatusModelPatterns on EliteStatusModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EliteStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EliteStatusModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EliteStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _EliteStatusModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EliteStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _EliteStatusModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tier, @JsonKey(name: 'total_trips', fromJson: intFromJson)  int totalTrips,  String rating, @JsonKey(name: 'acceptance_rate')  String acceptanceRate, @JsonKey(name: 'cancellation_rate')  String cancellationRate, @JsonKey(name: 'next_tier')  String? nextTier, @JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson)  int? tripsToNextTier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EliteStatusModel() when $default != null:
return $default(_that.tier,_that.totalTrips,_that.rating,_that.acceptanceRate,_that.cancellationRate,_that.nextTier,_that.tripsToNextTier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tier, @JsonKey(name: 'total_trips', fromJson: intFromJson)  int totalTrips,  String rating, @JsonKey(name: 'acceptance_rate')  String acceptanceRate, @JsonKey(name: 'cancellation_rate')  String cancellationRate, @JsonKey(name: 'next_tier')  String? nextTier, @JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson)  int? tripsToNextTier)  $default,) {final _that = this;
switch (_that) {
case _EliteStatusModel():
return $default(_that.tier,_that.totalTrips,_that.rating,_that.acceptanceRate,_that.cancellationRate,_that.nextTier,_that.tripsToNextTier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tier, @JsonKey(name: 'total_trips', fromJson: intFromJson)  int totalTrips,  String rating, @JsonKey(name: 'acceptance_rate')  String acceptanceRate, @JsonKey(name: 'cancellation_rate')  String cancellationRate, @JsonKey(name: 'next_tier')  String? nextTier, @JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson)  int? tripsToNextTier)?  $default,) {final _that = this;
switch (_that) {
case _EliteStatusModel() when $default != null:
return $default(_that.tier,_that.totalTrips,_that.rating,_that.acceptanceRate,_that.cancellationRate,_that.nextTier,_that.tripsToNextTier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EliteStatusModel extends EliteStatusModel {
  const _EliteStatusModel({this.tier = 'Silver', @JsonKey(name: 'total_trips', fromJson: intFromJson) this.totalTrips = 0, this.rating = '5.0', @JsonKey(name: 'acceptance_rate') this.acceptanceRate = '100%', @JsonKey(name: 'cancellation_rate') this.cancellationRate = '0%', @JsonKey(name: 'next_tier') this.nextTier, @JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson) this.tripsToNextTier}): super._();
  factory _EliteStatusModel.fromJson(Map<String, dynamic> json) => _$EliteStatusModelFromJson(json);

@override@JsonKey() final  String tier;
@override@JsonKey(name: 'total_trips', fromJson: intFromJson) final  int totalTrips;
@override@JsonKey() final  String rating;
@override@JsonKey(name: 'acceptance_rate') final  String acceptanceRate;
@override@JsonKey(name: 'cancellation_rate') final  String cancellationRate;
@override@JsonKey(name: 'next_tier') final  String? nextTier;
@override@JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson) final  int? tripsToNextTier;

/// Create a copy of EliteStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EliteStatusModelCopyWith<_EliteStatusModel> get copyWith => __$EliteStatusModelCopyWithImpl<_EliteStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EliteStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EliteStatusModel&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.acceptanceRate, acceptanceRate) || other.acceptanceRate == acceptanceRate)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.nextTier, nextTier) || other.nextTier == nextTier)&&(identical(other.tripsToNextTier, tripsToNextTier) || other.tripsToNextTier == tripsToNextTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier,totalTrips,rating,acceptanceRate,cancellationRate,nextTier,tripsToNextTier);

@override
String toString() {
  return 'EliteStatusModel(tier: $tier, totalTrips: $totalTrips, rating: $rating, acceptanceRate: $acceptanceRate, cancellationRate: $cancellationRate, nextTier: $nextTier, tripsToNextTier: $tripsToNextTier)';
}


}

/// @nodoc
abstract mixin class _$EliteStatusModelCopyWith<$Res> implements $EliteStatusModelCopyWith<$Res> {
  factory _$EliteStatusModelCopyWith(_EliteStatusModel value, $Res Function(_EliteStatusModel) _then) = __$EliteStatusModelCopyWithImpl;
@override @useResult
$Res call({
 String tier,@JsonKey(name: 'total_trips', fromJson: intFromJson) int totalTrips, String rating,@JsonKey(name: 'acceptance_rate') String acceptanceRate,@JsonKey(name: 'cancellation_rate') String cancellationRate,@JsonKey(name: 'next_tier') String? nextTier,@JsonKey(name: 'trips_to_next_tier', fromJson: nullableIntFromJson) int? tripsToNextTier
});




}
/// @nodoc
class __$EliteStatusModelCopyWithImpl<$Res>
    implements _$EliteStatusModelCopyWith<$Res> {
  __$EliteStatusModelCopyWithImpl(this._self, this._then);

  final _EliteStatusModel _self;
  final $Res Function(_EliteStatusModel) _then;

/// Create a copy of EliteStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier = null,Object? totalTrips = null,Object? rating = null,Object? acceptanceRate = null,Object? cancellationRate = null,Object? nextTier = freezed,Object? tripsToNextTier = freezed,}) {
  return _then(_EliteStatusModel(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String,acceptanceRate: null == acceptanceRate ? _self.acceptanceRate : acceptanceRate // ignore: cast_nullable_to_non_nullable
as String,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as String,nextTier: freezed == nextTier ? _self.nextTier : nextTier // ignore: cast_nullable_to_non_nullable
as String?,tripsToNextTier: freezed == tripsToNextTier ? _self.tripsToNextTier : tripsToNextTier // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
