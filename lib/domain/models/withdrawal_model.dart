import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawal_model.freezed.dart';
part 'withdrawal_model.g.dart';

@freezed
abstract class WithdrawalModel with _$WithdrawalModel {
  const factory WithdrawalModel({
    required int id,
    @Default('0.00') String amount,
    @Default('pending') String status,
    @JsonKey(name: 'requested_at') String? requestedAt,
  }) = _WithdrawalModel;

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalModelFromJson(json);
}
