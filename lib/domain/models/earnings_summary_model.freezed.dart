// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earnings_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EarningsSummaryModel {

@JsonKey(name: 'total_earned') String get totalEarned;@JsonKey(name: 'total_commission') String get totalCommission;@JsonKey(name: 'total_trips') int get totalTrips;@JsonKey(name: 'today_earned') String get todayEarned;@JsonKey(name: 'today_trips') int get todayTrips;@JsonKey(name: 'commission_percent') num get commissionPercent;
/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningsSummaryModelCopyWith<EarningsSummaryModel> get copyWith => _$EarningsSummaryModelCopyWithImpl<EarningsSummaryModel>(this as EarningsSummaryModel, _$identity);

  /// Serializes this EarningsSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarningsSummaryModel&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.totalCommission, totalCommission) || other.totalCommission == totalCommission)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.todayEarned, todayEarned) || other.todayEarned == todayEarned)&&(identical(other.todayTrips, todayTrips) || other.todayTrips == todayTrips)&&(identical(other.commissionPercent, commissionPercent) || other.commissionPercent == commissionPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEarned,totalCommission,totalTrips,todayEarned,todayTrips,commissionPercent);

@override
String toString() {
  return 'EarningsSummaryModel(totalEarned: $totalEarned, totalCommission: $totalCommission, totalTrips: $totalTrips, todayEarned: $todayEarned, todayTrips: $todayTrips, commissionPercent: $commissionPercent)';
}


}

