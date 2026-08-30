// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earnings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EarningsState {

 EarningsSummaryModel? get summary; List<EarningModel> get earningsList; WithdrawalBalanceModel? get withdrawalBalance; List<WithdrawalModel> get withdrawalHistory; int get selectedPeriodIndex; bool get isLoading; bool get isRefreshing; bool get isSubmittingWithdrawal; String? get errorMessage; String? get withdrawalSuccessMessage; double? get cashToCollect;
/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningsStateCopyWith<EarningsState> get copyWith => _$EarningsStateCopyWithImpl<EarningsState>(this as EarningsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarningsState&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.earningsList, earningsList)&&(identical(other.withdrawalBalance, withdrawalBalance) || other.withdrawalBalance == withdrawalBalance)&&const DeepCollectionEquality().equals(other.withdrawalHistory, withdrawalHistory)&&(identical(other.selectedPeriodIndex, selectedPeriodIndex) || other.selectedPeriodIndex == selectedPeriodIndex)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isSubmittingWithdrawal, isSubmittingWithdrawal) || other.isSubmittingWithdrawal == isSubmittingWithdrawal)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.withdrawalSuccessMessage, withdrawalSuccessMessage) || other.withdrawalSuccessMessage == withdrawalSuccessMessage)&&(identical(other.cashToCollect, cashToCollect) || other.cashToCollect == cashToCollect));
}


@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(earningsList),withdrawalBalance,const DeepCollectionEquality().hash(withdrawalHistory),selectedPeriodIndex,isLoading,isRefreshing,isSubmittingWithdrawal,errorMessage,withdrawalSuccessMessage,cashToCollect);

@override
String toString() {
  return 'EarningsState(summary: $summary, earningsList: $earningsList, withdrawalBalance: $withdrawalBalance, withdrawalHistory: $withdrawalHistory, selectedPeriodIndex: $selectedPeriodIndex, isLoading: $isLoading, isRefreshing: $isRefreshing, isSubmittingWithdrawal: $isSubmittingWithdrawal, errorMessage: $errorMessage, withdrawalSuccessMessage: $withdrawalSuccessMessage, cashToCollect: $cashToCollect)';
}


}

