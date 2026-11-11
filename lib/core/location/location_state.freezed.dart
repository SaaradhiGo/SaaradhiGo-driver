// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState()';
}


}

/// @nodoc
class $LocationStateCopyWith<$Res>  {
$LocationStateCopyWith(LocationState _, $Res Function(LocationState) __);
}


/// Adds pattern-matching-related methods to [LocationState].
extension LocationStatePatterns on LocationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LocationStateInitial value)?  initial,TResult Function( LocationStateRequesting value)?  requesting,TResult Function( LocationStateServiceDisabled value)?  serviceDisabled,TResult Function( LocationStatePermissionDenied value)?  permissionDenied,TResult Function( LocationStateAcquiring value)?  acquiring,TResult Function( LocationStateTracking value)?  tracking,TResult Function( LocationStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial(_that);case LocationStateRequesting() when requesting != null:
return requesting(_that);case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled(_that);case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case LocationStateAcquiring() when acquiring != null:
return acquiring(_that);case LocationStateTracking() when tracking != null:
return tracking(_that);case LocationStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LocationStateInitial value)  initial,required TResult Function( LocationStateRequesting value)  requesting,required TResult Function( LocationStateServiceDisabled value)  serviceDisabled,required TResult Function( LocationStatePermissionDenied value)  permissionDenied,required TResult Function( LocationStateAcquiring value)  acquiring,required TResult Function( LocationStateTracking value)  tracking,required TResult Function( LocationStateError value)  error,}){
final _that = this;
switch (_that) {
case LocationStateInitial():
return initial(_that);case LocationStateRequesting():
return requesting(_that);case LocationStateServiceDisabled():
return serviceDisabled(_that);case LocationStatePermissionDenied():
return permissionDenied(_that);case LocationStateAcquiring():
return acquiring(_that);case LocationStateTracking():
return tracking(_that);case LocationStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LocationStateInitial value)?  initial,TResult? Function( LocationStateRequesting value)?  requesting,TResult? Function( LocationStateServiceDisabled value)?  serviceDisabled,TResult? Function( LocationStatePermissionDenied value)?  permissionDenied,TResult? Function( LocationStateAcquiring value)?  acquiring,TResult? Function( LocationStateTracking value)?  tracking,TResult? Function( LocationStateError value)?  error,}){
final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial(_that);case LocationStateRequesting() when requesting != null:
return requesting(_that);case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled(_that);case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case LocationStateAcquiring() when acquiring != null:
return acquiring(_that);case LocationStateTracking() when tracking != null:
return tracking(_that);case LocationStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  requesting,TResult Function()?  serviceDisabled,TResult Function( bool permanent)?  permissionDenied,TResult Function()?  acquiring,TResult Function( LatLng position,  DateTime timestamp,  double? heading,  double? accuracy,  bool weakSignal,  bool hasBackgroundAccess)?  tracking,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial();case LocationStateRequesting() when requesting != null:
return requesting();case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled();case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied(_that.permanent);case LocationStateAcquiring() when acquiring != null:
return acquiring();case LocationStateTracking() when tracking != null:
return tracking(_that.position,_that.timestamp,_that.heading,_that.accuracy,_that.weakSignal,_that.hasBackgroundAccess);case LocationStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  requesting,required TResult Function()  serviceDisabled,required TResult Function( bool permanent)  permissionDenied,required TResult Function()  acquiring,required TResult Function( LatLng position,  DateTime timestamp,  double? heading,  double? accuracy,  bool weakSignal,  bool hasBackgroundAccess)  tracking,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case LocationStateInitial():
return initial();case LocationStateRequesting():
return requesting();case LocationStateServiceDisabled():
return serviceDisabled();case LocationStatePermissionDenied():
return permissionDenied(_that.permanent);case LocationStateAcquiring():
return acquiring();case LocationStateTracking():
return tracking(_that.position,_that.timestamp,_that.heading,_that.accuracy,_that.weakSignal,_that.hasBackgroundAccess);case LocationStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  requesting,TResult? Function()?  serviceDisabled,TResult? Function( bool permanent)?  permissionDenied,TResult? Function()?  acquiring,TResult? Function( LatLng position,  DateTime timestamp,  double? heading,  double? accuracy,  bool weakSignal,  bool hasBackgroundAccess)?  tracking,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial();case LocationStateRequesting() when requesting != null:
return requesting();case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled();case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied(_that.permanent);case LocationStateAcquiring() when acquiring != null:
return acquiring();case LocationStateTracking() when tracking != null:
return tracking(_that.position,_that.timestamp,_that.heading,_that.accuracy,_that.weakSignal,_that.hasBackgroundAccess);case LocationStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class LocationStateInitial implements LocationState {
  const LocationStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.initial()';
}


}




/// @nodoc


class LocationStateRequesting implements LocationState {
  const LocationStateRequesting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateRequesting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.requesting()';
}


}




/// @nodoc


class LocationStateServiceDisabled implements LocationState {
  const LocationStateServiceDisabled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateServiceDisabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.serviceDisabled()';
}


}




