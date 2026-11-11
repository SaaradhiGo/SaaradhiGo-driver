// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VehicleModel {

 int get id;@JsonKey(name: 'vehicle_number') String get vehicleNumber;@VehicleTypeConverter()@JsonKey(name: 'vehicle_type') String get vehicleType; String? get brand; String? get model; String? get color; int? get year; int? get capacity; String? get status;@JsonKey(name: 'rc_doc') String? get rcDoc;@JsonKey(name: 'vehicle_pic') String? get vehiclePic;@JsonKey(name: 'fuel_type') String? get fuelType;@JsonKey(name: 'insurance_doc') String? get insuranceDoc;@JsonKey(name: 'insurance_expiry') DateTime? get insuranceExpiry;@JsonKey(name: 'fitness_expiry') DateTime? get fitnessExpiry;
/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleModelCopyWith<VehicleModel> get copyWith => _$VehicleModelCopyWithImpl<VehicleModel>(this as VehicleModel, _$identity);

  /// Serializes this VehicleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.color, color) || other.color == color)&&(identical(other.year, year) || other.year == year)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.status, status) || other.status == status)&&(identical(other.rcDoc, rcDoc) || other.rcDoc == rcDoc)&&(identical(other.vehiclePic, vehiclePic) || other.vehiclePic == vehiclePic)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.insuranceDoc, insuranceDoc) || other.insuranceDoc == insuranceDoc)&&(identical(other.insuranceExpiry, insuranceExpiry) || other.insuranceExpiry == insuranceExpiry)&&(identical(other.fitnessExpiry, fitnessExpiry) || other.fitnessExpiry == fitnessExpiry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleNumber,vehicleType,brand,model,color,year,capacity,status,rcDoc,vehiclePic,fuelType,insuranceDoc,insuranceExpiry,fitnessExpiry);

@override
String toString() {
  return 'VehicleModel(id: $id, vehicleNumber: $vehicleNumber, vehicleType: $vehicleType, brand: $brand, model: $model, color: $color, year: $year, capacity: $capacity, status: $status, rcDoc: $rcDoc, vehiclePic: $vehiclePic, fuelType: $fuelType, insuranceDoc: $insuranceDoc, insuranceExpiry: $insuranceExpiry, fitnessExpiry: $fitnessExpiry)';
}


}