/// @nodoc
abstract mixin class $EarningsStateCopyWith<$Res>  {
  factory $EarningsStateCopyWith(EarningsState value, $Res Function(EarningsState) _then) = _$EarningsStateCopyWithImpl;
@useResult
$Res call({
 EarningsSummaryModel? summary, List<EarningModel> earningsList, WithdrawalBalanceModel? withdrawalBalance, List<WithdrawalModel> withdrawalHistory, int selectedPeriodIndex, bool isLoading, bool isRefreshing, bool isSubmittingWithdrawal, String? errorMessage, String? withdrawalSuccessMessage, double? cashToCollect
});


$EarningsSummaryModelCopyWith<$Res>? get summary;$WithdrawalBalanceModelCopyWith<$Res>? get withdrawalBalance;

}
/// @nodoc
class _$EarningsStateCopyWithImpl<$Res>
    implements $EarningsStateCopyWith<$Res> {
  _$EarningsStateCopyWithImpl(this._self, this._then);

  final EarningsState _self;
  final $Res Function(EarningsState) _then;

/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = freezed,Object? earningsList = null,Object? withdrawalBalance = freezed,Object? withdrawalHistory = null,Object? selectedPeriodIndex = null,Object? isLoading = null,Object? isRefreshing = null,Object? isSubmittingWithdrawal = null,Object? errorMessage = freezed,Object? withdrawalSuccessMessage = freezed,Object? cashToCollect = freezed,}) {
  return _then(EarningsState(
summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as EarningsSummaryModel?,earningsList: null == earningsList ? _self.earningsList : earningsList // ignore: cast_nullable_to_non_nullable
as List<EarningModel>,withdrawalBalance: freezed == withdrawalBalance ? _self.withdrawalBalance : withdrawalBalance // ignore: cast_nullable_to_non_nullable
as WithdrawalBalanceModel?,withdrawalHistory: null == withdrawalHistory ? _self.withdrawalHistory : withdrawalHistory // ignore: cast_nullable_to_non_nullable
as List<WithdrawalModel>,selectedPeriodIndex: null == selectedPeriodIndex ? _self.selectedPeriodIndex : selectedPeriodIndex // ignore: cast_nullable_to_non_nullable
as int,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isSubmittingWithdrawal: null == isSubmittingWithdrawal ? _self.isSubmittingWithdrawal : isSubmittingWithdrawal // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,withdrawalSuccessMessage: freezed == withdrawalSuccessMessage ? _self.withdrawalSuccessMessage : withdrawalSuccessMessage // ignore: cast_nullable_to_non_nullable
as String?,cashToCollect: freezed == cashToCollect ? _self.cashToCollect : cashToCollect // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EarningsSummaryModelCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $EarningsSummaryModelCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WithdrawalBalanceModelCopyWith<$Res>? get withdrawalBalance {
    if (_self.withdrawalBalance == null) {
    return null;
  }

  return $WithdrawalBalanceModelCopyWith<$Res>(_self.withdrawalBalance!, (value) {
    return _then(_self.copyWith(withdrawalBalance: value));
  });
}
}


/// Adds pattern-matching-related methods to [EarningsState].
extension EarningsStatePatterns on EarningsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarningsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarningsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarningsState value)  $default,){
final _that = this;
switch (_that) {
case _EarningsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarningsState value)?  $default,){
final _that = this;
switch (_that) {
case _EarningsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EarningsSummaryModel? summary,  List<EarningModel> earningsList,  WithdrawalBalanceModel? withdrawalBalance,  List<WithdrawalModel> withdrawalHistory,  int selectedPeriodIndex,  bool isLoading,  bool isRefreshing,  bool isSubmittingWithdrawal,  String? errorMessage,  String? withdrawalSuccessMessage,  double? cashToCollect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarningsState() when $default != null:
return $default(_that.summary,_that.earningsList,_that.withdrawalBalance,_that.withdrawalHistory,_that.selectedPeriodIndex,_that.isLoading,_that.isRefreshing,_that.isSubmittingWithdrawal,_that.errorMessage,_that.withdrawalSuccessMessage,_that.cashToCollect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EarningsSummaryModel? summary,  List<EarningModel> earningsList,  WithdrawalBalanceModel? withdrawalBalance,  List<WithdrawalModel> withdrawalHistory,  int selectedPeriodIndex,  bool isLoading,  bool isRefreshing,  bool isSubmittingWithdrawal,  String? errorMessage,  String? withdrawalSuccessMessage,  double? cashToCollect)  $default,) {final _that = this;
switch (_that) {
case _EarningsState():
return $default(_that.summary,_that.earningsList,_that.withdrawalBalance,_that.withdrawalHistory,_that.selectedPeriodIndex,_that.isLoading,_that.isRefreshing,_that.isSubmittingWithdrawal,_that.errorMessage,_that.withdrawalSuccessMessage,_that.cashToCollect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EarningsSummaryModel? summary,  List<EarningModel> earningsList,  WithdrawalBalanceModel? withdrawalBalance,  List<WithdrawalModel> withdrawalHistory,  int selectedPeriodIndex,  bool isLoading,  bool isRefreshing,  bool isSubmittingWithdrawal,  String? errorMessage,  String? withdrawalSuccessMessage,  double? cashToCollect)?  $default,) {final _that = this;
switch (_that) {
case _EarningsState() when $default != null:
return $default(_that.summary,_that.earningsList,_that.withdrawalBalance,_that.withdrawalHistory,_that.selectedPeriodIndex,_that.isLoading,_that.isRefreshing,_that.isSubmittingWithdrawal,_that.errorMessage,_that.withdrawalSuccessMessage,_that.cashToCollect);case _:
  return null;

}
}

}

/// @nodoc


class _EarningsState implements EarningsState {
  const _EarningsState({this.summary,  List<EarningModel> earningsList = const [], this.withdrawalBalance,  List<WithdrawalModel> withdrawalHistory = const [], this.selectedPeriodIndex = 0, this.isLoading = false, this.isRefreshing = false, this.isSubmittingWithdrawal = false, this.errorMessage, this.withdrawalSuccessMessage, this.cashToCollect}): _earningsList = earningsList,_withdrawalHistory = withdrawalHistory;
  

@override final  EarningsSummaryModel? summary;
 final  List<EarningModel> _earningsList;
@override@JsonKey() List<EarningModel> get earningsList {
  if (_earningsList is EqualUnmodifiableListView) return _earningsList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_earningsList);
}

@override final  WithdrawalBalanceModel? withdrawalBalance;
 final  List<WithdrawalModel> _withdrawalHistory;
@override@JsonKey() List<WithdrawalModel> get withdrawalHistory {
  if (_withdrawalHistory is EqualUnmodifiableListView) return _withdrawalHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_withdrawalHistory);
}

@override@JsonKey() final  int selectedPeriodIndex;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isRefreshing;
@override@JsonKey() final  bool isSubmittingWithdrawal;
@override final  String? errorMessage;
@override final  String? withdrawalSuccessMessage;
@override final  double? cashToCollect;

