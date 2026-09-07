// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_document_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverDocumentModel {

 String get id; String get documentTypeKey; String get title; String? get fileUrl; DateTime? get expiryDate; DocumentStatus get status; String? get rejectionReason; bool get isMandatory;
/// Create a copy of DriverDocumentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverDocumentModelCopyWith<DriverDocumentModel> get copyWith => _$DriverDocumentModelCopyWithImpl<DriverDocumentModel>(this as DriverDocumentModel, _$identity);

  /// Serializes this DriverDocumentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverDocumentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.documentTypeKey, documentTypeKey) || other.documentTypeKey == documentTypeKey)&&(identical(other.title, title) || other.title == title)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentTypeKey,title,fileUrl,expiryDate,status,rejectionReason,isMandatory);

@override
String toString() {
  return 'DriverDocumentModel(id: $id, documentTypeKey: $documentTypeKey, title: $title, fileUrl: $fileUrl, expiryDate: $expiryDate, status: $status, rejectionReason: $rejectionReason, isMandatory: $isMandatory)';
}


}

/// @nodoc
abstract mixin class $DriverDocumentModelCopyWith<$Res>  {
  factory $DriverDocumentModelCopyWith(DriverDocumentModel value, $Res Function(DriverDocumentModel) _then) = _$DriverDocumentModelCopyWithImpl;
@useResult
$Res call({
 String id, String documentTypeKey, String title, String? fileUrl, DateTime? expiryDate, DocumentStatus status, String? rejectionReason, bool isMandatory
});




}
/// @nodoc
class _$DriverDocumentModelCopyWithImpl<$Res>
    implements $DriverDocumentModelCopyWith<$Res> {
  _$DriverDocumentModelCopyWithImpl(this._self, this._then);

  final DriverDocumentModel _self;
  final $Res Function(DriverDocumentModel) _then;

/// Create a copy of DriverDocumentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? documentTypeKey = null,Object? title = null,Object? fileUrl = freezed,Object? expiryDate = freezed,Object? status = null,Object? rejectionReason = freezed,Object? isMandatory = null,}) {
  return _then(DriverDocumentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentTypeKey: null == documentTypeKey ? _self.documentTypeKey : documentTypeKey // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverDocumentModel].
extension DriverDocumentModelPatterns on DriverDocumentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverDocumentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverDocumentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverDocumentModel value)  $default,){
final _that = this;
switch (_that) {
case _DriverDocumentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverDocumentModel value)?  $default,){
final _that = this;
switch (_that) {
case _DriverDocumentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String documentTypeKey,  String title,  String? fileUrl,  DateTime? expiryDate,  DocumentStatus status,  String? rejectionReason,  bool isMandatory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverDocumentModel() when $default != null:
return $default(_that.id,_that.documentTypeKey,_that.title,_that.fileUrl,_that.expiryDate,_that.status,_that.rejectionReason,_that.isMandatory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String documentTypeKey,  String title,  String? fileUrl,  DateTime? expiryDate,  DocumentStatus status,  String? rejectionReason,  bool isMandatory)  $default,) {final _that = this;
switch (_that) {
case _DriverDocumentModel():
return $default(_that.id,_that.documentTypeKey,_that.title,_that.fileUrl,_that.expiryDate,_that.status,_that.rejectionReason,_that.isMandatory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String documentTypeKey,  String title,  String? fileUrl,  DateTime? expiryDate,  DocumentStatus status,  String? rejectionReason,  bool isMandatory)?  $default,) {final _that = this;
switch (_that) {
case _DriverDocumentModel() when $default != null:
return $default(_that.id,_that.documentTypeKey,_that.title,_that.fileUrl,_that.expiryDate,_that.status,_that.rejectionReason,_that.isMandatory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverDocumentModel extends DriverDocumentModel {
  const _DriverDocumentModel({required this.id, required this.documentTypeKey, required this.title, this.fileUrl, this.expiryDate, this.status = DocumentStatus.missing, this.rejectionReason, this.isMandatory = true}): super._();
  factory _DriverDocumentModel.fromJson(Map<String, dynamic> json) => _$DriverDocumentModelFromJson(json);

@override final  String id;
@override final  String documentTypeKey;
@override final  String title;
@override final  String? fileUrl;
@override final  DateTime? expiryDate;
@override@JsonKey() final  DocumentStatus status;
@override final  String? rejectionReason;
@override@JsonKey() final  bool isMandatory;

/// Create a copy of DriverDocumentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverDocumentModelCopyWith<_DriverDocumentModel> get copyWith => __$DriverDocumentModelCopyWithImpl<_DriverDocumentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverDocumentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverDocumentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.documentTypeKey, documentTypeKey) || other.documentTypeKey == documentTypeKey)&&(identical(other.title, title) || other.title == title)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentTypeKey,title,fileUrl,expiryDate,status,rejectionReason,isMandatory);

@override
String toString() {
  return 'DriverDocumentModel(id: $id, documentTypeKey: $documentTypeKey, title: $title, fileUrl: $fileUrl, expiryDate: $expiryDate, status: $status, rejectionReason: $rejectionReason, isMandatory: $isMandatory)';
}


}

/// @nodoc
abstract mixin class _$DriverDocumentModelCopyWith<$Res> implements $DriverDocumentModelCopyWith<$Res> {
  factory _$DriverDocumentModelCopyWith(_DriverDocumentModel value, $Res Function(_DriverDocumentModel) _then) = __$DriverDocumentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String documentTypeKey, String title, String? fileUrl, DateTime? expiryDate, DocumentStatus status, String? rejectionReason, bool isMandatory
});




}
/// @nodoc
class __$DriverDocumentModelCopyWithImpl<$Res>
    implements _$DriverDocumentModelCopyWith<$Res> {
  __$DriverDocumentModelCopyWithImpl(this._self, this._then);

  final _DriverDocumentModel _self;
  final $Res Function(_DriverDocumentModel) _then;

/// Create a copy of DriverDocumentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? documentTypeKey = null,Object? title = null,Object? fileUrl = freezed,Object? expiryDate = freezed,Object? status = null,Object? rejectionReason = freezed,Object? isMandatory = null,}) {
  return _then(_DriverDocumentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentTypeKey: null == documentTypeKey ? _self.documentTypeKey : documentTypeKey // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
