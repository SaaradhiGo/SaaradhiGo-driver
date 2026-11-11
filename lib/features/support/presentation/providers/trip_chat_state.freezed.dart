// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TripChatState {

 List<ChatMessageModel> get messages;/// Socket opening in flight, before `connection_established`.
 bool get connecting;/// Chat history REST load in flight.
 bool get isLoadingHistory;/// The transport exhausted its reconnect budget.
 bool get socketError;/// Outbound send in flight (the backend does not echo driver sends).
 bool get sending;/// Recoverable banner/snackbar error (e.g. `{type:error}` frame).
 String? get errorMessage;
/// Create a copy of TripChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripChatStateCopyWith<TripChatState> get copyWith => _$TripChatStateCopyWithImpl<TripChatState>(this as TripChatState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripChatState&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.connecting, connecting) || other.connecting == connecting)&&(identical(other.isLoadingHistory, isLoadingHistory) || other.isLoadingHistory == isLoadingHistory)&&(identical(other.socketError, socketError) || other.socketError == socketError)&&(identical(other.sending, sending) || other.sending == sending)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(messages),connecting,isLoadingHistory,socketError,sending,errorMessage);

@override
String toString() {
  return 'TripChatState(messages: $messages, connecting: $connecting, isLoadingHistory: $isLoadingHistory, socketError: $socketError, sending: $sending, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $TripChatStateCopyWith<$Res>  {
  factory $TripChatStateCopyWith(TripChatState value, $Res Function(TripChatState) _then) = _$TripChatStateCopyWithImpl;
@useResult
$Res call({
 List<ChatMessageModel> messages, bool connecting, bool isLoadingHistory, bool socketError, bool sending, String? errorMessage
});




}
/// @nodoc
class _$TripChatStateCopyWithImpl<$Res>
    implements $TripChatStateCopyWith<$Res> {
  _$TripChatStateCopyWithImpl(this._self, this._then);

  final TripChatState _self;
  final $Res Function(TripChatState) _then;

/// Create a copy of TripChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? connecting = null,Object? isLoadingHistory = null,Object? socketError = null,Object? sending = null,Object? errorMessage = freezed,}) {
  return _then(TripChatState(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessageModel>,connecting: null == connecting ? _self.connecting : connecting // ignore: cast_nullable_to_non_nullable
as bool,isLoadingHistory: null == isLoadingHistory ? _self.isLoadingHistory : isLoadingHistory // ignore: cast_nullable_to_non_nullable
as bool,socketError: null == socketError ? _self.socketError : socketError // ignore: cast_nullable_to_non_nullable
as bool,sending: null == sending ? _self.sending : sending // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripChatState].
extension TripChatStatePatterns on TripChatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripChatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripChatState value)  $default,){
final _that = this;
switch (_that) {
case _TripChatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripChatState value)?  $default,){
final _that = this;
switch (_that) {
case _TripChatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChatMessageModel> messages,  bool connecting,  bool isLoadingHistory,  bool socketError,  bool sending,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripChatState() when $default != null:
return $default(_that.messages,_that.connecting,_that.isLoadingHistory,_that.socketError,_that.sending,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChatMessageModel> messages,  bool connecting,  bool isLoadingHistory,  bool socketError,  bool sending,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _TripChatState():
return $default(_that.messages,_that.connecting,_that.isLoadingHistory,_that.socketError,_that.sending,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChatMessageModel> messages,  bool connecting,  bool isLoadingHistory,  bool socketError,  bool sending,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _TripChatState() when $default != null:
return $default(_that.messages,_that.connecting,_that.isLoadingHistory,_that.socketError,_that.sending,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _TripChatState extends TripChatState {
  const _TripChatState({ List<ChatMessageModel> messages = const [], this.connecting = false, this.isLoadingHistory = false, this.socketError = false, this.sending = false, this.errorMessage}): _messages = messages,super._();
  

 final  List<ChatMessageModel> _messages;
@override@JsonKey() List<ChatMessageModel> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// Socket opening in flight, before `connection_established`.
@override@JsonKey() final  bool connecting;
/// Chat history REST load in flight.
@override@JsonKey() final  bool isLoadingHistory;
/// The transport exhausted its reconnect budget.
@override@JsonKey() final  bool socketError;
/// Outbound send in flight (the backend does not echo driver sends).
@override@JsonKey() final  bool sending;
/// Recoverable banner/snackbar error (e.g. `{type:error}` frame).
@override final  String? errorMessage;

/// Create a copy of TripChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripChatStateCopyWith<_TripChatState> get copyWith => __$TripChatStateCopyWithImpl<_TripChatState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripChatState&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.connecting, connecting) || other.connecting == connecting)&&(identical(other.isLoadingHistory, isLoadingHistory) || other.isLoadingHistory == isLoadingHistory)&&(identical(other.socketError, socketError) || other.socketError == socketError)&&(identical(other.sending, sending) || other.sending == sending)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),connecting,isLoadingHistory,socketError,sending,errorMessage);

@override
String toString() {
  return 'TripChatState(messages: $messages, connecting: $connecting, isLoadingHistory: $isLoadingHistory, socketError: $socketError, sending: $sending, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$TripChatStateCopyWith<$Res> implements $TripChatStateCopyWith<$Res> {
  factory _$TripChatStateCopyWith(_TripChatState value, $Res Function(_TripChatState) _then) = __$TripChatStateCopyWithImpl;
@override @useResult
$Res call({
 List<ChatMessageModel> messages, bool connecting, bool isLoadingHistory, bool socketError, bool sending, String? errorMessage
});




}
/// @nodoc
class __$TripChatStateCopyWithImpl<$Res>
    implements _$TripChatStateCopyWith<$Res> {
  __$TripChatStateCopyWithImpl(this._self, this._then);

  final _TripChatState _self;
  final $Res Function(_TripChatState) _then;

/// Create a copy of TripChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? connecting = null,Object? isLoadingHistory = null,Object? socketError = null,Object? sending = null,Object? errorMessage = freezed,}) {
  return _then(_TripChatState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessageModel>,connecting: null == connecting ? _self.connecting : connecting // ignore: cast_nullable_to_non_nullable
as bool,isLoadingHistory: null == isLoadingHistory ? _self.isLoadingHistory : isLoadingHistory // ignore: cast_nullable_to_non_nullable
as bool,socketError: null == socketError ? _self.socketError : socketError // ignore: cast_nullable_to_non_nullable
as bool,sending: null == sending ? _self.sending : sending // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
