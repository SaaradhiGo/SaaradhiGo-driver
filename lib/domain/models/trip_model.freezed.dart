// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripModel {

@JsonKey(readValue: _readId) int get id;@JsonKey(defaultValue: TripStatus.requested) TripStatus get status;@JsonKey(name: 'rider_id') int? get riderId;@JsonKey(name: 'rider_name') String? get riderName;@JsonKey(name: 'driver_id') int? get driverId;@JsonKey(name: 'driver_name') String? get driverName;@JsonKey(name: 'pickup_lat') double? get pickupLat;@JsonKey(readValue: _readPickupLng) double? get pickupLng;@JsonKey(name: 'destination_lat') double? get destinationLat;@JsonKey(readValue: _readDestinationLng) double? get destinationLng;@JsonKey(name: 'pickup_address') String? get pickupAddress;@JsonKey(name: 'destination_address') String? get destinationAddress;@JsonKey(readValue: _readEstimatedFare) String? get estimatedFare;@JsonKey(readValue: _readFinalFare) String? get finalFare;@JsonKey(name: 'payment_method') String? get paymentMethod;@JsonKey(name: 'vehicle_type') String? get vehicleType; String? get otp;@JsonKey(readValue: _readDistanceKm) double? get distanceKm;@JsonKey(readValue: _readDurationMin) double? get durationMin;
/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripModelCopyWith<TripModel> get copyWith => _$TripModelCopyWithImpl<TripModel>(this as TripModel, _$identity);

  /// Serializes this TripModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.riderId, riderId) || other.riderId == riderId)&&(identical(other.riderName, riderName) || other.riderName == riderName)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.destinationLat, destinationLat) || other.destinationLat == destinationLat)&&(identical(other.destinationLng, destinationLng) || other.destinationLng == destinationLng)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.destinationAddress, destinationAddress) || other.destinationAddress == destinationAddress)&&(identical(other.estimatedFare, estimatedFare) || other.estimatedFare == estimatedFare)&&(identical(other.finalFare, finalFare) || other.finalFare == finalFare)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.otp, otp) || other.otp == otp)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,riderId,riderName,driverId,driverName,pickupLat,pickupLng,destinationLat,destinationLng,pickupAddress,destinationAddress,estimatedFare,finalFare,paymentMethod,vehicleType,otp,distanceKm,durationMin]);

@override
String toString() {
  return 'TripModel(id: $id, status: $status, riderId: $riderId, riderName: $riderName, driverId: $driverId, driverName: $driverName, pickupLat: $pickupLat, pickupLng: $pickupLng, destinationLat: $destinationLat, destinationLng: $destinationLng, pickupAddress: $pickupAddress, destinationAddress: $destinationAddress, estimatedFare: $estimatedFare, finalFare: $finalFare, paymentMethod: $paymentMethod, vehicleType: $vehicleType, otp: $otp, distanceKm: $distanceKm, durationMin: $durationMin)';
}


}