/// @nodoc


class LocationStatePermissionDenied implements LocationState {
  const LocationStatePermissionDenied({required this.permanent});
  

 final  bool permanent;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationStatePermissionDeniedCopyWith<LocationStatePermissionDenied> get copyWith => _$LocationStatePermissionDeniedCopyWithImpl<LocationStatePermissionDenied>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStatePermissionDenied&&(identical(other.permanent, permanent) || other.permanent == permanent));
}


@override
int get hashCode => Object.hash(runtimeType,permanent);

@override
String toString() {
  return 'LocationState.permissionDenied(permanent: $permanent)';
}


}

/// @nodoc
abstract mixin class $LocationStatePermissionDeniedCopyWith<$Res> implements $LocationStateCopyWith<$Res> {
  factory $LocationStatePermissionDeniedCopyWith(LocationStatePermissionDenied value, $Res Function(LocationStatePermissionDenied) _then) = _$LocationStatePermissionDeniedCopyWithImpl;
@useResult
$Res call({
 bool permanent
});




}
/// @nodoc
class _$LocationStatePermissionDeniedCopyWithImpl<$Res>
    implements $LocationStatePermissionDeniedCopyWith<$Res> {
  _$LocationStatePermissionDeniedCopyWithImpl(this._self, this._then);

  final LocationStatePermissionDenied _self;
  final $Res Function(LocationStatePermissionDenied) _then;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? permanent = null,}) {
  return _then(LocationStatePermissionDenied(
permanent: null == permanent ? _self.permanent : permanent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LocationStateAcquiring implements LocationState {
  const LocationStateAcquiring();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateAcquiring);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.acquiring()';
}


}




/// @nodoc


class LocationStateTracking implements LocationState {
  const LocationStateTracking({required this.position, required this.timestamp, this.heading, this.accuracy, this.weakSignal = false, this.hasBackgroundAccess = false});
  

 final  LatLng position;
 final  DateTime timestamp;
 final  double? heading;
 final  double? accuracy;
@JsonKey() final  bool weakSignal;
@JsonKey() final  bool hasBackgroundAccess;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationStateTrackingCopyWith<LocationStateTracking> get copyWith => _$LocationStateTrackingCopyWithImpl<LocationStateTracking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateTracking&&(identical(other.position, position) || other.position == position)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.weakSignal, weakSignal) || other.weakSignal == weakSignal)&&(identical(other.hasBackgroundAccess, hasBackgroundAccess) || other.hasBackgroundAccess == hasBackgroundAccess));
}


@override
int get hashCode => Object.hash(runtimeType,position,timestamp,heading,accuracy,weakSignal,hasBackgroundAccess);

@override
String toString() {
  return 'LocationState.tracking(position: $position, timestamp: $timestamp, heading: $heading, accuracy: $accuracy, weakSignal: $weakSignal, hasBackgroundAccess: $hasBackgroundAccess)';
}


}

/// @nodoc
abstract mixin class $LocationStateTrackingCopyWith<$Res> implements $LocationStateCopyWith<$Res> {
  factory $LocationStateTrackingCopyWith(LocationStateTracking value, $Res Function(LocationStateTracking) _then) = _$LocationStateTrackingCopyWithImpl;
@useResult
$Res call({
 LatLng position, DateTime timestamp, double? heading, double? accuracy, bool weakSignal, bool hasBackgroundAccess
});




}
/// @nodoc
class _$LocationStateTrackingCopyWithImpl<$Res>
    implements $LocationStateTrackingCopyWith<$Res> {
  _$LocationStateTrackingCopyWithImpl(this._self, this._then);

  final LocationStateTracking _self;
  final $Res Function(LocationStateTracking) _then;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? position = null,Object? timestamp = null,Object? heading = freezed,Object? accuracy = freezed,Object? weakSignal = null,Object? hasBackgroundAccess = null,}) {
  return _then(LocationStateTracking(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as LatLng,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,heading: freezed == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as double?,accuracy: freezed == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double?,weakSignal: null == weakSignal ? _self.weakSignal : weakSignal // ignore: cast_nullable_to_non_nullable
as bool,hasBackgroundAccess: null == hasBackgroundAccess ? _self.hasBackgroundAccess : hasBackgroundAccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LocationStateError implements LocationState {
  const LocationStateError(this.message);
  

 final  String message;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationStateErrorCopyWith<LocationStateError> get copyWith => _$LocationStateErrorCopyWithImpl<LocationStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LocationState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $LocationStateErrorCopyWith<$Res> implements $LocationStateCopyWith<$Res> {
  factory $LocationStateErrorCopyWith(LocationStateError value, $Res Function(LocationStateError) _then) = _$LocationStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$LocationStateErrorCopyWithImpl<$Res>
    implements $LocationStateErrorCopyWith<$Res> {
  _$LocationStateErrorCopyWithImpl(this._self, this._then);

  final LocationStateError _self;
  final $Res Function(LocationStateError) _then;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(LocationStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
