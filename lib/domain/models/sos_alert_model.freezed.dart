// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sos_alert_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SosAlertModel {

@JsonKey(fromJson: intFromJson) int get id;@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson) int? get tripId; String? get status;@JsonKey(name: 'latitude', fromJson: doubleFromJson) double? get latitude;@JsonKey(name: 'longitude', fromJson: doubleFromJson) double? get longitude; String? get message;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of SosAlertModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosAlertModelCopyWith<SosAlertModel> get copyWith => _$SosAlertModelCopyWithImpl<SosAlertModel>(this as SosAlertModel, _$identity);

  /// Serializes this SosAlertModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosAlertModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.message, message) || other.message == message)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,status,latitude,longitude,message,createdAt);

@override
String toString() {
  return 'SosAlertModel(id: $id, tripId: $tripId, status: $status, latitude: $latitude, longitude: $longitude, message: $message, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SosAlertModelCopyWith<$Res>  {
  factory $SosAlertModelCopyWith(SosAlertModel value, $Res Function(SosAlertModel) _then) = _$SosAlertModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id,@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson) int? tripId, String? status,@JsonKey(name: 'latitude', fromJson: doubleFromJson) double? latitude,@JsonKey(name: 'longitude', fromJson: doubleFromJson) double? longitude, String? message,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$SosAlertModelCopyWithImpl<$Res>
    implements $SosAlertModelCopyWith<$Res> {
  _$SosAlertModelCopyWithImpl(this._self, this._then);

  final SosAlertModel _self;
  final $Res Function(SosAlertModel) _then;

/// Create a copy of SosAlertModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = freezed,Object? status = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? message = freezed,Object? createdAt = freezed,}) {
  return _then(SosAlertModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SosAlertModel].
extension SosAlertModelPatterns on SosAlertModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosAlertModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosAlertModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosAlertModel value)  $default,){
final _that = this;
switch (_that) {
case _SosAlertModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosAlertModel value)?  $default,){
final _that = this;
switch (_that) {
case _SosAlertModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson)  int? tripId,  String? status, @JsonKey(name: 'latitude', fromJson: doubleFromJson)  double? latitude, @JsonKey(name: 'longitude', fromJson: doubleFromJson)  double? longitude,  String? message, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosAlertModel() when $default != null:
return $default(_that.id,_that.tripId,_that.status,_that.latitude,_that.longitude,_that.message,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson)  int? tripId,  String? status, @JsonKey(name: 'latitude', fromJson: doubleFromJson)  double? latitude, @JsonKey(name: 'longitude', fromJson: doubleFromJson)  double? longitude,  String? message, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SosAlertModel():
return $default(_that.id,_that.tripId,_that.status,_that.latitude,_that.longitude,_that.message,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson)  int? tripId,  String? status, @JsonKey(name: 'latitude', fromJson: doubleFromJson)  double? latitude, @JsonKey(name: 'longitude', fromJson: doubleFromJson)  double? longitude,  String? message, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SosAlertModel() when $default != null:
return $default(_that.id,_that.tripId,_that.status,_that.latitude,_that.longitude,_that.message,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosAlertModel implements SosAlertModel {
  const _SosAlertModel({@JsonKey(fromJson: intFromJson) this.id = 0, @JsonKey(name: 'trip_id', fromJson: nullableIntFromJson) this.tripId, this.status, @JsonKey(name: 'latitude', fromJson: doubleFromJson) this.latitude, @JsonKey(name: 'longitude', fromJson: doubleFromJson) this.longitude, this.message, @JsonKey(name: 'created_at') this.createdAt});
  factory _SosAlertModel.fromJson(Map<String, dynamic> json) => _$SosAlertModelFromJson(json);

@override@JsonKey(fromJson: intFromJson) final  int id;
@override@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson) final  int? tripId;
@override final  String? status;
@override@JsonKey(name: 'latitude', fromJson: doubleFromJson) final  double? latitude;
@override@JsonKey(name: 'longitude', fromJson: doubleFromJson) final  double? longitude;
@override final  String? message;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of SosAlertModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosAlertModelCopyWith<_SosAlertModel> get copyWith => __$SosAlertModelCopyWithImpl<_SosAlertModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosAlertModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosAlertModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.message, message) || other.message == message)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,status,latitude,longitude,message,createdAt);

@override
String toString() {
  return 'SosAlertModel(id: $id, tripId: $tripId, status: $status, latitude: $latitude, longitude: $longitude, message: $message, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SosAlertModelCopyWith<$Res> implements $SosAlertModelCopyWith<$Res> {
  factory _$SosAlertModelCopyWith(_SosAlertModel value, $Res Function(_SosAlertModel) _then) = __$SosAlertModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id,@JsonKey(name: 'trip_id', fromJson: nullableIntFromJson) int? tripId, String? status,@JsonKey(name: 'latitude', fromJson: doubleFromJson) double? latitude,@JsonKey(name: 'longitude', fromJson: doubleFromJson) double? longitude, String? message,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$SosAlertModelCopyWithImpl<$Res>
    implements _$SosAlertModelCopyWith<$Res> {
  __$SosAlertModelCopyWithImpl(this._self, this._then);

  final _SosAlertModel _self;
  final $Res Function(_SosAlertModel) _then;

/// Create a copy of SosAlertModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = freezed,Object? status = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? message = freezed,Object? createdAt = freezed,}) {
  return _then(_SosAlertModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
