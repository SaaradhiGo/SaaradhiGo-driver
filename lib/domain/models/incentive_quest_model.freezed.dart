// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incentive_quest_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IncentiveQuestModel {

@JsonKey(fromJson: intFromJson) int get id; String get title; String get description;@JsonKey(name: 'target_trips', fromJson: intFromJson) int get targetTrips;@JsonKey(name: 'progress_trips', fromJson: intFromJson) int get progressTrips;@JsonKey(name: 'reward_amount', fromJson: moneyFromJson) String get rewardAmount;@JsonKey(name: 'is_completed', fromJson: boolFromJson) bool get isCompleted;@JsonKey(name: 'expires_at') DateTime? get expiresAt; String? get type;
/// Create a copy of IncentiveQuestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncentiveQuestModelCopyWith<IncentiveQuestModel> get copyWith => _$IncentiveQuestModelCopyWithImpl<IncentiveQuestModel>(this as IncentiveQuestModel, _$identity);

  /// Serializes this IncentiveQuestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncentiveQuestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetTrips, targetTrips) || other.targetTrips == targetTrips)&&(identical(other.progressTrips, progressTrips) || other.progressTrips == progressTrips)&&(identical(other.rewardAmount, rewardAmount) || other.rewardAmount == rewardAmount)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,targetTrips,progressTrips,rewardAmount,isCompleted,expiresAt,type);

@override
String toString() {
  return 'IncentiveQuestModel(id: $id, title: $title, description: $description, targetTrips: $targetTrips, progressTrips: $progressTrips, rewardAmount: $rewardAmount, isCompleted: $isCompleted, expiresAt: $expiresAt, type: $type)';
}


}

