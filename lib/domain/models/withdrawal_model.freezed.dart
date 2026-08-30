// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalModel {

 int get id; String get amount; String get status;@JsonKey(name: 'requested_at') String? get requestedAt;
/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalModelCopyWith<WithdrawalModel> get copyWith => _$WithdrawalModelCopyWithImpl<WithdrawalModel>(this as WithdrawalModel, _$identity);

  /// Serializes this WithdrawalModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,status,requestedAt);

@override
String toString() {
  return 'WithdrawalModel(id: $id, amount: $amount, status: $status, requestedAt: $requestedAt)';
}


}

/// @nodoc
abstract mixin class $WithdrawalModelCopyWith<$Res>  {
  factory $WithdrawalModelCopyWith(WithdrawalModel value, $Res Function(WithdrawalModel) _then) = _$WithdrawalModelCopyWithImpl;
@useResult
$Res call({
 int id, String amount, String status,@JsonKey(name: 'requested_at') String? requestedAt
});




}
/// @nodoc
class _$WithdrawalModelCopyWithImpl<$Res>
    implements $WithdrawalModelCopyWith<$Res> {
  _$WithdrawalModelCopyWithImpl(this._self, this._then);

  final WithdrawalModel _self;
  final $Res Function(WithdrawalModel) _then;

/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? status = null,Object? requestedAt = freezed,}) {
  return _then(WithdrawalModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalModel].
extension WithdrawalModelPatterns on WithdrawalModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalModel value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalModel value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String amount,  String status, @JsonKey(name: 'requested_at')  String? requestedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
return $default(_that.id,_that.amount,_that.status,_that.requestedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String amount,  String status, @JsonKey(name: 'requested_at')  String? requestedAt)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalModel():
return $default(_that.id,_that.amount,_that.status,_that.requestedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String amount,  String status, @JsonKey(name: 'requested_at')  String? requestedAt)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
return $default(_that.id,_that.amount,_that.status,_that.requestedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalModel implements WithdrawalModel {
  const _WithdrawalModel({required this.id, this.amount = '0.00', this.status = 'pending', @JsonKey(name: 'requested_at') this.requestedAt});
  factory _WithdrawalModel.fromJson(Map<String, dynamic> json) => _$WithdrawalModelFromJson(json);

@override final  int id;
@override@JsonKey() final  String amount;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'requested_at') final  String? requestedAt;

/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalModelCopyWith<_WithdrawalModel> get copyWith => __$WithdrawalModelCopyWithImpl<_WithdrawalModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,status,requestedAt);

@override
String toString() {
  return 'WithdrawalModel(id: $id, amount: $amount, status: $status, requestedAt: $requestedAt)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalModelCopyWith<$Res> implements $WithdrawalModelCopyWith<$Res> {
  factory _$WithdrawalModelCopyWith(_WithdrawalModel value, $Res Function(_WithdrawalModel) _then) = __$WithdrawalModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String amount, String status,@JsonKey(name: 'requested_at') String? requestedAt
});




}
/// @nodoc
class __$WithdrawalModelCopyWithImpl<$Res>
    implements _$WithdrawalModelCopyWith<$Res> {
  __$WithdrawalModelCopyWithImpl(this._self, this._then);

  final _WithdrawalModel _self;
  final $Res Function(_WithdrawalModel) _then;

/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? status = null,Object? requestedAt = freezed,}) {
  return _then(_WithdrawalModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
