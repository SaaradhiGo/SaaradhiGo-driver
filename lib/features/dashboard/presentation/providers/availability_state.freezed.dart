// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'availability_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AvailabilityState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AvailabilityState()';
}


}

/// @nodoc
class $AvailabilityStateCopyWith<$Res>  {
$AvailabilityStateCopyWith(AvailabilityState _, $Res Function(AvailabilityState) __);
}


/// Adds pattern-matching-related methods to [AvailabilityState].
extension AvailabilityStatePatterns on AvailabilityState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AvailabilityStateOffline value)?  offline,TResult Function( AvailabilityStateGoingOnline value)?  goingOnline,TResult Function( AvailabilityStateOnline value)?  online,TResult Function( AvailabilityStateReconnecting value)?  reconnecting,TResult Function( AvailabilityStateGoingOffline value)?  goingOffline,TResult Function( AvailabilityStateBlocked value)?  blocked,TResult Function( AvailabilityStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AvailabilityStateOffline() when offline != null:
return offline(_that);case AvailabilityStateGoingOnline() when goingOnline != null:
return goingOnline(_that);case AvailabilityStateOnline() when online != null:
return online(_that);case AvailabilityStateReconnecting() when reconnecting != null:
return reconnecting(_that);case AvailabilityStateGoingOffline() when goingOffline != null:
return goingOffline(_that);case AvailabilityStateBlocked() when blocked != null:
return blocked(_that);case AvailabilityStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AvailabilityStateOffline value)  offline,required TResult Function( AvailabilityStateGoingOnline value)  goingOnline,required TResult Function( AvailabilityStateOnline value)  online,required TResult Function( AvailabilityStateReconnecting value)  reconnecting,required TResult Function( AvailabilityStateGoingOffline value)  goingOffline,required TResult Function( AvailabilityStateBlocked value)  blocked,required TResult Function( AvailabilityStateError value)  error,}){
final _that = this;
switch (_that) {
case AvailabilityStateOffline():
return offline(_that);case AvailabilityStateGoingOnline():
return goingOnline(_that);case AvailabilityStateOnline():
return online(_that);case AvailabilityStateReconnecting():
return reconnecting(_that);case AvailabilityStateGoingOffline():
return goingOffline(_that);case AvailabilityStateBlocked():
return blocked(_that);case AvailabilityStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AvailabilityStateOffline value)?  offline,TResult? Function( AvailabilityStateGoingOnline value)?  goingOnline,TResult? Function( AvailabilityStateOnline value)?  online,TResult? Function( AvailabilityStateReconnecting value)?  reconnecting,TResult? Function( AvailabilityStateGoingOffline value)?  goingOffline,TResult? Function( AvailabilityStateBlocked value)?  blocked,TResult? Function( AvailabilityStateError value)?  error,}){
final _that = this;
switch (_that) {
case AvailabilityStateOffline() when offline != null:
return offline(_that);case AvailabilityStateGoingOnline() when goingOnline != null:
return goingOnline(_that);case AvailabilityStateOnline() when online != null:
return online(_that);case AvailabilityStateReconnecting() when reconnecting != null:
return reconnecting(_that);case AvailabilityStateGoingOffline() when goingOffline != null:
return goingOffline(_that);case AvailabilityStateBlocked() when blocked != null:
return blocked(_that);case AvailabilityStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  offline,TResult Function()?  goingOnline,TResult Function( DateTime since)?  online,TResult Function()?  reconnecting,TResult Function()?  goingOffline,TResult Function( AvailabilityBlockReason reason,  String message)?  blocked,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AvailabilityStateOffline() when offline != null:
return offline();case AvailabilityStateGoingOnline() when goingOnline != null:
return goingOnline();case AvailabilityStateOnline() when online != null:
return online(_that.since);case AvailabilityStateReconnecting() when reconnecting != null:
return reconnecting();case AvailabilityStateGoingOffline() when goingOffline != null:
return goingOffline();case AvailabilityStateBlocked() when blocked != null:
return blocked(_that.reason,_that.message);case AvailabilityStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  offline,required TResult Function()  goingOnline,required TResult Function( DateTime since)  online,required TResult Function()  reconnecting,required TResult Function()  goingOffline,required TResult Function( AvailabilityBlockReason reason,  String message)  blocked,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case AvailabilityStateOffline():
return offline();case AvailabilityStateGoingOnline():
return goingOnline();case AvailabilityStateOnline():
return online(_that.since);case AvailabilityStateReconnecting():
return reconnecting();case AvailabilityStateGoingOffline():
return goingOffline();case AvailabilityStateBlocked():
return blocked(_that.reason,_that.message);case AvailabilityStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  offline,TResult? Function()?  goingOnline,TResult? Function( DateTime since)?  online,TResult? Function()?  reconnecting,TResult? Function()?  goingOffline,TResult? Function( AvailabilityBlockReason reason,  String message)?  blocked,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case AvailabilityStateOffline() when offline != null:
return offline();case AvailabilityStateGoingOnline() when goingOnline != null:
return goingOnline();case AvailabilityStateOnline() when online != null:
return online(_that.since);case AvailabilityStateReconnecting() when reconnecting != null:
return reconnecting();case AvailabilityStateGoingOffline() when goingOffline != null:
return goingOffline();case AvailabilityStateBlocked() when blocked != null:
return blocked(_that.reason,_that.message);case AvailabilityStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class AvailabilityStateOffline implements AvailabilityState {
  const AvailabilityStateOffline();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityStateOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AvailabilityState.offline()';
}


}




/// @nodoc


class AvailabilityStateGoingOnline implements AvailabilityState {
  const AvailabilityStateGoingOnline();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityStateGoingOnline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AvailabilityState.goingOnline()';
}


}




