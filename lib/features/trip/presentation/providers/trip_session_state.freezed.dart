// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TripSessionState {

 TripModel? get trip; TripStatus? get status;/// Socket opening / accept in flight, before `connection_established`.
 bool get connecting;/// A driver action was sent and we are awaiting its broadcast or error.
 bool get actionInProgress;/// OTP-specific rejection, surfaced inline on the OTP field.
 String? get otpError;/// Any other non-fatal error message to show as a banner/snackbar.
 String? get errorMessage;/// Reason why the trip was cancelled (if cancelled by rider or system).
 String? get cancellationReason;/// This offer was won by another driver (`trip_taken`).
 bool get takenByOther;/// The transport exhausted its reconnect budget.
 bool get socketError;/// A cash trip's `confirm_cash` has been acknowledged by the backend.
 bool get cashConfirmed;/// The offer we accepted was gone by the time the backend answered, or
/// never confirmed. The driver is NOT on a trip and should be back on the
/// duty screen. Distinct from `takenByOther` (a known race with another
/// driver) and from `socketError` (transport, trip may still be ours).
 bool get offerLost;/// True when the backend refused the accept for a reason about the
/// DRIVER (a fatigue lockout, a cancellation cooldown) rather than about
/// the ride. The two need different words on screen: "ride no longer
/// available" is actively wrong when the ride is fine and the driver is
/// the one who cannot take it.
 bool get refusedByBackend;
/// Create a copy of TripSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripSessionStateCopyWith<TripSessionState> get copyWith => _$TripSessionStateCopyWithImpl<TripSessionState>(this as TripSessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripSessionState&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.status, status) || other.status == status)&&(identical(other.connecting, connecting) || other.connecting == connecting)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.otpError, otpError) || other.otpError == otpError)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.takenByOther, takenByOther) || other.takenByOther == takenByOther)&&(identical(other.socketError, socketError) || other.socketError == socketError)&&(identical(other.cashConfirmed, cashConfirmed) || other.cashConfirmed == cashConfirmed)&&(identical(other.offerLost, offerLost) || other.offerLost == offerLost)&&(identical(other.refusedByBackend, refusedByBackend) || other.refusedByBackend == refusedByBackend));
}


@override
int get hashCode => Object.hash(runtimeType,trip,status,connecting,actionInProgress,otpError,errorMessage,cancellationReason,takenByOther,socketError,cashConfirmed,offerLost,refusedByBackend);

@override
String toString() {
  return 'TripSessionState(trip: $trip, status: $status, connecting: $connecting, actionInProgress: $actionInProgress, otpError: $otpError, errorMessage: $errorMessage, cancellationReason: $cancellationReason, takenByOther: $takenByOther, socketError: $socketError, cashConfirmed: $cashConfirmed, offerLost: $offerLost, refusedByBackend: $refusedByBackend)';
}


}