/// @nodoc
abstract mixin class $VehicleModelCopyWith<$Res>  {
  factory $VehicleModelCopyWith(VehicleModel value, $Res Function(VehicleModel) _then) = _$VehicleModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'vehicle_number') String vehicleNumber,@VehicleTypeConverter()@JsonKey(name: 'vehicle_type') String vehicleType, String? brand, String? model, String? color, int? year, int? capacity, String? status,@JsonKey(name: 'rc_doc') String? rcDoc,@JsonKey(name: 'vehicle_pic') String? vehiclePic,@JsonKey(name: 'fuel_type') String? fuelType,@JsonKey(name: 'insurance_doc') String? insuranceDoc,@JsonKey(name: 'insurance_expiry') DateTime? insuranceExpiry,@JsonKey(name: 'fitness_expiry') DateTime? fitnessExpiry
});




}
/// @nodoc
class _$VehicleModelCopyWithImpl<$Res>
    implements $VehicleModelCopyWith<$Res> {
  _$VehicleModelCopyWithImpl(this._self, this._then);

  final VehicleModel _self;
  final $Res Function(VehicleModel) _then;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleNumber = null,Object? vehicleType = null,Object? brand = freezed,Object? model = freezed,Object? color = freezed,Object? year = freezed,Object? capacity = freezed,Object? status = freezed,Object? rcDoc = freezed,Object? vehiclePic = freezed,Object? fuelType = freezed,Object? insuranceDoc = freezed,Object? insuranceExpiry = freezed,Object? fitnessExpiry = freezed,}) {
  return _then(VehicleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vehicleNumber: null == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,rcDoc: freezed == rcDoc ? _self.rcDoc : rcDoc // ignore: cast_nullable_to_non_nullable
as String?,vehiclePic: freezed == vehiclePic ? _self.vehiclePic : vehiclePic // ignore: cast_nullable_to_non_nullable
as String?,fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String?,insuranceDoc: freezed == insuranceDoc ? _self.insuranceDoc : insuranceDoc // ignore: cast_nullable_to_non_nullable
as String?,insuranceExpiry: freezed == insuranceExpiry ? _self.insuranceExpiry : insuranceExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,fitnessExpiry: freezed == fitnessExpiry ? _self.fitnessExpiry : fitnessExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleModel].
extension VehicleModelPatterns on VehicleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleModel value)  $default,){
final _that = this;
switch (_that) {
case _VehicleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleModel value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vehicle_number')  String vehicleNumber, @VehicleTypeConverter()@JsonKey(name: 'vehicle_type')  String vehicleType,  String? brand,  String? model,  String? color,  int? year,  int? capacity,  String? status, @JsonKey(name: 'rc_doc')  String? rcDoc, @JsonKey(name: 'vehicle_pic')  String? vehiclePic, @JsonKey(name: 'fuel_type')  String? fuelType, @JsonKey(name: 'insurance_doc')  String? insuranceDoc, @JsonKey(name: 'insurance_expiry')  DateTime? insuranceExpiry, @JsonKey(name: 'fitness_expiry')  DateTime? fitnessExpiry)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that.id,_that.vehicleNumber,_that.vehicleType,_that.brand,_that.model,_that.color,_that.year,_that.capacity,_that.status,_that.rcDoc,_that.vehiclePic,_that.fuelType,_that.insuranceDoc,_that.insuranceExpiry,_that.fitnessExpiry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vehicle_number')  String vehicleNumber, @VehicleTypeConverter()@JsonKey(name: 'vehicle_type')  String vehicleType,  String? brand,  String? model,  String? color,  int? year,  int? capacity,  String? status, @JsonKey(name: 'rc_doc')  String? rcDoc, @JsonKey(name: 'vehicle_pic')  String? vehiclePic, @JsonKey(name: 'fuel_type')  String? fuelType, @JsonKey(name: 'insurance_doc')  String? insuranceDoc, @JsonKey(name: 'insurance_expiry')  DateTime? insuranceExpiry, @JsonKey(name: 'fitness_expiry')  DateTime? fitnessExpiry)  $default,) {final _that = this;
switch (_that) {
case _VehicleModel():
return $default(_that.id,_that.vehicleNumber,_that.vehicleType,_that.brand,_that.model,_that.color,_that.year,_that.capacity,_that.status,_that.rcDoc,_that.vehiclePic,_that.fuelType,_that.insuranceDoc,_that.insuranceExpiry,_that.fitnessExpiry);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'vehicle_number')  String vehicleNumber, @VehicleTypeConverter()@JsonKey(name: 'vehicle_type')  String vehicleType,  String? brand,  String? model,  String? color,  int? year,  int? capacity,  String? status, @JsonKey(name: 'rc_doc')  String? rcDoc, @JsonKey(name: 'vehicle_pic')  String? vehiclePic, @JsonKey(name: 'fuel_type')  String? fuelType, @JsonKey(name: 'insurance_doc')  String? insuranceDoc, @JsonKey(name: 'insurance_expiry')  DateTime? insuranceExpiry, @JsonKey(name: 'fitness_expiry')  DateTime? fitnessExpiry)?  $default,) {final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that.id,_that.vehicleNumber,_that.vehicleType,_that.brand,_that.model,_that.color,_that.year,_that.capacity,_that.status,_that.rcDoc,_that.vehiclePic,_that.fuelType,_that.insuranceDoc,_that.insuranceExpiry,_that.fitnessExpiry);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleModel implements VehicleModel {
  const _VehicleModel({required this.id, @JsonKey(name: 'vehicle_number') required this.vehicleNumber, @VehicleTypeConverter()@JsonKey(name: 'vehicle_type') required this.vehicleType, this.brand, this.model, this.color, this.year, this.capacity, this.status, @JsonKey(name: 'rc_doc') this.rcDoc, @JsonKey(name: 'vehicle_pic') this.vehiclePic, @JsonKey(name: 'fuel_type') this.fuelType, @JsonKey(name: 'insurance_doc') this.insuranceDoc, @JsonKey(name: 'insurance_expiry') this.insuranceExpiry, @JsonKey(name: 'fitness_expiry') this.fitnessExpiry});
  factory _VehicleModel.fromJson(Map<String, dynamic> json) => _$VehicleModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'vehicle_number') final  String vehicleNumber;
