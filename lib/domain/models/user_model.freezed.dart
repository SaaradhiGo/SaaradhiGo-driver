// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 int get id;@JsonKey(name: 'phone_number') String? get phoneNumber; UserRole get role;@JsonKey(name: 'full_name') String? get fullName; String? get email; String? get avatar;@JsonKey(name: 'is_updated') bool get isUpdated;@JsonKey(name: 'fcm_token') String? get fcmToken;@JsonKey(name: 'emergency_contact') String? get emergencyContact;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.role, role) || other.role == role)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.isUpdated, isUpdated) || other.isUpdated == isUpdated)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,role,fullName,email,avatar,isUpdated,fcmToken,emergencyContact);

@override
String toString() {
  return 'UserModel(id: $id, phoneNumber: $phoneNumber, role: $role, fullName: $fullName, email: $email, avatar: $avatar, isUpdated: $isUpdated, fcmToken: $fcmToken, emergencyContact: $emergencyContact)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'phone_number') String? phoneNumber, UserRole role,@JsonKey(name: 'full_name') String? fullName, String? email, String? avatar,@JsonKey(name: 'is_updated') bool isUpdated,@JsonKey(name: 'fcm_token') String? fcmToken,@JsonKey(name: 'emergency_contact') String? emergencyContact
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phoneNumber = freezed,Object? role = null,Object? fullName = freezed,Object? email = freezed,Object? avatar = freezed,Object? isUpdated = null,Object? fcmToken = freezed,Object? emergencyContact = freezed,}) {
  return _then(UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,isUpdated: null == isUpdated ? _self.isUpdated : isUpdated // ignore: cast_nullable_to_non_nullable
as bool,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,emergencyContact: freezed == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'phone_number')  String? phoneNumber,  UserRole role, @JsonKey(name: 'full_name')  String? fullName,  String? email,  String? avatar, @JsonKey(name: 'is_updated')  bool isUpdated, @JsonKey(name: 'fcm_token')  String? fcmToken, @JsonKey(name: 'emergency_contact')  String? emergencyContact)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.role,_that.fullName,_that.email,_that.avatar,_that.isUpdated,_that.fcmToken,_that.emergencyContact);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'phone_number')  String? phoneNumber,  UserRole role, @JsonKey(name: 'full_name')  String? fullName,  String? email,  String? avatar, @JsonKey(name: 'is_updated')  bool isUpdated, @JsonKey(name: 'fcm_token')  String? fcmToken, @JsonKey(name: 'emergency_contact')  String? emergencyContact)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.phoneNumber,_that.role,_that.fullName,_that.email,_that.avatar,_that.isUpdated,_that.fcmToken,_that.emergencyContact);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'phone_number')  String? phoneNumber,  UserRole role, @JsonKey(name: 'full_name')  String? fullName,  String? email,  String? avatar, @JsonKey(name: 'is_updated')  bool isUpdated, @JsonKey(name: 'fcm_token')  String? fcmToken, @JsonKey(name: 'emergency_contact')  String? emergencyContact)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.role,_that.fullName,_that.email,_that.avatar,_that.isUpdated,_that.fcmToken,_that.emergencyContact);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({required this.id, @JsonKey(name: 'phone_number') this.phoneNumber, this.role = UserRole.driver, @JsonKey(name: 'full_name') this.fullName, this.email, this.avatar, @JsonKey(name: 'is_updated') this.isUpdated = false, @JsonKey(name: 'fcm_token') this.fcmToken, @JsonKey(name: 'emergency_contact') this.emergencyContact});
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'phone_number') final  String? phoneNumber;
@override@JsonKey() final  UserRole role;
@override@JsonKey(name: 'full_name') final  String? fullName;
@override final  String? email;
@override final  String? avatar;
@override@JsonKey(name: 'is_updated') final  bool isUpdated;
@override@JsonKey(name: 'fcm_token') final  String? fcmToken;
@override@JsonKey(name: 'emergency_contact') final  String? emergencyContact;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.role, role) || other.role == role)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.isUpdated, isUpdated) || other.isUpdated == isUpdated)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,role,fullName,email,avatar,isUpdated,fcmToken,emergencyContact);

@override
String toString() {
  return 'UserModel(id: $id, phoneNumber: $phoneNumber, role: $role, fullName: $fullName, email: $email, avatar: $avatar, isUpdated: $isUpdated, fcmToken: $fcmToken, emergencyContact: $emergencyContact)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'phone_number') String? phoneNumber, UserRole role,@JsonKey(name: 'full_name') String? fullName, String? email, String? avatar,@JsonKey(name: 'is_updated') bool isUpdated,@JsonKey(name: 'fcm_token') String? fcmToken,@JsonKey(name: 'emergency_contact') String? emergencyContact
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phoneNumber = freezed,Object? role = null,Object? fullName = freezed,Object? email = freezed,Object? avatar = freezed,Object? isUpdated = null,Object? fcmToken = freezed,Object? emergencyContact = freezed,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,isUpdated: null == isUpdated ? _self.isUpdated : isUpdated // ignore: cast_nullable_to_non_nullable
as bool,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,emergencyContact: freezed == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
