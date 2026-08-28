// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VehicleRequestDto {

@JsonKey(name: 'registration_number') String get registrationNumber;@JsonKey(name: 'vehicle_type') String get vehicleType; String get make; String get model; int get year; String get color;@JsonKey(includeToJson: false, includeFromJson: false) PickedDocument? get rcDocument;@JsonKey(name: 'rc_doc') String? get rcDocKey;@JsonKey(includeToJson: false, includeFromJson: false) PickedDocument? get vehiclePicDocument;@JsonKey(includeToJson: false, includeFromJson: false) bool? get setAsActive;
/// Create a copy of VehicleRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleRequestDtoCopyWith<VehicleRequestDto> get copyWith => _$VehicleRequestDtoCopyWithImpl<VehicleRequestDto>(this as VehicleRequestDto, _$identity);

  /// Serializes this VehicleRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleRequestDto&&(identical(other.registrationNumber, registrationNumber) || other.registrationNumber == registrationNumber)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.color, color) || other.color == color)&&(identical(other.rcDocument, rcDocument) || other.rcDocument == rcDocument)&&(identical(other.rcDocKey, rcDocKey) || other.rcDocKey == rcDocKey)&&(identical(other.vehiclePicDocument, vehiclePicDocument) || other.vehiclePicDocument == vehiclePicDocument)&&(identical(other.setAsActive, setAsActive) || other.setAsActive == setAsActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registrationNumber,vehicleType,make,model,year,color,rcDocument,rcDocKey,vehiclePicDocument,setAsActive);

@override
String toString() {
  return 'VehicleRequestDto(registrationNumber: $registrationNumber, vehicleType: $vehicleType, make: $make, model: $model, year: $year, color: $color, rcDocument: $rcDocument, rcDocKey: $rcDocKey, vehiclePicDocument: $vehiclePicDocument, setAsActive: $setAsActive)';
}


}