/// @nodoc
abstract mixin class $TripModelCopyWith<$Res>  {
  factory $TripModelCopyWith(TripModel value, $Res Function(TripModel) _then) = _$TripModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: _readId) int id,@JsonKey(defaultValue: TripStatus.requested) TripStatus status,@JsonKey(name: 'rider_id') int? riderId,@JsonKey(name: 'rider_name') String? riderName,@JsonKey(name: 'driver_id') int? driverId,@JsonKey(name: 'driver_name') String? driverName,@JsonKey(name: 'pickup_lat') double? pickupLat,@JsonKey(readValue: _readPickupLng) double? pickupLng,@JsonKey(name: 'destination_lat') double? destinationLat,@JsonKey(readValue: _readDestinationLng) double? destinationLng,@JsonKey(name: 'pickup_address') String? pickupAddress,@JsonKey(name: 'destination_address') String? destinationAddress,@JsonKey(readValue: _readEstimatedFare) String? estimatedFare,@JsonKey(readValue: _readFinalFare) String? finalFare,@JsonKey(name: 'payment_method') String? paymentMethod,@JsonKey(name: 'vehicle_type') String? vehicleType, String? otp,@JsonKey(readValue: _readDistanceKm) double? distanceKm,@JsonKey(readValue: _readDurationMin) double? durationMin
});




}
/// @nodoc
class _$TripModelCopyWithImpl<$Res>
    implements $TripModelCopyWith<$Res> {
  _$TripModelCopyWithImpl(this._self, this._then);

  final TripModel _self;
  final $Res Function(TripModel) _then;

/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? riderId = freezed,Object? riderName = freezed,Object? driverId = freezed,Object? driverName = freezed,Object? pickupLat = freezed,Object? pickupLng = freezed,Object? destinationLat = freezed,Object? destinationLng = freezed,Object? pickupAddress = freezed,Object? destinationAddress = freezed,Object? estimatedFare = freezed,Object? finalFare = freezed,Object? paymentMethod = freezed,Object? vehicleType = freezed,Object? otp = freezed,Object? distanceKm = freezed,Object? durationMin = freezed,}) {
  return _then(TripModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,riderId: freezed == riderId ? _self.riderId : riderId // ignore: cast_nullable_to_non_nullable
as int?,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as int?,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,pickupLat: freezed == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double?,pickupLng: freezed == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double?,destinationLat: freezed == destinationLat ? _self.destinationLat : destinationLat // ignore: cast_nullable_to_non_nullable
as double?,destinationLng: freezed == destinationLng ? _self.destinationLng : destinationLng // ignore: cast_nullable_to_non_nullable
as double?,pickupAddress: freezed == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String?,destinationAddress: freezed == destinationAddress ? _self.destinationAddress : destinationAddress // ignore: cast_nullable_to_non_nullable
as String?,estimatedFare: freezed == estimatedFare ? _self.estimatedFare : estimatedFare // ignore: cast_nullable_to_non_nullable
as String?,finalFare: freezed == finalFare ? _self.finalFare : finalFare // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,otp: freezed == otp ? _self.otp : otp // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,durationMin: freezed == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripModel].
extension TripModelPatterns on TripModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripModel value)  $default,){
final _that = this;
switch (_that) {
case _TripModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripModel value)?  $default,){
final _that = this;
switch (_that) {
case _TripModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(readValue: _readId)  int id, @JsonKey(defaultValue: TripStatus.requested)  TripStatus status, @JsonKey(name: 'rider_id')  int? riderId, @JsonKey(name: 'rider_name')  String? riderName, @JsonKey(name: 'driver_id')  int? driverId, @JsonKey(name: 'driver_name')  String? driverName, @JsonKey(name: 'pickup_lat')  double? pickupLat, @JsonKey(readValue: _readPickupLng)  double? pickupLng, @JsonKey(name: 'destination_lat')  double? destinationLat, @JsonKey(readValue: _readDestinationLng)  double? destinationLng, @JsonKey(name: 'pickup_address')  String? pickupAddress, @JsonKey(name: 'destination_address')  String? destinationAddress, @JsonKey(readValue: _readEstimatedFare)  String? estimatedFare, @JsonKey(readValue: _readFinalFare)  String? finalFare, @JsonKey(name: 'payment_method')  String? paymentMethod, @JsonKey(name: 'vehicle_type')  String? vehicleType,  String? otp, @JsonKey(readValue: _readDistanceKm)  double? distanceKm, @JsonKey(readValue: _readDurationMin)  double? durationMin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripModel() when $default != null:
return $default(_that.id,_that.status,_that.riderId,_that.riderName,_that.driverId,_that.driverName,_that.pickupLat,_that.pickupLng,_that.destinationLat,_that.destinationLng,_that.pickupAddress,_that.destinationAddress,_that.estimatedFare,_that.finalFare,_that.paymentMethod,_that.vehicleType,_that.otp,_that.distanceKm,_that.durationMin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(readValue: _readId)  int id, @JsonKey(defaultValue: TripStatus.requested)  TripStatus status, @JsonKey(name: 'rider_id')  int? riderId, @JsonKey(name: 'rider_name')  String? riderName, @JsonKey(name: 'driver_id')  int? driverId, @JsonKey(name: 'driver_name')  String? driverName, @JsonKey(name: 'pickup_lat')  double? pickupLat, @JsonKey(readValue: _readPickupLng)  double? pickupLng, @JsonKey(name: 'destination_lat')  double? destinationLat, @JsonKey(readValue: _readDestinationLng)  double? destinationLng, @JsonKey(name: 'pickup_address')  String? pickupAddress, @JsonKey(name: 'destination_address')  String? destinationAddress, @JsonKey(readValue: _readEstimatedFare)  String? estimatedFare, @JsonKey(readValue: _readFinalFare)  String? finalFare, @JsonKey(name: 'payment_method')  String? paymentMethod, @JsonKey(name: 'vehicle_type')  String? vehicleType,  String? otp, @JsonKey(readValue: _readDistanceKm)  double? distanceKm, @JsonKey(readValue: _readDurationMin)  double? durationMin)  $default,) {final _that = this;
switch (_that) {
case _TripModel():
return $default(_that.id,_that.status,_that.riderId,_that.riderName,_that.driverId,_that.driverName,_that.pickupLat,_that.pickupLng,_that.destinationLat,_that.destinationLng,_that.pickupAddress,_that.destinationAddress,_that.estimatedFare,_that.finalFare,_that.paymentMethod,_that.vehicleType,_that.otp,_that.distanceKm,_that.durationMin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(readValue: _readId)  int id, @JsonKey(defaultValue: TripStatus.requested)  TripStatus status, @JsonKey(name: 'rider_id')  int? riderId, @JsonKey(name: 'rider_name')  String? riderName, @JsonKey(name: 'driver_id')  int? driverId, @JsonKey(name: 'driver_name')  String? driverName, @JsonKey(name: 'pickup_lat')  double? pickupLat, @JsonKey(readValue: _readPickupLng)  double? pickupLng, @JsonKey(name: 'destination_lat')  double? destinationLat, @JsonKey(readValue: _readDestinationLng)  double? destinationLng, @JsonKey(name: 'pickup_address')  String? pickupAddress, @JsonKey(name: 'destination_address')  String? destinationAddress, @JsonKey(readValue: _readEstimatedFare)  String? estimatedFare, @JsonKey(readValue: _readFinalFare)  String? finalFare, @JsonKey(name: 'payment_method')  String? paymentMethod, @JsonKey(name: 'vehicle_type')  String? vehicleType,  String? otp, @JsonKey(readValue: _readDistanceKm)  double? distanceKm, @JsonKey(readValue: _readDurationMin)  double? durationMin)?  $default,) {final _that = this;
switch (_that) {
case _TripModel() when $default != null:
return $default(_that.id,_that.status,_that.riderId,_that.riderName,_that.driverId,_that.driverName,_that.pickupLat,_that.pickupLng,_that.destinationLat,_that.destinationLng,_that.pickupAddress,_that.destinationAddress,_that.estimatedFare,_that.finalFare,_that.paymentMethod,_that.vehicleType,_that.otp,_that.distanceKm,_that.durationMin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripModel implements TripModel {
  const _TripModel({@JsonKey(readValue: _readId) required this.id, @JsonKey(defaultValue: TripStatus.requested) required this.status, @JsonKey(name: 'rider_id') this.riderId, @JsonKey(name: 'rider_name') this.riderName, @JsonKey(name: 'driver_id') this.driverId, @JsonKey(name: 'driver_name') this.driverName, @JsonKey(name: 'pickup_lat') this.pickupLat, @JsonKey(readValue: _readPickupLng) this.pickupLng, @JsonKey(name: 'destination_lat') this.destinationLat, @JsonKey(readValue: _readDestinationLng) this.destinationLng, @JsonKey(name: 'pickup_address') this.pickupAddress, @JsonKey(name: 'destination_address') this.destinationAddress, @JsonKey(readValue: _readEstimatedFare) this.estimatedFare, @JsonKey(readValue: _readFinalFare) this.finalFare, @JsonKey(name: 'payment_method') this.paymentMethod, @JsonKey(name: 'vehicle_type') this.vehicleType, this.otp, @JsonKey(readValue: _readDistanceKm) this.distanceKm, @JsonKey(readValue: _readDurationMin) this.durationMin});
  factory _TripModel.fromJson(Map<String, dynamic> json) => _$TripModelFromJson(json);

@override@JsonKey(readValue: _readId) final  int id;
@override@JsonKey(defaultValue: TripStatus.requested) final  TripStatus status;
@override@JsonKey(name: 'rider_id') final  int? riderId;
@override@JsonKey(name: 'rider_name') final  String? riderName;
@override@JsonKey(name: 'driver_id') final  int? driverId;
@override@JsonKey(name: 'driver_name') final  String? driverName;
@override@JsonKey(name: 'pickup_lat') final  double? pickupLat;
@override@JsonKey(readValue: _readPickupLng) final  double? pickupLng;
@override@JsonKey(name: 'destination_lat') final  double? destinationLat;
@override@JsonKey(readValue: _readDestinationLng) final  double? destinationLng;
@override@JsonKey(name: 'pickup_address') final  String? pickupAddress;
@override@JsonKey(name: 'destination_address') final  String? destinationAddress;
@override@JsonKey(readValue: _readEstimatedFare) final  String? estimatedFare;
@override@JsonKey(readValue: _readFinalFare) final  String? finalFare;
@override@JsonKey(name: 'payment_method') final  String? paymentMethod;
@override@JsonKey(name: 'vehicle_type') final  String? vehicleType;
@override final  String? otp;
@override@JsonKey(readValue: _readDistanceKm) final  double? distanceKm;
@override@JsonKey(readValue: _readDurationMin) final  double? durationMin;

/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripModelCopyWith<_TripModel> get copyWith => __$TripModelCopyWithImpl<_TripModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.riderId, riderId) || other.riderId == riderId)&&(identical(other.riderName, riderName) || other.riderName == riderName)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.destinationLat, destinationLat) || other.destinationLat == destinationLat)&&(identical(other.destinationLng, destinationLng) || other.destinationLng == destinationLng)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.destinationAddress, destinationAddress) || other.destinationAddress == destinationAddress)&&(identical(other.estimatedFare, estimatedFare) || other.estimatedFare == estimatedFare)&&(identical(other.finalFare, finalFare) || other.finalFare == finalFare)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.otp, otp) || other.otp == otp)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,riderId,riderName,driverId,driverName,pickupLat,pickupLng,destinationLat,destinationLng,pickupAddress,destinationAddress,estimatedFare,finalFare,paymentMethod,vehicleType,otp,distanceKm,durationMin]);