/// @nodoc
abstract mixin class $IncentiveQuestModelCopyWith<$Res>  {
  factory $IncentiveQuestModelCopyWith(IncentiveQuestModel value, $Res Function(IncentiveQuestModel) _then) = _$IncentiveQuestModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id, String title, String description,@JsonKey(name: 'target_trips', fromJson: intFromJson) int targetTrips,@JsonKey(name: 'progress_trips', fromJson: intFromJson) int progressTrips,@JsonKey(name: 'reward_amount', fromJson: moneyFromJson) String rewardAmount,@JsonKey(name: 'is_completed', fromJson: boolFromJson) bool isCompleted,@JsonKey(name: 'expires_at') DateTime? expiresAt, String? type
});




}
/// @nodoc
class _$IncentiveQuestModelCopyWithImpl<$Res>
    implements $IncentiveQuestModelCopyWith<$Res> {
  _$IncentiveQuestModelCopyWithImpl(this._self, this._then);

  final IncentiveQuestModel _self;
  final $Res Function(IncentiveQuestModel) _then;

/// Create a copy of IncentiveQuestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? targetTrips = null,Object? progressTrips = null,Object? rewardAmount = null,Object? isCompleted = null,Object? expiresAt = freezed,Object? type = freezed,}) {
  return _then(IncentiveQuestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,targetTrips: null == targetTrips ? _self.targetTrips : targetTrips // ignore: cast_nullable_to_non_nullable
as int,progressTrips: null == progressTrips ? _self.progressTrips : progressTrips // ignore: cast_nullable_to_non_nullable
as int,rewardAmount: null == rewardAmount ? _self.rewardAmount : rewardAmount // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IncentiveQuestModel].
extension IncentiveQuestModelPatterns on IncentiveQuestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncentiveQuestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncentiveQuestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncentiveQuestModel value)  $default,){
final _that = this;
switch (_that) {
case _IncentiveQuestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncentiveQuestModel value)?  $default,){
final _that = this;
switch (_that) {
case _IncentiveQuestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id,  String title,  String description, @JsonKey(name: 'target_trips', fromJson: intFromJson)  int targetTrips, @JsonKey(name: 'progress_trips', fromJson: intFromJson)  int progressTrips, @JsonKey(name: 'reward_amount', fromJson: moneyFromJson)  String rewardAmount, @JsonKey(name: 'is_completed', fromJson: boolFromJson)  bool isCompleted, @JsonKey(name: 'expires_at')  DateTime? expiresAt,  String? type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncentiveQuestModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.targetTrips,_that.progressTrips,_that.rewardAmount,_that.isCompleted,_that.expiresAt,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: intFromJson)  int id,  String title,  String description, @JsonKey(name: 'target_trips', fromJson: intFromJson)  int targetTrips, @JsonKey(name: 'progress_trips', fromJson: intFromJson)  int progressTrips, @JsonKey(name: 'reward_amount', fromJson: moneyFromJson)  String rewardAmount, @JsonKey(name: 'is_completed', fromJson: boolFromJson)  bool isCompleted, @JsonKey(name: 'expires_at')  DateTime? expiresAt,  String? type)  $default,) {final _that = this;
switch (_that) {
case _IncentiveQuestModel():
return $default(_that.id,_that.title,_that.description,_that.targetTrips,_that.progressTrips,_that.rewardAmount,_that.isCompleted,_that.expiresAt,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: intFromJson)  int id,  String title,  String description, @JsonKey(name: 'target_trips', fromJson: intFromJson)  int targetTrips, @JsonKey(name: 'progress_trips', fromJson: intFromJson)  int progressTrips, @JsonKey(name: 'reward_amount', fromJson: moneyFromJson)  String rewardAmount, @JsonKey(name: 'is_completed', fromJson: boolFromJson)  bool isCompleted, @JsonKey(name: 'expires_at')  DateTime? expiresAt,  String? type)?  $default,) {final _that = this;
switch (_that) {
case _IncentiveQuestModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.targetTrips,_that.progressTrips,_that.rewardAmount,_that.isCompleted,_that.expiresAt,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IncentiveQuestModel extends IncentiveQuestModel {
  const _IncentiveQuestModel({@JsonKey(fromJson: intFromJson) required this.id, this.title = '', this.description = '', @JsonKey(name: 'target_trips', fromJson: intFromJson) this.targetTrips = 1, @JsonKey(name: 'progress_trips', fromJson: intFromJson) this.progressTrips = 0, @JsonKey(name: 'reward_amount', fromJson: moneyFromJson) this.rewardAmount = '0.00', @JsonKey(name: 'is_completed', fromJson: boolFromJson) this.isCompleted = false, @JsonKey(name: 'expires_at') this.expiresAt, this.type}): super._();
  factory _IncentiveQuestModel.fromJson(Map<String, dynamic> json) => _$IncentiveQuestModelFromJson(json);

@override@JsonKey(fromJson: intFromJson) final  int id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'target_trips', fromJson: intFromJson) final  int targetTrips;
@override@JsonKey(name: 'progress_trips', fromJson: intFromJson) final  int progressTrips;
@override@JsonKey(name: 'reward_amount', fromJson: moneyFromJson) final  String rewardAmount;
@override@JsonKey(name: 'is_completed', fromJson: boolFromJson) final  bool isCompleted;
@override@JsonKey(name: 'expires_at') final  DateTime? expiresAt;
@override final  String? type;

/// Create a copy of IncentiveQuestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncentiveQuestModelCopyWith<_IncentiveQuestModel> get copyWith => __$IncentiveQuestModelCopyWithImpl<_IncentiveQuestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncentiveQuestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncentiveQuestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetTrips, targetTrips) || other.targetTrips == targetTrips)&&(identical(other.progressTrips, progressTrips) || other.progressTrips == progressTrips)&&(identical(other.rewardAmount, rewardAmount) || other.rewardAmount == rewardAmount)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,targetTrips,progressTrips,rewardAmount,isCompleted,expiresAt,type);

@override
String toString() {
  return 'IncentiveQuestModel(id: $id, title: $title, description: $description, targetTrips: $targetTrips, progressTrips: $progressTrips, rewardAmount: $rewardAmount, isCompleted: $isCompleted, expiresAt: $expiresAt, type: $type)';
}


}

/// @nodoc
abstract mixin class _$IncentiveQuestModelCopyWith<$Res> implements $IncentiveQuestModelCopyWith<$Res> {
  factory _$IncentiveQuestModelCopyWith(_IncentiveQuestModel value, $Res Function(_IncentiveQuestModel) _then) = __$IncentiveQuestModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: intFromJson) int id, String title, String description,@JsonKey(name: 'target_trips', fromJson: intFromJson) int targetTrips,@JsonKey(name: 'progress_trips', fromJson: intFromJson) int progressTrips,@JsonKey(name: 'reward_amount', fromJson: moneyFromJson) String rewardAmount,@JsonKey(name: 'is_completed', fromJson: boolFromJson) bool isCompleted,@JsonKey(name: 'expires_at') DateTime? expiresAt, String? type
});




}
/// @nodoc
class __$IncentiveQuestModelCopyWithImpl<$Res>
    implements _$IncentiveQuestModelCopyWith<$Res> {
  __$IncentiveQuestModelCopyWithImpl(this._self, this._then);

  final _IncentiveQuestModel _self;
  final $Res Function(_IncentiveQuestModel) _then;

/// Create a copy of IncentiveQuestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? targetTrips = null,Object? progressTrips = null,Object? rewardAmount = null,Object? isCompleted = null,Object? expiresAt = freezed,Object? type = freezed,}) {
  return _then(_IncentiveQuestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,targetTrips: null == targetTrips ? _self.targetTrips : targetTrips // ignore: cast_nullable_to_non_nullable
as int,progressTrips: null == progressTrips ? _self.progressTrips : progressTrips // ignore: cast_nullable_to_non_nullable
as int,rewardAmount: null == rewardAmount ? _self.rewardAmount : rewardAmount // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