/// @nodoc
abstract mixin class $VehicleRequestDtoCopyWith<$Res>  {
  factory $VehicleRequestDtoCopyWith(VehicleRequestDto value, $Res Function(VehicleRequestDto) _then) = _$VehicleRequestDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'registration_number') String registrationNumber,@JsonKey(name: 'vehicle_type') String vehicleType, String make, String model, int year, String color,@JsonKey(includeToJson: false, includeFromJson: false) PickedDocument? rcDocument,@JsonKey(name: 'rc_doc') String? rcDocKey,@JsonKey(includeToJson: false, includeFromJson: false) PickedDocument? vehiclePicDocument,@JsonKey(includeToJson: false, includeFromJson: false) bool? setAsActive
});




}
/// @nodoc
class _$VehicleRequestDtoCopyWithImpl<$Res>
    implements $VehicleRequestDtoCopyWith<$Res> {
  _$VehicleRequestDtoCopyWithImpl(this._self, this._then);

  final VehicleRequestDto _self;
  final $Res Function(VehicleRequestDto) _then;

/// Create a copy of VehicleRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? registrationNumber = null,Object? vehicleType = null,Object? make = null,Object? model = null,Object? year = null,Object? color = null,Object? rcDocument = freezed,Object? rcDocKey = freezed,Object? vehiclePicDocument = freezed,Object? setAsActive = freezed,}) {
  return _then(VehicleRequestDto(
registrationNumber: null == registrationNumber ? _self.registrationNumber : registrationNumber // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,rcDocument: freezed == rcDocument ? _self.rcDocument : rcDocument // ignore: cast_nullable_to_non_nullable
as PickedDocument?,rcDocKey: freezed == rcDocKey ? _self.rcDocKey : rcDocKey // ignore: cast_nullable_to_non_nullable
as String?,vehiclePicDocument: freezed == vehiclePicDocument ? _self.vehiclePicDocument : vehiclePicDocument // ignore: cast_nullable_to_non_nullable
as PickedDocument?,setAsActive: freezed == setAsActive ? _self.setAsActive : setAsActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleRequestDto].
extension VehicleRequestDtoPatterns on VehicleRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _VehicleRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'registration_number')  String registrationNumber, @JsonKey(name: 'vehicle_type')  String vehicleType,  String make,  String model,  int year,  String color, @JsonKey(includeToJson: false, includeFromJson: false)  PickedDocument? rcDocument, @JsonKey(name: 'rc_doc')  String? rcDocKey, @JsonKey(includeToJson: false, includeFromJson: false)  PickedDocument? vehiclePicDocument, @JsonKey(includeToJson: false, includeFromJson: false)  bool? setAsActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleRequestDto() when $default != null:
return $default(_that.registrationNumber,_that.vehicleType,_that.make,_that.model,_that.year,_that.color,_that.rcDocument,_that.rcDocKey,_that.vehiclePicDocument,_that.setAsActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'registration_number')  String registrationNumber, @JsonKey(name: 'vehicle_type')  String vehicleType,  String make,  String model,  int year,  String color, @JsonKey(includeToJson: false, includeFromJson: false)  PickedDocument? rcDocument, @JsonKey(name: 'rc_doc')  String? rcDocKey, @JsonKey(includeToJson: false, includeFromJson: false)  PickedDocument? vehiclePicDocument, @JsonKey(includeToJson: false, includeFromJson: false)  bool? setAsActive)  $default,) {final _that = this;
switch (_that) {
case _VehicleRequestDto():
return $default(_that.registrationNumber,_that.vehicleType,_that.make,_that.model,_that.year,_that.color,_that.rcDocument,_that.rcDocKey,_that.vehiclePicDocument,_that.setAsActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'registration_number')  String registrationNumber, @JsonKey(name: 'vehicle_type')  String vehicleType,  String make,  String model,  int year,  String color, @JsonKey(includeToJson: false, includeFromJson: false)  PickedDocument? rcDocument, @JsonKey(name: 'rc_doc')  String? rcDocKey, @JsonKey(includeToJson: false, includeFromJson: false)  PickedDocument? vehiclePicDocument, @JsonKey(includeToJson: false, includeFromJson: false)  bool? setAsActive)?  $default,) {final _that = this;
switch (_that) {
case _VehicleRequestDto() when $default != null:
return $default(_that.registrationNumber,_that.vehicleType,_that.make,_that.model,_that.year,_that.color,_that.rcDocument,_that.rcDocKey,_that.vehiclePicDocument,_that.setAsActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleRequestDto implements VehicleRequestDto {
  const _VehicleRequestDto({@JsonKey(name: 'registration_number') required this.registrationNumber, @JsonKey(name: 'vehicle_type') required this.vehicleType, required this.make, required this.model, required this.year, required this.color, @JsonKey(includeToJson: false, includeFromJson: false) this.rcDocument, @JsonKey(name: 'rc_doc') this.rcDocKey, @JsonKey(includeToJson: false, includeFromJson: false) this.vehiclePicDocument, @JsonKey(includeToJson: false, includeFromJson: false) this.setAsActive});
  factory _VehicleRequestDto.fromJson(Map<String, dynamic> json) => _$VehicleRequestDtoFromJson(json);

@override@JsonKey(name: 'registration_number') final  String registrationNumber;
@override@JsonKey(name: 'vehicle_type') final  String vehicleType;
@override final  String make;
@override final  String model;
@override final  int year;
@override final  String color;
@override@JsonKey(includeToJson: false, includeFromJson: false) final  PickedDocument? rcDocument;
@override@JsonKey(name: 'rc_doc') final  String? rcDocKey;
@override@JsonKey(includeToJson: false, includeFromJson: false) final  PickedDocument? vehiclePicDocument;
@override@JsonKey(includeToJson: false, includeFromJson: false) final  bool? setAsActive;

/// Create a copy of VehicleRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleRequestDtoCopyWith<_VehicleRequestDto> get copyWith => __$VehicleRequestDtoCopyWithImpl<_VehicleRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleRequestDto&&(identical(other.registrationNumber, registrationNumber) || other.registrationNumber == registrationNumber)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.color, color) || other.color == color)&&(identical(other.rcDocument, rcDocument) || other.rcDocument == rcDocument)&&(identical(other.rcDocKey, rcDocKey) || other.rcDocKey == rcDocKey)&&(identical(other.vehiclePicDocument, vehiclePicDocument) || other.vehiclePicDocument == vehiclePicDocument)&&(identical(other.setAsActive, setAsActive) || other.setAsActive == setAsActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registrationNumber,vehicleType,make,model,year,color,rcDocument,rcDocKey,vehiclePicDocument,setAsActive);

@override
String toString() {
  return 'VehicleRequestDto(registrationNumber: $registrationNumber, vehicleType: $vehicleType, make: $make, model: $model, year: $year, color: $color, rcDocument: $rcDocument, rcDocKey: $rcDocKey, vehiclePicDocument: $vehiclePicDocument, setAsActive: $setAsActive)';
}


}

/// @nodoc
abstract mixin class _$VehicleRequestDtoCopyWith<$Res> implements $VehicleRequestDtoCopyWith<$Res> {
  factory _$VehicleRequestDtoCopyWith(_VehicleRequestDto value, $Res Function(_VehicleRequestDto) _then) = __$VehicleRequestDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'registration_number') String registrationNumber,@JsonKey(name: 'vehicle_type') String vehicleType, String make, String model, int year, String color,@JsonKey(includeToJson: false, includeFromJson: false) PickedDocument? rcDocument,@JsonKey(name: 'rc_doc') String? rcDocKey,@JsonKey(includeToJson: false, includeFromJson: false) PickedDocument? vehiclePicDocument,@JsonKey(includeToJson: false, includeFromJson: false) bool? setAsActive
});




}
/// @nodoc
class __$VehicleRequestDtoCopyWithImpl<$Res>
    implements _$VehicleRequestDtoCopyWith<$Res> {
  __$VehicleRequestDtoCopyWithImpl(this._self, this._then);

  final _VehicleRequestDto _self;
  final $Res Function(_VehicleRequestDto) _then;

/// Create a copy of VehicleRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? registrationNumber = null,Object? vehicleType = null,Object? make = null,Object? model = null,Object? year = null,Object? color = null,Object? rcDocument = freezed,Object? rcDocKey = freezed,Object? vehiclePicDocument = freezed,Object? setAsActive = freezed,}) {
  return _then(_VehicleRequestDto(
registrationNumber: null == registrationNumber ? _self.registrationNumber : registrationNumber // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,rcDocument: freezed == rcDocument ? _self.rcDocument : rcDocument // ignore: cast_nullable_to_non_nullable
as PickedDocument?,rcDocKey: freezed == rcDocKey ? _self.rcDocKey : rcDocKey // ignore: cast_nullable_to_non_nullable
as String?,vehiclePicDocument: freezed == vehiclePicDocument ? _self.vehiclePicDocument : vehiclePicDocument // ignore: cast_nullable_to_non_nullable
as PickedDocument?,setAsActive: freezed == setAsActive ? _self.setAsActive : setAsActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
