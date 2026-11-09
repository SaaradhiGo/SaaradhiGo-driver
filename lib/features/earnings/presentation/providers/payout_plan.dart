/// The payout plan (owner ruling, 9 Nov): when the driver is next paid and
/// whether Withdraw now is offered in their city, from
/// `GET /driver/withdrawals/balance/`. Read raw so the balance model is
/// unchanged; a failure hides both lines rather than showing a guess.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class PayoutPlan {
  const PayoutPlan({
    this.nextAt,
    this.estimatedAmount,
    this.currency,
    this.instantAvailable = false,
    this.provider,
  });

  /// The next scheduled payout, or null when payouts here are on request.
  final DateTime? nextAt;
  final String? estimatedAmount;
  final String? currency;
  final bool instantAvailable;
  final String? provider;
}

PayoutPlan? parsePayoutPlan(Object? body) {
  final data = body is Map && body['data'] is Map ? body['data'] : body;
  if (data is! Map) return null;
  final next = data['next_payout'];
  final instant = data['instant'];
  return PayoutPlan(
    nextAt: next is Map && next['at'] is String
        ? DateTime.tryParse(next['at'] as String)
        : null,
    estimatedAmount: next is Map ? next['estimated_amount']?.toString() : null,
    currency: next is Map
        ? next['currency']?.toString()
        : data['currency']?.toString(),
    instantAvailable: instant is Map && instant['available'] == true,
    provider: instant is Map ? instant['provider']?.toString() : null,
  );
}

final payoutPlanProvider = FutureProvider.autoDispose<PayoutPlan?>((ref) async {
  try {
    final dio = ref.watch(dioClientProvider).dio;
    final res = await dio.get(ApiEndpoints.driverWithdrawalBalance);
    return parsePayoutPlan(res.data);
  } catch (_) {
    return null;
  }
});

/// The Withdraw now confirmation (`GET /driver/withdrawals/instant/quote/`).
/// The fee shown is the fee the withdrawal is charged: one server rule.
class InstantQuote {
  const InstantQuote({
    required this.amount,
    required this.providerFee,
    required this.providerFeeLabel,
    required this.saaradhigoFee,
    required this.youReceive,
    required this.currency,
    required this.destination,
    required this.arrival,
    required this.valid,
  });

  final String amount;
  final String providerFee;
  final String providerFeeLabel;
  final String saaradhigoFee;
  final String youReceive;
  final String currency;
  final String? destination;
  final String arrival;
  final bool valid;
}

InstantQuote? parseInstantQuote(Object? body) {
  final d = body is Map && body['data'] is Map ? body['data'] : body;
  if (d is! Map || d['amount'] == null) return null;
  return InstantQuote(
    amount: d['amount'].toString(),
    providerFee: d['provider_fee'].toString(),
    providerFeeLabel: (d['provider_fee_label'] ?? 'Provider fee').toString(),
    saaradhigoFee: (d['saaradhigo_fee'] ?? '0').toString(),
    youReceive: d['you_receive'].toString(),
    currency: (d['currency'] ?? '').toString(),
    destination: d['destination']?.toString(),
    arrival: (d['arrival'] ?? '').toString(),
    valid: d['valid'] == true,
  );
}
