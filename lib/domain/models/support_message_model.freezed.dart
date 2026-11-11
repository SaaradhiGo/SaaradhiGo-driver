// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportMessageModel {

@JsonKey(fromJson: intFromJson) int get id;@JsonKey(readValue: _readSenderRole) String? get senderRole; String? get body;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'is_system', fromJson: boolFromJson) bool get isSystem;
/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportMessageModelCopyWith<SupportMessageModel> get copyWith => _$SupportMessageModelCopyWithImpl<SupportMessageModel>(this as SupportMessageModel, _$identity);

  /// Serializes this SupportMessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.senderRole, senderRole) || other.senderRole == senderRole)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderRole,body,createdAt,isSystem);

@override
String toString() {
  return 'SupportMessageModel(id: $id, senderRole: $senderRole, body: $body, createdAt: $createdAt, isSystem: $isSystem)';
}


}

/// @nodoc
abstract mixin class $SupportMessageModelCopyWith<$Res>  {
  factory $SupportMessageModelCopyWith(SupportMessageModel value, $Res Function(SupportMessageModel) _then) = _$SupportMessageModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id,@JsonKey(readValue: _readSenderRole) String? senderRole, String? body,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'is_system', fromJson: boolFromJson) bool isSystem
});




}
/// @nodoc
class _$SupportMessageModelCopyWithImpl<$Res>
    implements $SupportMessageModelCopyWith<$Res> {
  _$SupportMessageModelCopyWithImpl(this._self, this._then);

  final SupportMessageModel _self;
  final $Res Function(SupportMessageModel) _then;

/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderRole = freezed,Object? body = freezed,Object? createdAt = freezed,Object? isSystem = null,}) {
  return _then(SupportMessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,senderRole: freezed == senderRole ? _self.senderRole : senderRole // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportMessageModel].
extension SupportMessageModelPatterns on SupportMessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportMessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportMessageModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportMessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportMessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(readValue: _readSenderRole)  String? senderRole,  String? body, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'is_system', fromJson: boolFromJson)  bool isSystem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
return $default(_that.id,_that.senderRole,_that.body,_that.createdAt,_that.isSystem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(readValue: _readSenderRole)  String? senderRole,  String? body, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'is_system', fromJson: boolFromJson)  bool isSystem)  $default,) {final _that = this;
switch (_that) {
case _SupportMessageModel():
return $default(_that.id,_that.senderRole,_that.body,_that.createdAt,_that.isSystem);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: intFromJson)  int id, @JsonKey(readValue: _readSenderRole)  String? senderRole,  String? body, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'is_system', fromJson: boolFromJson)  bool isSystem)?  $default,) {final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
return $default(_that.id,_that.senderRole,_that.body,_that.createdAt,_that.isSystem);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportMessageModel implements SupportMessageModel {
  const _SupportMessageModel({@JsonKey(fromJson: intFromJson) this.id = 0, @JsonKey(readValue: _readSenderRole) this.senderRole, this.body, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'is_system', fromJson: boolFromJson) this.isSystem = false});
  factory _SupportMessageModel.fromJson(Map<String, dynamic> json) => _$SupportMessageModelFromJson(json);

@override@JsonKey(fromJson: intFromJson) final  int id;
@override@JsonKey(readValue: _readSenderRole) final  String? senderRole;
@override final  String? body;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'is_system', fromJson: boolFromJson) final  bool isSystem;

/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportMessageModelCopyWith<_SupportMessageModel> get copyWith => __$SupportMessageModelCopyWithImpl<_SupportMessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportMessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.senderRole, senderRole) || other.senderRole == senderRole)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderRole,body,createdAt,isSystem);

@override
String toString() {
  return 'SupportMessageModel(id: $id, senderRole: $senderRole, body: $body, createdAt: $createdAt, isSystem: $isSystem)';
}


}

/// @nodoc
abstract mixin class _$SupportMessageModelCopyWith<$Res> implements $SupportMessageModelCopyWith<$Res> {
  factory _$SupportMessageModelCopyWith(_SupportMessageModel value, $Res Function(_SupportMessageModel) _then) = __$SupportMessageModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id,@JsonKey(readValue: _readSenderRole) String? senderRole, String? body,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'is_system', fromJson: boolFromJson) bool isSystem
});




}
/// @nodoc
class __$SupportMessageModelCopyWithImpl<$Res>
    implements _$SupportMessageModelCopyWith<$Res> {
  __$SupportMessageModelCopyWithImpl(this._self, this._then);

  final _SupportMessageModel _self;
  final $Res Function(_SupportMessageModel) _then;

/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderRole = freezed,Object? body = freezed,Object? createdAt = freezed,Object? isSystem = null,}) {
  return _then(_SupportMessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,senderRole: freezed == senderRole ? _self.senderRole : senderRole // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
