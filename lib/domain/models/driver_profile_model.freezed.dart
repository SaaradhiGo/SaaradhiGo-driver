// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverProfileModel {

 int get id;@UserOrIdConverter() UserModel? get user;@JsonKey(unknownEnumValue: DriverStatus.offline) DriverStatus get status;@SafeBoolConverter() bool get approved;/// MAY THIS DRIVER OPERATE RIGHT NOW.
///
/// Not the same question as `approved`, which means a human reviewed
/// real documents. The backend computes this from the same rule its
/// dispatch sockets use, so the app and the server stop disagreeing: a
/// QA test driver with simulated eligibility used to be accepted by the
/// sockets and sent to the onboarding wizard by this app at the same
/// time.
///
/// Defaults to false, so a build talking to a backend that does not send
/// it behaves exactly as before.
@SafeBoolConverter()@JsonKey(name: 'dispatch_eligible') bool get dispatchEligible;@JsonKey(name: 'kyc_status') String? get kycStatus;@JsonKey(name: 'license_doc') String? get licenseDoc;@JsonKey(name: 'license_doc_back') String? get licenseDocBack;@SafeDateTimeConverter()@JsonKey(name: 'license_expiry') DateTime? get licenseExpiry;@JsonKey(name: 'active_vehicle') int? get activeVehicle;@JsonKey(name: 'active_vehicle_details') Map<String, dynamic>? get activeVehicleDetails;@JsonKey(name: 'total_trips') int? get totalTrips;@StringDoubleConverter() double? get ratings;
/// Create a copy of DriverProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverProfileModelCopyWith<DriverProfileModel> get copyWith => _$DriverProfileModelCopyWithImpl<DriverProfileModel>(this as DriverProfileModel, _$identity);

  /// Serializes this DriverProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.user, user) || other.user == user)&&(identical(other.status, status) || other.status == status)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.dispatchEligible, dispatchEligible) || other.dispatchEligible == dispatchEligible)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.licenseDoc, licenseDoc) || other.licenseDoc == licenseDoc)&&(identical(other.licenseDocBack, licenseDocBack) || other.licenseDocBack == licenseDocBack)&&(identical(other.licenseExpiry, licenseExpiry) || other.licenseExpiry == licenseExpiry)&&(identical(other.activeVehicle, activeVehicle) || other.activeVehicle == activeVehicle)&&const DeepCollectionEquality().equals(other.activeVehicleDetails, activeVehicleDetails)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.ratings, ratings) || other.ratings == ratings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,user,status,approved,dispatchEligible,kycStatus,licenseDoc,licenseDocBack,licenseExpiry,activeVehicle,const DeepCollectionEquality().hash(activeVehicleDetails),totalTrips,ratings);

@override
String toString() {
  return 'DriverProfileModel(id: $id, user: $user, status: $status, approved: $approved, dispatchEligible: $dispatchEligible, kycStatus: $kycStatus, licenseDoc: $licenseDoc, licenseDocBack: $licenseDocBack, licenseExpiry: $licenseExpiry, activeVehicle: $activeVehicle, activeVehicleDetails: $activeVehicleDetails, totalTrips: $totalTrips, ratings: $ratings)';
}


}