@override@VehicleTypeConverter()@JsonKey(name: 'vehicle_type') final  String vehicleType;
@override final  String? brand;
@override final  String? model;
@override final  String? color;
@override final  int? year;
@override final  int? capacity;
@override final  String? status;
@override@JsonKey(name: 'rc_doc') final  String? rcDoc;
@override@JsonKey(name: 'vehicle_pic') final  String? vehiclePic;
@override@JsonKey(name: 'fuel_type') final  String? fuelType;
@override@JsonKey(name: 'insurance_doc') final  String? insuranceDoc;
@override@JsonKey(name: 'insurance_expiry') final  DateTime? insuranceExpiry;
@override@JsonKey(name: 'fitness_expiry') final  DateTime? fitnessExpiry;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleModelCopyWith<_VehicleModel> get copyWith => __$VehicleModelCopyWithImpl<_VehicleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.color, color) || other.color == color)&&(identical(other.year, year) || other.year == year)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.status, status) || other.status == status)&&(identical(other.rcDoc, rcDoc) || other.rcDoc == rcDoc)&&(identical(other.vehiclePic, vehiclePic) || other.vehiclePic == vehiclePic)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.insuranceDoc, insuranceDoc) || other.insuranceDoc == insuranceDoc)&&(identical(other.insuranceExpiry, insuranceExpiry) || other.insuranceExpiry == insuranceExpiry)&&(identical(other.fitnessExpiry, fitnessExpiry) || other.fitnessExpiry == fitnessExpiry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleNumber,vehicleType,brand,model,color,year,capacity,status,rcDoc,vehiclePic,fuelType,insuranceDoc,insuranceExpiry,fitnessExpiry);

@override
String toString() {
  return 'VehicleModel(id: $id, vehicleNumber: $vehicleNumber, vehicleType: $vehicleType, brand: $brand, model: $model, color: $color, year: $year, capacity: $capacity, status: $status, rcDoc: $rcDoc, vehiclePic: $vehiclePic, fuelType: $fuelType, insuranceDoc: $insuranceDoc, insuranceExpiry: $insuranceExpiry, fitnessExpiry: $fitnessExpiry)';
}


}

/// @nodoc
abstract mixin class _$VehicleModelCopyWith<$Res> implements $VehicleModelCopyWith<$Res> {
  factory _$VehicleModelCopyWith(_VehicleModel value, $Res Function(_VehicleModel) _then) = __$VehicleModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'vehicle_number') String vehicleNumber,@VehicleTypeConverter()@JsonKey(name: 'vehicle_type') String vehicleType, String? brand, String? model, String? color, int? year, int? capacity, String? status,@JsonKey(name: 'rc_doc') String? rcDoc,@JsonKey(name: 'vehicle_pic') String? vehiclePic,@JsonKey(name: 'fuel_type') String? fuelType,@JsonKey(name: 'insurance_doc') String? insuranceDoc,@JsonKey(name: 'insurance_expiry') DateTime? insuranceExpiry,@JsonKey(name: 'fitness_expiry') DateTime? fitnessExpiry
});




}
/// @nodoc
class __$VehicleModelCopyWithImpl<$Res>
    implements _$VehicleModelCopyWith<$Res> {
  __$VehicleModelCopyWithImpl(this._self, this._then);

  final _VehicleModel _self;
  final $Res Function(_VehicleModel) _then;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleNumber = null,Object? vehicleType = null,Object? brand = freezed,Object? model = freezed,Object? color = freezed,Object? year = freezed,Object? capacity = freezed,Object? status = freezed,Object? rcDoc = freezed,Object? vehiclePic = freezed,Object? fuelType = freezed,Object? insuranceDoc = freezed,Object? insuranceExpiry = freezed,Object? fitnessExpiry = freezed,}) {
  return _then(_VehicleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vehicleNumber: null == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,rcDoc: freezed == rcDoc ? _self.rcDoc : rcDoc // ignore: cast_nullable_to_non_nullable
as String?,vehiclePic: freezed == vehiclePic ? _self.vehiclePic : vehiclePic // ignore: cast_nullable_to_non_nullable
as String?,fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String?,insuranceDoc: freezed == insuranceDoc ? _self.insuranceDoc : insuranceDoc // ignore: cast_nullable_to_non_nullable
as String?,insuranceExpiry: freezed == insuranceExpiry ? _self.insuranceExpiry : insuranceExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,fitnessExpiry: freezed == fitnessExpiry ? _self.fitnessExpiry : fitnessExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
