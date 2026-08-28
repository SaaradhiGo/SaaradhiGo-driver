// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState()';
}


}

/// @nodoc
class $OnboardingStateCopyWith<$Res>  {
$OnboardingStateCopyWith(OnboardingState _, $Res Function(OnboardingState) __);
}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OnboardingStateInitial value)?  initial,TResult Function( OnboardingStateLoading value)?  loading,TResult Function( OnboardingStateUploading value)?  uploading,TResult Function( OnboardingStateSuccess value)?  success,TResult Function( OnboardingStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OnboardingStateInitial() when initial != null:
return initial(_that);case OnboardingStateLoading() when loading != null:
return loading(_that);case OnboardingStateUploading() when uploading != null:
return uploading(_that);case OnboardingStateSuccess() when success != null:
return success(_that);case OnboardingStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OnboardingStateInitial value)  initial,required TResult Function( OnboardingStateLoading value)  loading,required TResult Function( OnboardingStateUploading value)  uploading,required TResult Function( OnboardingStateSuccess value)  success,required TResult Function( OnboardingStateError value)  error,}){
final _that = this;
switch (_that) {
case OnboardingStateInitial():
return initial(_that);case OnboardingStateLoading():
return loading(_that);case OnboardingStateUploading():
return uploading(_that);case OnboardingStateSuccess():
return success(_that);case OnboardingStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OnboardingStateInitial value)?  initial,TResult? Function( OnboardingStateLoading value)?  loading,TResult? Function( OnboardingStateUploading value)?  uploading,TResult? Function( OnboardingStateSuccess value)?  success,TResult? Function( OnboardingStateError value)?  error,}){
final _that = this;
switch (_that) {
case OnboardingStateInitial() when initial != null:
return initial(_that);case OnboardingStateLoading() when loading != null:
return loading(_that);case OnboardingStateUploading() when uploading != null:
return uploading(_that);case OnboardingStateSuccess() when success != null:
return success(_that);case OnboardingStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( double progress,  String label)?  uploading,TResult Function()?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OnboardingStateInitial() when initial != null:
return initial();case OnboardingStateLoading() when loading != null:
return loading();case OnboardingStateUploading() when uploading != null:
return uploading(_that.progress,_that.label);case OnboardingStateSuccess() when success != null:
return success();case OnboardingStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( double progress,  String label)  uploading,required TResult Function()  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case OnboardingStateInitial():
return initial();case OnboardingStateLoading():
return loading();case OnboardingStateUploading():
return uploading(_that.progress,_that.label);case OnboardingStateSuccess():
return success();case OnboardingStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( double progress,  String label)?  uploading,TResult? Function()?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case OnboardingStateInitial() when initial != null:
return initial();case OnboardingStateLoading() when loading != null:
return loading();case OnboardingStateUploading() when uploading != null:
return uploading(_that.progress,_that.label);case OnboardingStateSuccess() when success != null:
return success();case OnboardingStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class OnboardingStateInitial implements OnboardingState {
  const OnboardingStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.initial()';
}


}




/// @nodoc


class OnboardingStateLoading implements OnboardingState {
  const OnboardingStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.loading()';
}


}




/// @nodoc


class OnboardingStateUploading implements OnboardingState {
  const OnboardingStateUploading({required this.progress, required this.label});
  

 final  double progress;
 final  String label;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateUploadingCopyWith<OnboardingStateUploading> get copyWith => _$OnboardingStateUploadingCopyWithImpl<OnboardingStateUploading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingStateUploading&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,progress,label);

@override
String toString() {
  return 'OnboardingState.uploading(progress: $progress, label: $label)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateUploadingCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory $OnboardingStateUploadingCopyWith(OnboardingStateUploading value, $Res Function(OnboardingStateUploading) _then) = _$OnboardingStateUploadingCopyWithImpl;
@useResult
$Res call({
 double progress, String label
});




}
/// @nodoc
class _$OnboardingStateUploadingCopyWithImpl<$Res>
    implements $OnboardingStateUploadingCopyWith<$Res> {
  _$OnboardingStateUploadingCopyWithImpl(this._self, this._then);

  final OnboardingStateUploading _self;
  final $Res Function(OnboardingStateUploading) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? progress = null,Object? label = null,}) {
  return _then(OnboardingStateUploading(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OnboardingStateSuccess implements OnboardingState {
  const OnboardingStateSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingStateSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.success()';
}


}




/// @nodoc


class OnboardingStateError implements OnboardingState {
  const OnboardingStateError(this.message);
  

 final  String message;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateErrorCopyWith<OnboardingStateError> get copyWith => _$OnboardingStateErrorCopyWithImpl<OnboardingStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'OnboardingState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateErrorCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory $OnboardingStateErrorCopyWith(OnboardingStateError value, $Res Function(OnboardingStateError) _then) = _$OnboardingStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$OnboardingStateErrorCopyWithImpl<$Res>
    implements $OnboardingStateErrorCopyWith<$Res> {
  _$OnboardingStateErrorCopyWithImpl(this._self, this._then);

  final OnboardingStateError _self;
  final $Res Function(OnboardingStateError) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(OnboardingStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