@override
String toString() {
  return 'TripModel(id: $id, status: $status, riderId: $riderId, riderName: $riderName, driverId: $driverId, driverName: $driverName, pickupLat: $pickupLat, pickupLng: $pickupLng, destinationLat: $destinationLat, destinationLng: $destinationLng, pickupAddress: $pickupAddress, destinationAddress: $destinationAddress, estimatedFare: $estimatedFare, finalFare: $finalFare, paymentMethod: $paymentMethod, vehicleType: $vehicleType, otp: $otp, distanceKm: $distanceKm, durationMin: $durationMin)';
}


}

/// @nodoc
abstract mixin class _$TripModelCopyWith<$Res> implements $TripModelCopyWith<$Res> {
  factory _$TripModelCopyWith(_TripModel value, $Res Function(_TripModel) _then) = __$TripModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: _readId) int id,@JsonKey(defaultValue: TripStatus.requested) TripStatus status,@JsonKey(name: 'rider_id') int? riderId,@JsonKey(name: 'rider_name') String? riderName,@JsonKey(name: 'driver_id') int? driverId,@JsonKey(name: 'driver_name') String? driverName,@JsonKey(name: 'pickup_lat') double? pickupLat,@JsonKey(readValue: _readPickupLng) double? pickupLng,@JsonKey(name: 'destination_lat') double? destinationLat,@JsonKey(readValue: _readDestinationLng) double? destinationLng,@JsonKey(name: 'pickup_address') String? pickupAddress,@JsonKey(name: 'destination_address') String? destinationAddress,@JsonKey(readValue: _readEstimatedFare) String? estimatedFare,@JsonKey(readValue: _readFinalFare) String? finalFare,@JsonKey(name: 'payment_method') String? paymentMethod,@JsonKey(name: 'vehicle_type') String? vehicleType, String? otp,@JsonKey(readValue: _readDistanceKm) double? distanceKm,@JsonKey(readValue: _readDurationMin) double? durationMin
});




}
/// @nodoc
class __$TripModelCopyWithImpl<$Res>
    implements _$TripModelCopyWith<$Res> {
  __$TripModelCopyWithImpl(this._self, this._then);

  final _TripModel _self;
  final $Res Function(_TripModel) _then;

/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? riderId = freezed,Object? riderName = freezed,Object? driverId = freezed,Object? driverName = freezed,Object? pickupLat = freezed,Object? pickupLng = freezed,Object? destinationLat = freezed,Object? destinationLng = freezed,Object? pickupAddress = freezed,Object? destinationAddress = freezed,Object? estimatedFare = freezed,Object? finalFare = freezed,Object? paymentMethod = freezed,Object? vehicleType = freezed,Object? otp = freezed,Object? distanceKm = freezed,Object? durationMin = freezed,}) {
  return _then(_TripModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,riderId: freezed == riderId ? _self.riderId : riderId // ignore: cast_nullable_to_non_nullable
as int?,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as int?,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,pickupLat: freezed == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double?,pickupLng: freezed == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double?,destinationLat: freezed == destinationLat ? _self.destinationLat : destinationLat // ignore: cast_nullable_to_non_nullable
as double?,destinationLng: freezed == destinationLng ? _self.destinationLng : destinationLng // ignore: cast_nullable_to_non_nullable
as double?,pickupAddress: freezed == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String?,destinationAddress: freezed == destinationAddress ? _self.destinationAddress : destinationAddress // ignore: cast_nullable_to_non_nullable
as String?,estimatedFare: freezed == estimatedFare ? _self.estimatedFare : estimatedFare // ignore: cast_nullable_to_non_nullable
as String?,finalFare: freezed == finalFare ? _self.finalFare : finalFare // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,otp: freezed == otp ? _self.otp : otp // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,durationMin: freezed == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