/// @nodoc
abstract mixin class $DriverProfileModelCopyWith<$Res>  {
  factory $DriverProfileModelCopyWith(DriverProfileModel value, $Res Function(DriverProfileModel) _then) = _$DriverProfileModelCopyWithImpl;
@useResult
$Res call({
 int id,@UserOrIdConverter() UserModel? user,@JsonKey(unknownEnumValue: DriverStatus.offline) DriverStatus status,@SafeBoolConverter() bool approved,@SafeBoolConverter()@JsonKey(name: 'dispatch_eligible') bool dispatchEligible,@JsonKey(name: 'kyc_status') String? kycStatus,@JsonKey(name: 'license_doc') String? licenseDoc,@JsonKey(name: 'license_doc_back') String? licenseDocBack,@SafeDateTimeConverter()@JsonKey(name: 'license_expiry') DateTime? licenseExpiry,@JsonKey(name: 'active_vehicle') int? activeVehicle,@JsonKey(name: 'active_vehicle_details') Map<String, dynamic>? activeVehicleDetails,@JsonKey(name: 'total_trips') int? totalTrips,@StringDoubleConverter() double? ratings
});


$UserModelCopyWith<$Res>? get user;

}
/// @nodoc
class _$DriverProfileModelCopyWithImpl<$Res>
    implements $DriverProfileModelCopyWith<$Res> {
  _$DriverProfileModelCopyWithImpl(this._self, this._then);

  final DriverProfileModel _self;
  final $Res Function(DriverProfileModel) _then;

/// Create a copy of DriverProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? user = freezed,Object? status = null,Object? approved = null,Object? dispatchEligible = null,Object? kycStatus = freezed,Object? licenseDoc = freezed,Object? licenseDocBack = freezed,Object? licenseExpiry = freezed,Object? activeVehicle = freezed,Object? activeVehicleDetails = freezed,Object? totalTrips = freezed,Object? ratings = freezed,}) {
  return _then(DriverProfileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserModel?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DriverStatus,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,dispatchEligible: null == dispatchEligible ? _self.dispatchEligible : dispatchEligible // ignore: cast_nullable_to_non_nullable
as bool,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,licenseDoc: freezed == licenseDoc ? _self.licenseDoc : licenseDoc // ignore: cast_nullable_to_non_nullable
as String?,licenseDocBack: freezed == licenseDocBack ? _self.licenseDocBack : licenseDocBack // ignore: cast_nullable_to_non_nullable
as String?,licenseExpiry: freezed == licenseExpiry ? _self.licenseExpiry : licenseExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,activeVehicle: freezed == activeVehicle ? _self.activeVehicle : activeVehicle // ignore: cast_nullable_to_non_nullable
as int?,activeVehicleDetails: freezed == activeVehicleDetails ? _self.activeVehicleDetails : activeVehicleDetails // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,totalTrips: freezed == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int?,ratings: freezed == ratings ? _self.ratings : ratings // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of DriverProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [DriverProfileModel].
extension DriverProfileModelPatterns on DriverProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _DriverProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _DriverProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @UserOrIdConverter()  UserModel? user, @JsonKey(unknownEnumValue: DriverStatus.offline)  DriverStatus status, @SafeBoolConverter()  bool approved, @SafeBoolConverter()@JsonKey(name: 'dispatch_eligible')  bool dispatchEligible, @JsonKey(name: 'kyc_status')  String? kycStatus, @JsonKey(name: 'license_doc')  String? licenseDoc, @JsonKey(name: 'license_doc_back')  String? licenseDocBack, @SafeDateTimeConverter()@JsonKey(name: 'license_expiry')  DateTime? licenseExpiry, @JsonKey(name: 'active_vehicle')  int? activeVehicle, @JsonKey(name: 'active_vehicle_details')  Map<String, dynamic>? activeVehicleDetails, @JsonKey(name: 'total_trips')  int? totalTrips, @StringDoubleConverter()  double? ratings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverProfileModel() when $default != null:
return $default(_that.id,_that.user,_that.status,_that.approved,_that.dispatchEligible,_that.kycStatus,_that.licenseDoc,_that.licenseDocBack,_that.licenseExpiry,_that.activeVehicle,_that.activeVehicleDetails,_that.totalTrips,_that.ratings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @UserOrIdConverter()  UserModel? user, @JsonKey(unknownEnumValue: DriverStatus.offline)  DriverStatus status, @SafeBoolConverter()  bool approved, @SafeBoolConverter()@JsonKey(name: 'dispatch_eligible')  bool dispatchEligible, @JsonKey(name: 'kyc_status')  String? kycStatus, @JsonKey(name: 'license_doc')  String? licenseDoc, @JsonKey(name: 'license_doc_back')  String? licenseDocBack, @SafeDateTimeConverter()@JsonKey(name: 'license_expiry')  DateTime? licenseExpiry, @JsonKey(name: 'active_vehicle')  int? activeVehicle, @JsonKey(name: 'active_vehicle_details')  Map<String, dynamic>? activeVehicleDetails, @JsonKey(name: 'total_trips')  int? totalTrips, @StringDoubleConverter()  double? ratings)  $default,) {final _that = this;
switch (_that) {
case _DriverProfileModel():
return $default(_that.id,_that.user,_that.status,_that.approved,_that.dispatchEligible,_that.kycStatus,_that.licenseDoc,_that.licenseDocBack,_that.licenseExpiry,_that.activeVehicle,_that.activeVehicleDetails,_that.totalTrips,_that.ratings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @UserOrIdConverter()  UserModel? user, @JsonKey(unknownEnumValue: DriverStatus.offline)  DriverStatus status, @SafeBoolConverter()  bool approved, @SafeBoolConverter()@JsonKey(name: 'dispatch_eligible')  bool dispatchEligible, @JsonKey(name: 'kyc_status')  String? kycStatus, @JsonKey(name: 'license_doc')  String? licenseDoc, @JsonKey(name: 'license_doc_back')  String? licenseDocBack, @SafeDateTimeConverter()@JsonKey(name: 'license_expiry')  DateTime? licenseExpiry, @JsonKey(name: 'active_vehicle')  int? activeVehicle, @JsonKey(name: 'active_vehicle_details')  Map<String, dynamic>? activeVehicleDetails, @JsonKey(name: 'total_trips')  int? totalTrips, @StringDoubleConverter()  double? ratings)?  $default,) {final _that = this;
switch (_that) {
case _DriverProfileModel() when $default != null:
return $default(_that.id,_that.user,_that.status,_that.approved,_that.dispatchEligible,_that.kycStatus,_that.licenseDoc,_that.licenseDocBack,_that.licenseExpiry,_that.activeVehicle,_that.activeVehicleDetails,_that.totalTrips,_that.ratings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverProfileModel implements DriverProfileModel {
  const _DriverProfileModel({this.id = 0, @UserOrIdConverter() this.user, @JsonKey(unknownEnumValue: DriverStatus.offline) this.status = DriverStatus.offline, @SafeBoolConverter() this.approved = false, @SafeBoolConverter()@JsonKey(name: 'dispatch_eligible') this.dispatchEligible = false, @JsonKey(name: 'kyc_status') this.kycStatus, @JsonKey(name: 'license_doc') this.licenseDoc, @JsonKey(name: 'license_doc_back') this.licenseDocBack, @SafeDateTimeConverter()@JsonKey(name: 'license_expiry') this.licenseExpiry, @JsonKey(name: 'active_vehicle') this.activeVehicle, @JsonKey(name: 'active_vehicle_details')  Map<String, dynamic>? activeVehicleDetails, @JsonKey(name: 'total_trips') this.totalTrips, @StringDoubleConverter() this.ratings}): _activeVehicleDetails = activeVehicleDetails;
  factory _DriverProfileModel.fromJson(Map<String, dynamic> json) => _$DriverProfileModelFromJson(json);

@override@JsonKey() final  int id;
@override@UserOrIdConverter() final  UserModel? user;
@override@JsonKey(unknownEnumValue: DriverStatus.offline) final  DriverStatus status;
@override@JsonKey()@SafeBoolConverter() final  bool approved;
/// MAY THIS DRIVER OPERATE RIGHT NOW.
///
/// Not the same question as `approved`, which means a human reviewed
/// real documents. The backend computes this from the same rule its
/// dispatch sockets use, so the app and the server stop disagreeing: a
/// QA test driver with simulated eligibility used to be accepted by the
/// sockets and sent to the onboarding wizard by this app at the same
/// time.
///
/// Defaults to false, so a build talking to a backend that does not send
/// it behaves exactly as before.
@override@SafeBoolConverter()@JsonKey(name: 'dispatch_eligible') final  bool dispatchEligible;
@override@JsonKey(name: 'kyc_status') final  String? kycStatus;
@override@JsonKey(name: 'license_doc') final  String? licenseDoc;
@override@JsonKey(name: 'license_doc_back') final  String? licenseDocBack;
@override@SafeDateTimeConverter()@JsonKey(name: 'license_expiry') final  DateTime? licenseExpiry;
@override@JsonKey(name: 'active_vehicle') final  int? activeVehicle;
 final  Map<String, dynamic>? _activeVehicleDetails;
@override@JsonKey(name: 'active_vehicle_details') Map<String, dynamic>? get activeVehicleDetails {
  final value = _activeVehicleDetails;
  if (value == null) return null;
  if (_activeVehicleDetails is EqualUnmodifiableMapView) return _activeVehicleDetails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'total_trips') final  int? totalTrips;
@override@StringDoubleConverter() final  double? ratings;

/// Create a copy of DriverProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverProfileModelCopyWith<_DriverProfileModel> get copyWith => __$DriverProfileModelCopyWithImpl<_DriverProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.user, user) || other.user == user)&&(identical(other.status, status) || other.status == status)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.dispatchEligible, dispatchEligible) || other.dispatchEligible == dispatchEligible)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.licenseDoc, licenseDoc) || other.licenseDoc == licenseDoc)&&(identical(other.licenseDocBack, licenseDocBack) || other.licenseDocBack == licenseDocBack)&&(identical(other.licenseExpiry, licenseExpiry) || other.licenseExpiry == licenseExpiry)&&(identical(other.activeVehicle, activeVehicle) || other.activeVehicle == activeVehicle)&&const DeepCollectionEquality().equals(other._activeVehicleDetails, _activeVehicleDetails)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.ratings, ratings) || other.ratings == ratings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,user,status,approved,dispatchEligible,kycStatus,licenseDoc,licenseDocBack,licenseExpiry,activeVehicle,const DeepCollectionEquality().hash(_activeVehicleDetails),totalTrips,ratings);

@override
String toString() {
  return 'DriverProfileModel(id: $id, user: $user, status: $status, approved: $approved, dispatchEligible: $dispatchEligible, kycStatus: $kycStatus, licenseDoc: $licenseDoc, licenseDocBack: $licenseDocBack, licenseExpiry: $licenseExpiry, activeVehicle: $activeVehicle, activeVehicleDetails: $activeVehicleDetails, totalTrips: $totalTrips, ratings: $ratings)';
}


}

/// @nodoc
abstract mixin class _$DriverProfileModelCopyWith<$Res> implements $DriverProfileModelCopyWith<$Res> {
  factory _$DriverProfileModelCopyWith(_DriverProfileModel value, $Res Function(_DriverProfileModel) _then) = __$DriverProfileModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@UserOrIdConverter() UserModel? user,@JsonKey(unknownEnumValue: DriverStatus.offline) DriverStatus status,@SafeBoolConverter() bool approved,@SafeBoolConverter()@JsonKey(name: 'dispatch_eligible') bool dispatchEligible,@JsonKey(name: 'kyc_status') String? kycStatus,@JsonKey(name: 'license_doc') String? licenseDoc,@JsonKey(name: 'license_doc_back') String? licenseDocBack,@SafeDateTimeConverter()@JsonKey(name: 'license_expiry') DateTime? licenseExpiry,@JsonKey(name: 'active_vehicle') int? activeVehicle,@JsonKey(name: 'active_vehicle_details') Map<String, dynamic>? activeVehicleDetails,@JsonKey(name: 'total_trips') int? totalTrips,@StringDoubleConverter() double? ratings
});


@override $UserModelCopyWith<$Res>? get user;

}
/// @nodoc
class __$DriverProfileModelCopyWithImpl<$Res>
    implements _$DriverProfileModelCopyWith<$Res> {
  __$DriverProfileModelCopyWithImpl(this._self, this._then);

  final _DriverProfileModel _self;
  final $Res Function(_DriverProfileModel) _then;

/// Create a copy of DriverProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? user = freezed,Object? status = null,Object? approved = null,Object? dispatchEligible = null,Object? kycStatus = freezed,Object? licenseDoc = freezed,Object? licenseDocBack = freezed,Object? licenseExpiry = freezed,Object? activeVehicle = freezed,Object? activeVehicleDetails = freezed,Object? totalTrips = freezed,Object? ratings = freezed,}) {
  return _then(_DriverProfileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserModel?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DriverStatus,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,dispatchEligible: null == dispatchEligible ? _self.dispatchEligible : dispatchEligible // ignore: cast_nullable_to_non_nullable
as bool,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,licenseDoc: freezed == licenseDoc ? _self.licenseDoc : licenseDoc // ignore: cast_nullable_to_non_nullable
as String?,licenseDocBack: freezed == licenseDocBack ? _self.licenseDocBack : licenseDocBack // ignore: cast_nullable_to_non_nullable
as String?,licenseExpiry: freezed == licenseExpiry ? _self.licenseExpiry : licenseExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,activeVehicle: freezed == activeVehicle ? _self.activeVehicle : activeVehicle // ignore: cast_nullable_to_non_nullable
as int?,activeVehicleDetails: freezed == activeVehicleDetails ? _self._activeVehicleDetails : activeVehicleDetails // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,totalTrips: freezed == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int?,ratings: freezed == ratings ? _self.ratings : ratings // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of DriverProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