/// @nodoc
abstract mixin class $EarningsSummaryModelCopyWith<$Res>  {
  factory $EarningsSummaryModelCopyWith(EarningsSummaryModel value, $Res Function(EarningsSummaryModel) _then) = _$EarningsSummaryModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_earned') String totalEarned,@JsonKey(name: 'total_commission') String totalCommission,@JsonKey(name: 'total_trips') int totalTrips,@JsonKey(name: 'today_earned') String todayEarned,@JsonKey(name: 'today_trips') int todayTrips,@JsonKey(name: 'commission_percent') num commissionPercent
});




}
/// @nodoc
class _$EarningsSummaryModelCopyWithImpl<$Res>
    implements $EarningsSummaryModelCopyWith<$Res> {
  _$EarningsSummaryModelCopyWithImpl(this._self, this._then);

  final EarningsSummaryModel _self;
  final $Res Function(EarningsSummaryModel) _then;

/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalEarned = null,Object? totalCommission = null,Object? totalTrips = null,Object? todayEarned = null,Object? todayTrips = null,Object? commissionPercent = null,}) {
  return _then(EarningsSummaryModel(
totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as String,totalCommission: null == totalCommission ? _self.totalCommission : totalCommission // ignore: cast_nullable_to_non_nullable
as String,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,todayEarned: null == todayEarned ? _self.todayEarned : todayEarned // ignore: cast_nullable_to_non_nullable
as String,todayTrips: null == todayTrips ? _self.todayTrips : todayTrips // ignore: cast_nullable_to_non_nullable
as int,commissionPercent: null == commissionPercent ? _self.commissionPercent : commissionPercent // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [EarningsSummaryModel].
extension EarningsSummaryModelPatterns on EarningsSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarningsSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarningsSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _EarningsSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarningsSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_earned')  String totalEarned, @JsonKey(name: 'total_commission')  String totalCommission, @JsonKey(name: 'total_trips')  int totalTrips, @JsonKey(name: 'today_earned')  String todayEarned, @JsonKey(name: 'today_trips')  int todayTrips, @JsonKey(name: 'commission_percent')  num commissionPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
return $default(_that.totalEarned,_that.totalCommission,_that.totalTrips,_that.todayEarned,_that.todayTrips,_that.commissionPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_earned')  String totalEarned, @JsonKey(name: 'total_commission')  String totalCommission, @JsonKey(name: 'total_trips')  int totalTrips, @JsonKey(name: 'today_earned')  String todayEarned, @JsonKey(name: 'today_trips')  int todayTrips, @JsonKey(name: 'commission_percent')  num commissionPercent)  $default,) {final _that = this;
switch (_that) {
case _EarningsSummaryModel():
return $default(_that.totalEarned,_that.totalCommission,_that.totalTrips,_that.todayEarned,_that.todayTrips,_that.commissionPercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_earned')  String totalEarned, @JsonKey(name: 'total_commission')  String totalCommission, @JsonKey(name: 'total_trips')  int totalTrips, @JsonKey(name: 'today_earned')  String todayEarned, @JsonKey(name: 'today_trips')  int todayTrips, @JsonKey(name: 'commission_percent')  num commissionPercent)?  $default,) {final _that = this;
switch (_that) {
case _EarningsSummaryModel() when $default != null:
return $default(_that.totalEarned,_that.totalCommission,_that.totalTrips,_that.todayEarned,_that.todayTrips,_that.commissionPercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarningsSummaryModel implements EarningsSummaryModel {
  const _EarningsSummaryModel({@JsonKey(name: 'total_earned') this.totalEarned = '0.00', @JsonKey(name: 'total_commission') this.totalCommission = '0.00', @JsonKey(name: 'total_trips') this.totalTrips = 0, @JsonKey(name: 'today_earned') this.todayEarned = '0.00', @JsonKey(name: 'today_trips') this.todayTrips = 0, @JsonKey(name: 'commission_percent') this.commissionPercent = 10});
  factory _EarningsSummaryModel.fromJson(Map<String, dynamic> json) => _$EarningsSummaryModelFromJson(json);

@override@JsonKey(name: 'total_earned') final  String totalEarned;
@override@JsonKey(name: 'total_commission') final  String totalCommission;
@override@JsonKey(name: 'total_trips') final  int totalTrips;
@override@JsonKey(name: 'today_earned') final  String todayEarned;
@override@JsonKey(name: 'today_trips') final  int todayTrips;
@override@JsonKey(name: 'commission_percent') final  num commissionPercent;

/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningsSummaryModelCopyWith<_EarningsSummaryModel> get copyWith => __$EarningsSummaryModelCopyWithImpl<_EarningsSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarningsSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarningsSummaryModel&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.totalCommission, totalCommission) || other.totalCommission == totalCommission)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.todayEarned, todayEarned) || other.todayEarned == todayEarned)&&(identical(other.todayTrips, todayTrips) || other.todayTrips == todayTrips)&&(identical(other.commissionPercent, commissionPercent) || other.commissionPercent == commissionPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEarned,totalCommission,totalTrips,todayEarned,todayTrips,commissionPercent);

@override
String toString() {
  return 'EarningsSummaryModel(totalEarned: $totalEarned, totalCommission: $totalCommission, totalTrips: $totalTrips, todayEarned: $todayEarned, todayTrips: $todayTrips, commissionPercent: $commissionPercent)';
}


}

/// @nodoc
abstract mixin class _$EarningsSummaryModelCopyWith<$Res> implements $EarningsSummaryModelCopyWith<$Res> {
  factory _$EarningsSummaryModelCopyWith(_EarningsSummaryModel value, $Res Function(_EarningsSummaryModel) _then) = __$EarningsSummaryModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_earned') String totalEarned,@JsonKey(name: 'total_commission') String totalCommission,@JsonKey(name: 'total_trips') int totalTrips,@JsonKey(name: 'today_earned') String todayEarned,@JsonKey(name: 'today_trips') int todayTrips,@JsonKey(name: 'commission_percent') num commissionPercent
});




}
/// @nodoc
class __$EarningsSummaryModelCopyWithImpl<$Res>
    implements _$EarningsSummaryModelCopyWith<$Res> {
  __$EarningsSummaryModelCopyWithImpl(this._self, this._then);

  final _EarningsSummaryModel _self;
  final $Res Function(_EarningsSummaryModel) _then;

/// Create a copy of EarningsSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalEarned = null,Object? totalCommission = null,Object? totalTrips = null,Object? todayEarned = null,Object? todayTrips = null,Object? commissionPercent = null,}) {
  return _then(_EarningsSummaryModel(
totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as String,totalCommission: null == totalCommission ? _self.totalCommission : totalCommission // ignore: cast_nullable_to_non_nullable
as String,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,todayEarned: null == todayEarned ? _self.todayEarned : todayEarned // ignore: cast_nullable_to_non_nullable
as String,todayTrips: null == todayTrips ? _self.todayTrips : todayTrips // ignore: cast_nullable_to_non_nullable
as int,commissionPercent: null == commissionPercent ? _self.commissionPercent : commissionPercent // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
