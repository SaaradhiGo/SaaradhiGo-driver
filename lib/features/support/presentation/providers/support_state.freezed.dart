// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SupportTicketsState {

 List<SupportTicketModel> get tickets;/// First load in flight (full-screen spinner).
 bool get isLoading;/// Pull-to-refresh in flight.
 bool get isRefreshing;/// Creating an incident/ticket in flight.
 bool get isSubmitting; String? get errorMessage;/// Set when [submitTicket] succeeds so the UI can navigate to the detail.
 int? get createdTicketId;
/// Create a copy of SupportTicketsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketsStateCopyWith<SupportTicketsState> get copyWith => _$SupportTicketsStateCopyWithImpl<SupportTicketsState>(this as SupportTicketsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicketsState&&const DeepCollectionEquality().equals(other.tickets, tickets)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdTicketId, createdTicketId) || other.createdTicketId == createdTicketId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tickets),isLoading,isRefreshing,isSubmitting,errorMessage,createdTicketId);

@override
String toString() {
  return 'SupportTicketsState(tickets: $tickets, isLoading: $isLoading, isRefreshing: $isRefreshing, isSubmitting: $isSubmitting, errorMessage: $errorMessage, createdTicketId: $createdTicketId)';
}


}

/// @nodoc
abstract mixin class $SupportTicketsStateCopyWith<$Res>  {
  factory $SupportTicketsStateCopyWith(SupportTicketsState value, $Res Function(SupportTicketsState) _then) = _$SupportTicketsStateCopyWithImpl;
@useResult
$Res call({
 List<SupportTicketModel> tickets, bool isLoading, bool isRefreshing, bool isSubmitting, String? errorMessage, int? createdTicketId
});




}
/// @nodoc
class _$SupportTicketsStateCopyWithImpl<$Res>
    implements $SupportTicketsStateCopyWith<$Res> {
  _$SupportTicketsStateCopyWithImpl(this._self, this._then);

  final SupportTicketsState _self;
  final $Res Function(SupportTicketsState) _then;

/// Create a copy of SupportTicketsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tickets = null,Object? isLoading = null,Object? isRefreshing = null,Object? isSubmitting = null,Object? errorMessage = freezed,Object? createdTicketId = freezed,}) {
  return _then(SupportTicketsState(
tickets: null == tickets ? _self.tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<SupportTicketModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdTicketId: freezed == createdTicketId ? _self.createdTicketId : createdTicketId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportTicketsState].
extension SupportTicketsStatePatterns on SupportTicketsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicketsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicketsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicketsState value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicketsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicketsState value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicketsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SupportTicketModel> tickets,  bool isLoading,  bool isRefreshing,  bool isSubmitting,  String? errorMessage,  int? createdTicketId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicketsState() when $default != null:
return $default(_that.tickets,_that.isLoading,_that.isRefreshing,_that.isSubmitting,_that.errorMessage,_that.createdTicketId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SupportTicketModel> tickets,  bool isLoading,  bool isRefreshing,  bool isSubmitting,  String? errorMessage,  int? createdTicketId)  $default,) {final _that = this;
switch (_that) {
case _SupportTicketsState():
return $default(_that.tickets,_that.isLoading,_that.isRefreshing,_that.isSubmitting,_that.errorMessage,_that.createdTicketId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SupportTicketModel> tickets,  bool isLoading,  bool isRefreshing,  bool isSubmitting,  String? errorMessage,  int? createdTicketId)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicketsState() when $default != null:
return $default(_that.tickets,_that.isLoading,_that.isRefreshing,_that.isSubmitting,_that.errorMessage,_that.createdTicketId);case _:
  return null;

}
}

}

/// @nodoc


class _SupportTicketsState extends SupportTicketsState {
  const _SupportTicketsState({ List<SupportTicketModel> tickets = const [], this.isLoading = false, this.isRefreshing = false, this.isSubmitting = false, this.errorMessage, this.createdTicketId}): _tickets = tickets,super._();
  

 final  List<SupportTicketModel> _tickets;
@override@JsonKey() List<SupportTicketModel> get tickets {
  if (_tickets is EqualUnmodifiableListView) return _tickets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tickets);
}

/// First load in flight (full-screen spinner).
@override@JsonKey() final  bool isLoading;
/// Pull-to-refresh in flight.
@override@JsonKey() final  bool isRefreshing;
/// Creating an incident/ticket in flight.
@override@JsonKey() final  bool isSubmitting;
@override final  String? errorMessage;
/// Set when [submitTicket] succeeds so the UI can navigate to the detail.
@override final  int? createdTicketId;