/// @nodoc


class AvailabilityStateOnline implements AvailabilityState {
  const AvailabilityStateOnline({required this.since});
  

 final  DateTime since;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilityStateOnlineCopyWith<AvailabilityStateOnline> get copyWith => _$AvailabilityStateOnlineCopyWithImpl<AvailabilityStateOnline>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityStateOnline&&(identical(other.since, since) || other.since == since));
}


@override
int get hashCode => Object.hash(runtimeType,since);

@override
String toString() {
  return 'AvailabilityState.online(since: $since)';
}


}

/// @nodoc
abstract mixin class $AvailabilityStateOnlineCopyWith<$Res> implements $AvailabilityStateCopyWith<$Res> {
  factory $AvailabilityStateOnlineCopyWith(AvailabilityStateOnline value, $Res Function(AvailabilityStateOnline) _then) = _$AvailabilityStateOnlineCopyWithImpl;
@useResult
$Res call({
 DateTime since
});




}
/// @nodoc
class _$AvailabilityStateOnlineCopyWithImpl<$Res>
    implements $AvailabilityStateOnlineCopyWith<$Res> {
  _$AvailabilityStateOnlineCopyWithImpl(this._self, this._then);

  final AvailabilityStateOnline _self;
  final $Res Function(AvailabilityStateOnline) _then;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? since = null,}) {
  return _then(AvailabilityStateOnline(
since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class AvailabilityStateReconnecting implements AvailabilityState {
  const AvailabilityStateReconnecting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityStateReconnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AvailabilityState.reconnecting()';
}


}




/// @nodoc


class AvailabilityStateGoingOffline implements AvailabilityState {
  const AvailabilityStateGoingOffline();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityStateGoingOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AvailabilityState.goingOffline()';
}


}




/// @nodoc


class AvailabilityStateBlocked implements AvailabilityState {
  const AvailabilityStateBlocked({required this.reason, required this.message});
  

 final  AvailabilityBlockReason reason;
 final  String message;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilityStateBlockedCopyWith<AvailabilityStateBlocked> get copyWith => _$AvailabilityStateBlockedCopyWithImpl<AvailabilityStateBlocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityStateBlocked&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,reason,message);

@override
String toString() {
  return 'AvailabilityState.blocked(reason: $reason, message: $message)';
}


}

/// @nodoc
abstract mixin class $AvailabilityStateBlockedCopyWith<$Res> implements $AvailabilityStateCopyWith<$Res> {
  factory $AvailabilityStateBlockedCopyWith(AvailabilityStateBlocked value, $Res Function(AvailabilityStateBlocked) _then) = _$AvailabilityStateBlockedCopyWithImpl;
@useResult
$Res call({
 AvailabilityBlockReason reason, String message
});




}
/// @nodoc
class _$AvailabilityStateBlockedCopyWithImpl<$Res>
    implements $AvailabilityStateBlockedCopyWith<$Res> {
  _$AvailabilityStateBlockedCopyWithImpl(this._self, this._then);

  final AvailabilityStateBlocked _self;
  final $Res Function(AvailabilityStateBlocked) _then;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? message = null,}) {
  return _then(AvailabilityStateBlocked(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as AvailabilityBlockReason,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AvailabilityStateError implements AvailabilityState {
  const AvailabilityStateError(this.message);
  

 final  String message;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilityStateErrorCopyWith<AvailabilityStateError> get copyWith => _$AvailabilityStateErrorCopyWithImpl<AvailabilityStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AvailabilityState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $AvailabilityStateErrorCopyWith<$Res> implements $AvailabilityStateCopyWith<$Res> {
  factory $AvailabilityStateErrorCopyWith(AvailabilityStateError value, $Res Function(AvailabilityStateError) _then) = _$AvailabilityStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AvailabilityStateErrorCopyWithImpl<$Res>
    implements $AvailabilityStateErrorCopyWith<$Res> {
  _$AvailabilityStateErrorCopyWithImpl(this._self, this._then);

  final AvailabilityStateError _self;
  final $Res Function(AvailabilityStateError) _then;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AvailabilityStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