/// @nodoc
abstract mixin class $TripSessionStateCopyWith<$Res>  {
  factory $TripSessionStateCopyWith(TripSessionState value, $Res Function(TripSessionState) _then) = _$TripSessionStateCopyWithImpl;
@useResult
$Res call({
 TripModel? trip, TripStatus? status, bool connecting, bool actionInProgress, String? otpError, String? errorMessage, String? cancellationReason, bool takenByOther, bool socketError, bool cashConfirmed, bool offerLost, bool refusedByBackend
});


$TripModelCopyWith<$Res>? get trip;

}
/// @nodoc
class _$TripSessionStateCopyWithImpl<$Res>
    implements $TripSessionStateCopyWith<$Res> {
  _$TripSessionStateCopyWithImpl(this._self, this._then);

  final TripSessionState _self;
  final $Res Function(TripSessionState) _then;

/// Create a copy of TripSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trip = freezed,Object? status = freezed,Object? connecting = null,Object? actionInProgress = null,Object? otpError = freezed,Object? errorMessage = freezed,Object? cancellationReason = freezed,Object? takenByOther = null,Object? socketError = null,Object? cashConfirmed = null,Object? offerLost = null,Object? refusedByBackend = null,}) {
  return _then(TripSessionState(
trip: freezed == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as TripModel?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus?,connecting: null == connecting ? _self.connecting : connecting // ignore: cast_nullable_to_non_nullable
as bool,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,otpError: freezed == otpError ? _self.otpError : otpError // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,takenByOther: null == takenByOther ? _self.takenByOther : takenByOther // ignore: cast_nullable_to_non_nullable
as bool,socketError: null == socketError ? _self.socketError : socketError // ignore: cast_nullable_to_non_nullable
as bool,cashConfirmed: null == cashConfirmed ? _self.cashConfirmed : cashConfirmed // ignore: cast_nullable_to_non_nullable
as bool,offerLost: null == offerLost ? _self.offerLost : offerLost // ignore: cast_nullable_to_non_nullable
as bool,refusedByBackend: null == refusedByBackend ? _self.refusedByBackend : refusedByBackend // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TripSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripModelCopyWith<$Res>? get trip {
    if (_self.trip == null) {
    return null;
  }

  return $TripModelCopyWith<$Res>(_self.trip!, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripSessionState].
extension TripSessionStatePatterns on TripSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripSessionState value)  $default,){
final _that = this;
switch (_that) {
case _TripSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _TripSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TripModel? trip,  TripStatus? status,  bool connecting,  bool actionInProgress,  String? otpError,  String? errorMessage,  String? cancellationReason,  bool takenByOther,  bool socketError,  bool cashConfirmed,  bool offerLost,  bool refusedByBackend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripSessionState() when $default != null:
return $default(_that.trip,_that.status,_that.connecting,_that.actionInProgress,_that.otpError,_that.errorMessage,_that.cancellationReason,_that.takenByOther,_that.socketError,_that.cashConfirmed,_that.offerLost,_that.refusedByBackend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TripModel? trip,  TripStatus? status,  bool connecting,  bool actionInProgress,  String? otpError,  String? errorMessage,  String? cancellationReason,  bool takenByOther,  bool socketError,  bool cashConfirmed,  bool offerLost,  bool refusedByBackend)  $default,) {final _that = this;
switch (_that) {
case _TripSessionState():
return $default(_that.trip,_that.status,_that.connecting,_that.actionInProgress,_that.otpError,_that.errorMessage,_that.cancellationReason,_that.takenByOther,_that.socketError,_that.cashConfirmed,_that.offerLost,_that.refusedByBackend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TripModel? trip,  TripStatus? status,  bool connecting,  bool actionInProgress,  String? otpError,  String? errorMessage,  String? cancellationReason,  bool takenByOther,  bool socketError,  bool cashConfirmed,  bool offerLost,  bool refusedByBackend)?  $default,) {final _that = this;
switch (_that) {
case _TripSessionState() when $default != null:
return $default(_that.trip,_that.status,_that.connecting,_that.actionInProgress,_that.otpError,_that.errorMessage,_that.cancellationReason,_that.takenByOther,_that.socketError,_that.cashConfirmed,_that.offerLost,_that.refusedByBackend);case _:
  return null;

}
}

}

/// @nodoc


class _TripSessionState extends TripSessionState {
  const _TripSessionState({this.trip, this.status, this.connecting = false, this.actionInProgress = false, this.otpError, this.errorMessage, this.cancellationReason, this.takenByOther = false, this.socketError = false, this.cashConfirmed = false, this.offerLost = false, this.refusedByBackend = false}): super._();
  

@override final  TripModel? trip;
@override final  TripStatus? status;
/// Socket opening / accept in flight, before `connection_established`.
@override@JsonKey() final  bool connecting;
/// A driver action was sent and we are awaiting its broadcast or error.
@override@JsonKey() final  bool actionInProgress;
/// OTP-specific rejection, surfaced inline on the OTP field.
@override final  String? otpError;
/// Any other non-fatal error message to show as a banner/snackbar.
@override final  String? errorMessage;
/// Reason why the trip was cancelled (if cancelled by rider or system).
@override final  String? cancellationReason;
/// This offer was won by another driver (`trip_taken`).
@override@JsonKey() final  bool takenByOther;
/// The transport exhausted its reconnect budget.
@override@JsonKey() final  bool socketError;
/// A cash trip's `confirm_cash` has been acknowledged by the backend.
@override@JsonKey() final  bool cashConfirmed;
/// The offer we accepted was gone by the time the backend answered, or
/// never confirmed. The driver is NOT on a trip and should be back on the
/// duty screen. Distinct from `takenByOther` (a known race with another
/// driver) and from `socketError` (transport, trip may still be ours).
@override@JsonKey() final  bool offerLost;
/// True when the backend refused the accept for a reason about the
/// DRIVER (a fatigue lockout, a cancellation cooldown) rather than about
/// the ride. The two need different words on screen: "ride no longer
/// available" is actively wrong when the ride is fine and the driver is
/// the one who cannot take it.
@override@JsonKey() final  bool refusedByBackend;

/// Create a copy of TripSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripSessionStateCopyWith<_TripSessionState> get copyWith => __$TripSessionStateCopyWithImpl<_TripSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripSessionState&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.status, status) || other.status == status)&&(identical(other.connecting, connecting) || other.connecting == connecting)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.otpError, otpError) || other.otpError == otpError)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.takenByOther, takenByOther) || other.takenByOther == takenByOther)&&(identical(other.socketError, socketError) || other.socketError == socketError)&&(identical(other.cashConfirmed, cashConfirmed) || other.cashConfirmed == cashConfirmed)&&(identical(other.offerLost, offerLost) || other.offerLost == offerLost)&&(identical(other.refusedByBackend, refusedByBackend) || other.refusedByBackend == refusedByBackend));
}


@override
int get hashCode => Object.hash(runtimeType,trip,status,connecting,actionInProgress,otpError,errorMessage,cancellationReason,takenByOther,socketError,cashConfirmed,offerLost,refusedByBackend);

@override
String toString() {
  return 'TripSessionState(trip: $trip, status: $status, connecting: $connecting, actionInProgress: $actionInProgress, otpError: $otpError, errorMessage: $errorMessage, cancellationReason: $cancellationReason, takenByOther: $takenByOther, socketError: $socketError, cashConfirmed: $cashConfirmed, offerLost: $offerLost, refusedByBackend: $refusedByBackend)';
}


}

/// @nodoc
abstract mixin class _$TripSessionStateCopyWith<$Res> implements $TripSessionStateCopyWith<$Res> {
  factory _$TripSessionStateCopyWith(_TripSessionState value, $Res Function(_TripSessionState) _then) = __$TripSessionStateCopyWithImpl;
@override @useResult
$Res call({
 TripModel? trip, TripStatus? status, bool connecting, bool actionInProgress, String? otpError, String? errorMessage, String? cancellationReason, bool takenByOther, bool socketError, bool cashConfirmed, bool offerLost, bool refusedByBackend
});


@override $TripModelCopyWith<$Res>? get trip;

}
/// @nodoc
class __$TripSessionStateCopyWithImpl<$Res>
    implements _$TripSessionStateCopyWith<$Res> {
  __$TripSessionStateCopyWithImpl(this._self, this._then);

  final _TripSessionState _self;
  final $Res Function(_TripSessionState) _then;

/// Create a copy of TripSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trip = freezed,Object? status = freezed,Object? connecting = null,Object? actionInProgress = null,Object? otpError = freezed,Object? errorMessage = freezed,Object? cancellationReason = freezed,Object? takenByOther = null,Object? socketError = null,Object? cashConfirmed = null,Object? offerLost = null,Object? refusedByBackend = null,}) {
  return _then(_TripSessionState(
trip: freezed == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as TripModel?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus?,connecting: null == connecting ? _self.connecting : connecting // ignore: cast_nullable_to_non_nullable
as bool,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,otpError: freezed == otpError ? _self.otpError : otpError // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,takenByOther: null == takenByOther ? _self.takenByOther : takenByOther // ignore: cast_nullable_to_non_nullable
as bool,socketError: null == socketError ? _self.socketError : socketError // ignore: cast_nullable_to_non_nullable
as bool,cashConfirmed: null == cashConfirmed ? _self.cashConfirmed : cashConfirmed // ignore: cast_nullable_to_non_nullable
as bool,offerLost: null == offerLost ? _self.offerLost : offerLost // ignore: cast_nullable_to_non_nullable
as bool,refusedByBackend: null == refusedByBackend ? _self.refusedByBackend : refusedByBackend // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TripSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripModelCopyWith<$Res>? get trip {
    if (_self.trip == null) {
    return null;
  }

  return $TripModelCopyWith<$Res>(_self.trip!, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}

// dart format on