/// Create a copy of SupportTicketsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketsStateCopyWith<_SupportTicketsState> get copyWith => __$SupportTicketsStateCopyWithImpl<_SupportTicketsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicketsState&&const DeepCollectionEquality().equals(other._tickets, _tickets)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdTicketId, createdTicketId) || other.createdTicketId == createdTicketId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tickets),isLoading,isRefreshing,isSubmitting,errorMessage,createdTicketId);

@override
String toString() {
  return 'SupportTicketsState(tickets: $tickets, isLoading: $isLoading, isRefreshing: $isRefreshing, isSubmitting: $isSubmitting, errorMessage: $errorMessage, createdTicketId: $createdTicketId)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketsStateCopyWith<$Res> implements $SupportTicketsStateCopyWith<$Res> {
  factory _$SupportTicketsStateCopyWith(_SupportTicketsState value, $Res Function(_SupportTicketsState) _then) = __$SupportTicketsStateCopyWithImpl;
@override @useResult
$Res call({
 List<SupportTicketModel> tickets, bool isLoading, bool isRefreshing, bool isSubmitting, String? errorMessage, int? createdTicketId
});




}
/// @nodoc
class __$SupportTicketsStateCopyWithImpl<$Res>
    implements _$SupportTicketsStateCopyWith<$Res> {
  __$SupportTicketsStateCopyWithImpl(this._self, this._then);

  final _SupportTicketsState _self;
  final $Res Function(_SupportTicketsState) _then;

/// Create a copy of SupportTicketsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tickets = null,Object? isLoading = null,Object? isRefreshing = null,Object? isSubmitting = null,Object? errorMessage = freezed,Object? createdTicketId = freezed,}) {
  return _then(_SupportTicketsState(
tickets: null == tickets ? _self._tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<SupportTicketModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdTicketId: freezed == createdTicketId ? _self.createdTicketId : createdTicketId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$SupportTicketDetailState {

 SupportTicketModel? get ticket;/// First load in flight.
 bool get isLoading;/// Replying to the thread in flight.
 bool get isSendingReply;/// Closing the ticket in flight.
 bool get isClosing; String? get errorMessage;
/// Create a copy of SupportTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketDetailStateCopyWith<SupportTicketDetailState> get copyWith => _$SupportTicketDetailStateCopyWithImpl<SupportTicketDetailState>(this as SupportTicketDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicketDetailState&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSendingReply, isSendingReply) || other.isSendingReply == isSendingReply)&&(identical(other.isClosing, isClosing) || other.isClosing == isClosing)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,ticket,isLoading,isSendingReply,isClosing,errorMessage);

@override
String toString() {
  return 'SupportTicketDetailState(ticket: $ticket, isLoading: $isLoading, isSendingReply: $isSendingReply, isClosing: $isClosing, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SupportTicketDetailStateCopyWith<$Res>  {
  factory $SupportTicketDetailStateCopyWith(SupportTicketDetailState value, $Res Function(SupportTicketDetailState) _then) = _$SupportTicketDetailStateCopyWithImpl;
@useResult
$Res call({
 SupportTicketModel? ticket, bool isLoading, bool isSendingReply, bool isClosing, String? errorMessage
});


$SupportTicketModelCopyWith<$Res>? get ticket;

}
/// @nodoc
class _$SupportTicketDetailStateCopyWithImpl<$Res>
    implements $SupportTicketDetailStateCopyWith<$Res> {
  _$SupportTicketDetailStateCopyWithImpl(this._self, this._then);

  final SupportTicketDetailState _self;
  final $Res Function(SupportTicketDetailState) _then;

/// Create a copy of SupportTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticket = freezed,Object? isLoading = null,Object? isSendingReply = null,Object? isClosing = null,Object? errorMessage = freezed,}) {
  return _then(SupportTicketDetailState(
ticket: freezed == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as SupportTicketModel?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSendingReply: null == isSendingReply ? _self.isSendingReply : isSendingReply // ignore: cast_nullable_to_non_nullable
as bool,isClosing: null == isClosing ? _self.isClosing : isClosing // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SupportTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportTicketModelCopyWith<$Res>? get ticket {
    if (_self.ticket == null) {
    return null;
  }

  return $SupportTicketModelCopyWith<$Res>(_self.ticket!, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportTicketDetailState].
extension SupportTicketDetailStatePatterns on SupportTicketDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicketDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicketDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicketDetailState value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicketDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicketDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicketDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SupportTicketModel? ticket,  bool isLoading,  bool isSendingReply,  bool isClosing,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicketDetailState() when $default != null:
return $default(_that.ticket,_that.isLoading,_that.isSendingReply,_that.isClosing,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SupportTicketModel? ticket,  bool isLoading,  bool isSendingReply,  bool isClosing,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SupportTicketDetailState():
return $default(_that.ticket,_that.isLoading,_that.isSendingReply,_that.isClosing,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SupportTicketModel? ticket,  bool isLoading,  bool isSendingReply,  bool isClosing,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicketDetailState() when $default != null:
return $default(_that.ticket,_that.isLoading,_that.isSendingReply,_that.isClosing,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SupportTicketDetailState extends SupportTicketDetailState {
  const _SupportTicketDetailState({this.ticket, this.isLoading = false, this.isSendingReply = false, this.isClosing = false, this.errorMessage}): super._();
  

@override final  SupportTicketModel? ticket;
/// First load in flight.
@override@JsonKey() final  bool isLoading;
/// Replying to the thread in flight.
@override@JsonKey() final  bool isSendingReply;
/// Closing the ticket in flight.
@override@JsonKey() final  bool isClosing;
@override final  String? errorMessage;

/// Create a copy of SupportTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketDetailStateCopyWith<_SupportTicketDetailState> get copyWith => __$SupportTicketDetailStateCopyWithImpl<_SupportTicketDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicketDetailState&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSendingReply, isSendingReply) || other.isSendingReply == isSendingReply)&&(identical(other.isClosing, isClosing) || other.isClosing == isClosing)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,ticket,isLoading,isSendingReply,isClosing,errorMessage);

@override
String toString() {
  return 'SupportTicketDetailState(ticket: $ticket, isLoading: $isLoading, isSendingReply: $isSendingReply, isClosing: $isClosing, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketDetailStateCopyWith<$Res> implements $SupportTicketDetailStateCopyWith<$Res> {
  factory _$SupportTicketDetailStateCopyWith(_SupportTicketDetailState value, $Res Function(_SupportTicketDetailState) _then) = __$SupportTicketDetailStateCopyWithImpl;
@override @useResult
$Res call({
 SupportTicketModel? ticket, bool isLoading, bool isSendingReply, bool isClosing, String? errorMessage
});


@override $SupportTicketModelCopyWith<$Res>? get ticket;

}
/// @nodoc
class __$SupportTicketDetailStateCopyWithImpl<$Res>
    implements _$SupportTicketDetailStateCopyWith<$Res> {
  __$SupportTicketDetailStateCopyWithImpl(this._self, this._then);

  final _SupportTicketDetailState _self;
  final $Res Function(_SupportTicketDetailState) _then;

/// Create a copy of SupportTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticket = freezed,Object? isLoading = null,Object? isSendingReply = null,Object? isClosing = null,Object? errorMessage = freezed,}) {
  return _then(_SupportTicketDetailState(
ticket: freezed == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as SupportTicketModel?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSendingReply: null == isSendingReply ? _self.isSendingReply : isSendingReply // ignore: cast_nullable_to_non_nullable
as bool,isClosing: null == isClosing ? _self.isClosing : isClosing // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SupportTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportTicketModelCopyWith<$Res>? get ticket {
    if (_self.ticket == null) {
    return null;
  }

  return $SupportTicketModelCopyWith<$Res>(_self.ticket!, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}

/// @nodoc
mixin _$SosState {

/// Raising the SOS alert in flight.
 bool get isRaising;/// The last successful alert, shown as a confirmation.
 String? get confirmationMessage;/// Saving the emergency contact in flight.
 bool get isSavingContact; String? get errorMessage;/// Success feedback after saving the emergency contact.
 String? get contactSavedMessage;
/// Create a copy of SosState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosStateCopyWith<SosState> get copyWith => _$SosStateCopyWithImpl<SosState>(this as SosState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosState&&(identical(other.isRaising, isRaising) || other.isRaising == isRaising)&&(identical(other.confirmationMessage, confirmationMessage) || other.confirmationMessage == confirmationMessage)&&(identical(other.isSavingContact, isSavingContact) || other.isSavingContact == isSavingContact)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.contactSavedMessage, contactSavedMessage) || other.contactSavedMessage == contactSavedMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isRaising,confirmationMessage,isSavingContact,errorMessage,contactSavedMessage);

@override
String toString() {
  return 'SosState(isRaising: $isRaising, confirmationMessage: $confirmationMessage, isSavingContact: $isSavingContact, errorMessage: $errorMessage, contactSavedMessage: $contactSavedMessage)';
}


}

/// @nodoc
abstract mixin class $SosStateCopyWith<$Res>  {
  factory $SosStateCopyWith(SosState value, $Res Function(SosState) _then) = _$SosStateCopyWithImpl;
@useResult
$Res call({
 bool isRaising, String? confirmationMessage, bool isSavingContact, String? errorMessage, String? contactSavedMessage
});




}
/// @nodoc
class _$SosStateCopyWithImpl<$Res>
    implements $SosStateCopyWith<$Res> {
  _$SosStateCopyWithImpl(this._self, this._then);

  final SosState _self;
  final $Res Function(SosState) _then;

/// Create a copy of SosState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRaising = null,Object? confirmationMessage = freezed,Object? isSavingContact = null,Object? errorMessage = freezed,Object? contactSavedMessage = freezed,}) {
  return _then(SosState(
isRaising: null == isRaising ? _self.isRaising : isRaising // ignore: cast_nullable_to_non_nullable
as bool,confirmationMessage: freezed == confirmationMessage ? _self.confirmationMessage : confirmationMessage // ignore: cast_nullable_to_non_nullable
as String?,isSavingContact: null == isSavingContact ? _self.isSavingContact : isSavingContact // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,contactSavedMessage: freezed == contactSavedMessage ? _self.contactSavedMessage : contactSavedMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SosState].
extension SosStatePatterns on SosState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosState value)  $default,){
final _that = this;
switch (_that) {
case _SosState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosState value)?  $default,){
final _that = this;
switch (_that) {
case _SosState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRaising,  String? confirmationMessage,  bool isSavingContact,  String? errorMessage,  String? contactSavedMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosState() when $default != null:
return $default(_that.isRaising,_that.confirmationMessage,_that.isSavingContact,_that.errorMessage,_that.contactSavedMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRaising,  String? confirmationMessage,  bool isSavingContact,  String? errorMessage,  String? contactSavedMessage)  $default,) {final _that = this;
switch (_that) {
case _SosState():
return $default(_that.isRaising,_that.confirmationMessage,_that.isSavingContact,_that.errorMessage,_that.contactSavedMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRaising,  String? confirmationMessage,  bool isSavingContact,  String? errorMessage,  String? contactSavedMessage)?  $default,) {final _that = this;
switch (_that) {
case _SosState() when $default != null:
return $default(_that.isRaising,_that.confirmationMessage,_that.isSavingContact,_that.errorMessage,_that.contactSavedMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SosState extends SosState {
  const _SosState({this.isRaising = false, this.confirmationMessage, this.isSavingContact = false, this.errorMessage, this.contactSavedMessage}): super._();
  

/// Raising the SOS alert in flight.
@override@JsonKey() final  bool isRaising;
/// The last successful alert, shown as a confirmation.
@override final  String? confirmationMessage;
/// Saving the emergency contact in flight.
@override@JsonKey() final  bool isSavingContact;
@override final  String? errorMessage;
/// Success feedback after saving the emergency contact.
@override final  String? contactSavedMessage;

/// Create a copy of SosState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosStateCopyWith<_SosState> get copyWith => __$SosStateCopyWithImpl<_SosState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosState&&(identical(other.isRaising, isRaising) || other.isRaising == isRaising)&&(identical(other.confirmationMessage, confirmationMessage) || other.confirmationMessage == confirmationMessage)&&(identical(other.isSavingContact, isSavingContact) || other.isSavingContact == isSavingContact)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.contactSavedMessage, contactSavedMessage) || other.contactSavedMessage == contactSavedMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isRaising,confirmationMessage,isSavingContact,errorMessage,contactSavedMessage);

@override
String toString() {
  return 'SosState(isRaising: $isRaising, confirmationMessage: $confirmationMessage, isSavingContact: $isSavingContact, errorMessage: $errorMessage, contactSavedMessage: $contactSavedMessage)';
}


}

/// @nodoc
abstract mixin class _$SosStateCopyWith<$Res> implements $SosStateCopyWith<$Res> {
  factory _$SosStateCopyWith(_SosState value, $Res Function(_SosState) _then) = __$SosStateCopyWithImpl;
@override @useResult
$Res call({
 bool isRaising, String? confirmationMessage, bool isSavingContact, String? errorMessage, String? contactSavedMessage
});




}
/// @nodoc
class __$SosStateCopyWithImpl<$Res>
    implements _$SosStateCopyWith<$Res> {
  __$SosStateCopyWithImpl(this._self, this._then);

  final _SosState _self;
  final $Res Function(_SosState) _then;

/// Create a copy of SosState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRaising = null,Object? confirmationMessage = freezed,Object? isSavingContact = null,Object? errorMessage = freezed,Object? contactSavedMessage = freezed,}) {
  return _then(_SosState(
isRaising: null == isRaising ? _self.isRaising : isRaising // ignore: cast_nullable_to_non_nullable
as bool,confirmationMessage: freezed == confirmationMessage ? _self.confirmationMessage : confirmationMessage // ignore: cast_nullable_to_non_nullable
as String?,isSavingContact: null == isSavingContact ? _self.isSavingContact : isSavingContact // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,contactSavedMessage: freezed == contactSavedMessage ? _self.contactSavedMessage : contactSavedMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
