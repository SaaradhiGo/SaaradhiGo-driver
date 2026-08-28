// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfileState()';
}


}

/// @nodoc
class $ProfileStateCopyWith<$Res>  {
$ProfileStateCopyWith(ProfileState _, $Res Function(ProfileState) __);
}


/// Adds pattern-matching-related methods to [ProfileState].
extension ProfileStatePatterns on ProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProfileStateInitial value)?  initial,TResult Function( ProfileStateLoading value)?  loading,TResult Function( ProfileStateLoaded value)?  loaded,TResult Function( ProfileStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProfileStateInitial() when initial != null:
return initial(_that);case ProfileStateLoading() when loading != null:
return loading(_that);case ProfileStateLoaded() when loaded != null:
return loaded(_that);case ProfileStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProfileStateInitial value)  initial,required TResult Function( ProfileStateLoading value)  loading,required TResult Function( ProfileStateLoaded value)  loaded,required TResult Function( ProfileStateError value)  error,}){
final _that = this;
switch (_that) {
case ProfileStateInitial():
return initial(_that);case ProfileStateLoading():
return loading(_that);case ProfileStateLoaded():
return loaded(_that);case ProfileStateError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProfileStateInitial value)?  initial,TResult? Function( ProfileStateLoading value)?  loading,TResult? Function( ProfileStateLoaded value)?  loaded,TResult? Function( ProfileStateError value)?  error,}){
final _that = this;
switch (_that) {
case ProfileStateInitial() when initial != null:
return initial(_that);case ProfileStateLoading() when loading != null:
return loading(_that);case ProfileStateLoaded() when loaded != null:
return loaded(_that);case ProfileStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( DriverProfileModel profile)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProfileStateInitial() when initial != null:
return initial();case ProfileStateLoading() when loading != null:
return loading();case ProfileStateLoaded() when loaded != null:
return loaded(_that.profile);case ProfileStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( DriverProfileModel profile)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ProfileStateInitial():
return initial();case ProfileStateLoading():
return loading();case ProfileStateLoaded():
return loaded(_that.profile);case ProfileStateError():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( DriverProfileModel profile)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ProfileStateInitial() when initial != null:
return initial();case ProfileStateLoading() when loading != null:
return loading();case ProfileStateLoaded() when loaded != null:
return loaded(_that.profile);case ProfileStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ProfileStateInitial implements ProfileState {
  const ProfileStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfileState.initial()';
}


}




/// @nodoc


class ProfileStateLoading implements ProfileState {
  const ProfileStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfileState.loading()';
}


}




/// @nodoc


class ProfileStateLoaded implements ProfileState {
  const ProfileStateLoaded(this.profile);
  

 final  DriverProfileModel profile;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileStateLoadedCopyWith<ProfileStateLoaded> get copyWith => _$ProfileStateLoadedCopyWithImpl<ProfileStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileStateLoaded&&(identical(other.profile, profile) || other.profile == profile));
}


@override
int get hashCode => Object.hash(runtimeType,profile);

@override
String toString() {
  return 'ProfileState.loaded(profile: $profile)';
}


}

/// @nodoc
abstract mixin class $ProfileStateLoadedCopyWith<$Res> implements $ProfileStateCopyWith<$Res> {
  factory $ProfileStateLoadedCopyWith(ProfileStateLoaded value, $Res Function(ProfileStateLoaded) _then) = _$ProfileStateLoadedCopyWithImpl;
@useResult
$Res call({
 DriverProfileModel profile
});


$DriverProfileModelCopyWith<$Res> get profile;

}
/// @nodoc
class _$ProfileStateLoadedCopyWithImpl<$Res>
    implements $ProfileStateLoadedCopyWith<$Res> {
  _$ProfileStateLoadedCopyWithImpl(this._self, this._then);

  final ProfileStateLoaded _self;
  final $Res Function(ProfileStateLoaded) _then;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profile = null,}) {
  return _then(ProfileStateLoaded(
null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as DriverProfileModel,
  ));
}

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverProfileModelCopyWith<$Res> get profile {
  
  return $DriverProfileModelCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

/// @nodoc


class ProfileStateError implements ProfileState {
  const ProfileStateError(this.message);
  

 final  String message;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileStateErrorCopyWith<ProfileStateError> get copyWith => _$ProfileStateErrorCopyWithImpl<ProfileStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProfileState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProfileStateErrorCopyWith<$Res> implements $ProfileStateCopyWith<$Res> {
  factory $ProfileStateErrorCopyWith(ProfileStateError value, $Res Function(ProfileStateError) _then) = _$ProfileStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProfileStateErrorCopyWithImpl<$Res>
    implements $ProfileStateErrorCopyWith<$Res> {
  _$ProfileStateErrorCopyWithImpl(this._self, this._then);

  final ProfileStateError _self;
  final $Res Function(ProfileStateError) _then;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProfileStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
