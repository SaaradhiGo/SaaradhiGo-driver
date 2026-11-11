import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_type_converters.dart';

part 'earning_model.freezed.dart';
part 'earning_model.g.dart';

Object? _readTripId(Map<dynamic, dynamic> m, String _) =>
    m['trip_id_val'] ?? m['trip_id'];
Object? _readGross(Map<dynamic, dynamic> m, String _) =>
    m['amount'] ?? m['amount_collected'];
Object? _readCommission(Map<dynamic, dynamic> m, String _) =>
    m['commission'] ?? m['platform_fee'];
Object? _readNet(Map<dynamic, dynamic> m, String _) =>
    m['net_amount'] ?? m['net_earning'];

/// One collected-and-owed line on a cash trip (US pass-through): the rider's
/// sales tax or the per-trip regulatory fee the driver holds and SaaradhiGo
/// remits. `kind` is `tax_collected` or `regulatory_fee_collected`; `label` is
/// the API's own wording ("Sales tax collected (remitted by SaaradhiGo)").
class EarningDeduction {
  const EarningDeduction({
    required this.kind,
    required this.label,
    required this.amount,
  });

  final String kind;
  final String label;
  final String amount;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'label': label,
    'amount': amount,
  };
}

/// Reads the `deductions` list; anything malformed is dropped, and an absent
/// list is empty, so India rows (which send `[]`) and old rows are unchanged.
List<EarningDeduction> deductionsFromJson(dynamic value) {
  if (value is! List) return const [];
  final out = <EarningDeduction>[];
  for (final item in value) {
    if (item is! Map) continue;
    final label = item['label']?.toString().trim() ?? '';
    final amount = nullableMoneyFromJson(item['amount']);
    if (label.isEmpty || amount == null) continue;
    out.add(
      EarningDeduction(
        kind: item['kind']?.toString() ?? '',
        label: label,
        amount: amount,
      ),
    );
  }
  return out;
}

List<Map<String, dynamic>> deductionsToJson(List<EarningDeduction> value) =>
    value.map((d) => d.toJson()).toList();

@freezed
abstract class EarningModel with _$EarningModel {
  const factory EarningModel({
    @JsonKey(fromJson: intFromJson) @Default(0) int id,
    // The settlements endpoint sends `trip_id_val`, `amount`, `commission`,
    // `net_amount` and `commission_percent`; the older names are still read as
    // a fallback. Money and the rate are nullable: nothing is shown for a
    // value the API did not send, and no default is ever invented.
    @JsonKey(
      name: 'trip_id',
      fromJson: nullableIntFromJson,
      readValue: _readTripId,
    )
    int? tripId,
    @JsonKey(
      name: 'amount_collected',
      fromJson: nullableMoneyFromJson,
      readValue: _readGross,
    )
    String? amountCollected,
    @JsonKey(
      name: 'platform_fee',
      fromJson: nullableMoneyFromJson,
      readValue: _readCommission,
    )
    String? platformFee,
    @JsonKey(
      name: 'net_earning',
      fromJson: nullableMoneyFromJson,
      readValue: _readNet,
    )
    String? netEarning,
    @JsonKey(name: 'commission_percent', fromJson: nullableNumFromJson)
    num? commissionPercent,
    @JsonKey(name: 'created_at') String? createdAt,
    // Module 12 / US pass-through, all additive and all null/empty when the API
    // does not send them (India, older settlements). The app shows them as
    // returned and never derives any of them.
    /// `cash`/`online`, as the API labels the trip.
    String? method,
    @JsonKey(name: 'cash_in_hand', fromJson: nullableBoolFromJson)
    bool? cashInHand,
    /// What a cash driver collects from the rider (the fare less a promo, plus
    /// a US trip's tax and fee). Null on an online trip.
    @JsonKey(name: 'cash_to_collect', fromJson: nullableMoneyFromJson)
    String? cashToCollect,
    @JsonKey(name: 'promo_paid_by_platform', fromJson: nullableMoneyFromJson)
    String? promoPaidByPlatform,
    @JsonKey(name: 'promo_paid_label') String? promoPaidLabel,
    @JsonKey(name: 'promo_credited_to_wallet', fromJson: nullableBoolFromJson)
    bool? promoCreditedToWallet,
    /// US only: collected for remittance, never earnings.
    @JsonKey(name: 'tax_collected', fromJson: nullableMoneyFromJson)
    String? taxCollected,
    @JsonKey(name: 'regulatory_fee_collected', fromJson: nullableMoneyFromJson)
    String? regulatoryFeeCollected,
    @JsonKey(
      name: 'deductions',
      fromJson: deductionsFromJson,
      toJson: deductionsToJson,
    )
    @Default(<EarningDeduction>[])
    List<EarningDeduction> deductions,
  }) = _EarningModel;

  factory EarningModel.fromJson(Map<String, dynamic> json) =>
      _$EarningModelFromJson(json);
}