/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningsStateCopyWith<_EarningsState> get copyWith => __$EarningsStateCopyWithImpl<_EarningsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarningsState&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._earningsList, _earningsList)&&(identical(other.withdrawalBalance, withdrawalBalance) || other.withdrawalBalance == withdrawalBalance)&&const DeepCollectionEquality().equals(other._withdrawalHistory, _withdrawalHistory)&&(identical(other.selectedPeriodIndex, selectedPeriodIndex) || other.selectedPeriodIndex == selectedPeriodIndex)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isSubmittingWithdrawal, isSubmittingWithdrawal) || other.isSubmittingWithdrawal == isSubmittingWithdrawal)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.withdrawalSuccessMessage, withdrawalSuccessMessage) || other.withdrawalSuccessMessage == withdrawalSuccessMessage)&&(identical(other.cashToCollect, cashToCollect) || other.cashToCollect == cashToCollect));
}


@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_earningsList),withdrawalBalance,const DeepCollectionEquality().hash(_withdrawalHistory),selectedPeriodIndex,isLoading,isRefreshing,isSubmittingWithdrawal,errorMessage,withdrawalSuccessMessage,cashToCollect);

@override
String toString() {
  return 'EarningsState(summary: $summary, earningsList: $earningsList, withdrawalBalance: $withdrawalBalance, withdrawalHistory: $withdrawalHistory, selectedPeriodIndex: $selectedPeriodIndex, isLoading: $isLoading, isRefreshing: $isRefreshing, isSubmittingWithdrawal: $isSubmittingWithdrawal, errorMessage: $errorMessage, withdrawalSuccessMessage: $withdrawalSuccessMessage, cashToCollect: $cashToCollect)';
}


}

/// @nodoc
abstract mixin class _$EarningsStateCopyWith<$Res> implements $EarningsStateCopyWith<$Res> {
  factory _$EarningsStateCopyWith(_EarningsState value, $Res Function(_EarningsState) _then) = __$EarningsStateCopyWithImpl;
@override @useResult
$Res call({
 EarningsSummaryModel? summary, List<EarningModel> earningsList, WithdrawalBalanceModel? withdrawalBalance, List<WithdrawalModel> withdrawalHistory, int selectedPeriodIndex, bool isLoading, bool isRefreshing, bool isSubmittingWithdrawal, String? errorMessage, String? withdrawalSuccessMessage, double? cashToCollect
});


@override $EarningsSummaryModelCopyWith<$Res>? get summary;@override $WithdrawalBalanceModelCopyWith<$Res>? get withdrawalBalance;

}
/// @nodoc
class __$EarningsStateCopyWithImpl<$Res>
    implements _$EarningsStateCopyWith<$Res> {
  __$EarningsStateCopyWithImpl(this._self, this._then);

  final _EarningsState _self;
  final $Res Function(_EarningsState) _then;

/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = freezed,Object? earningsList = null,Object? withdrawalBalance = freezed,Object? withdrawalHistory = null,Object? selectedPeriodIndex = null,Object? isLoading = null,Object? isRefreshing = null,Object? isSubmittingWithdrawal = null,Object? errorMessage = freezed,Object? withdrawalSuccessMessage = freezed,Object? cashToCollect = freezed,}) {
  return _then(_EarningsState(
summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as EarningsSummaryModel?,earningsList: null == earningsList ? _self._earningsList : earningsList // ignore: cast_nullable_to_non_nullable
as List<EarningModel>,withdrawalBalance: freezed == withdrawalBalance ? _self.withdrawalBalance : withdrawalBalance // ignore: cast_nullable_to_non_nullable
as WithdrawalBalanceModel?,withdrawalHistory: null == withdrawalHistory ? _self._withdrawalHistory : withdrawalHistory // ignore: cast_nullable_to_non_nullable
as List<WithdrawalModel>,selectedPeriodIndex: null == selectedPeriodIndex ? _self.selectedPeriodIndex : selectedPeriodIndex // ignore: cast_nullable_to_non_nullable
as int,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isSubmittingWithdrawal: null == isSubmittingWithdrawal ? _self.isSubmittingWithdrawal : isSubmittingWithdrawal // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,withdrawalSuccessMessage: freezed == withdrawalSuccessMessage ? _self.withdrawalSuccessMessage : withdrawalSuccessMessage // ignore: cast_nullable_to_non_nullable
as String?,cashToCollect: freezed == cashToCollect ? _self.cashToCollect : cashToCollect // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EarningsSummaryModelCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $EarningsSummaryModelCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of EarningsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WithdrawalBalanceModelCopyWith<$Res>? get withdrawalBalance {
    if (_self.withdrawalBalance == null) {
    return null;
  }

  return $WithdrawalBalanceModelCopyWith<$Res>(_self.withdrawalBalance!, (value) {
    return _then(_self.copyWith(withdrawalBalance: value));
  });
}
}

// dart format on
