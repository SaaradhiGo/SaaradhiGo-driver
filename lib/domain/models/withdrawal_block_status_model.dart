import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'withdrawal_block_status_model.freezed.dart';
part 'withdrawal_block_status_model.g.dart';

@freezed
abstract class WithdrawalBlockStatusModel with _$WithdrawalBlockStatusModel {
  const factory WithdrawalBlockStatusModel({
    @JsonKey(fromJson: boolFromJson) @Default(false) bool blocked,
    @JsonKey(name: 'last_withdrawal_at') String? lastWithdrawalAt,
    @JsonKey(name: 'block_remaining_seconds', fromJson: nullableIntFromJson)
    int? blockRemainingSeconds,
  }) = _WithdrawalBlockStatusModel;

  factory WithdrawalBlockStatusModel.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalBlockStatusModelFromJson(json);
}
