/// Reads for Tier 3 screens 5 and 6 that the existing models do not carry.
/// Each is optional: a failure hides its element rather than showing a guess.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../ui/driver_f_logic.dart';
import '../../../documents/checklist_docs.dart';
import '../../../requirements/requirements_api.dart';

/// `GET /driver/earnings/daily/?days=31` (the chart shows the last 7; week and
/// month sum them). Null when the call fails or the body
/// is not the expected shape, and the chart is hidden.
final dailyEarningsProvider = FutureProvider.autoDispose<List<DailyEarning>?>((
  ref,
) async {
  try {
    final dio = ref.watch(dioClientProvider).dio;
    final res = await dio.get(
      ApiEndpoints.driverEarningsDaily,
      queryParameters: {'days': 31},
    );
    return parseDailyEarnings(res.data);
  } catch (_) {
    return null;
  }
});

/// `payout_details_on_file` from `GET /driver/withdrawals/balance/`. Null when
/// the call fails or the field is absent (the missing-payout card is hidden).
final payoutDetailsOnFileProvider = FutureProvider.autoDispose<bool?>((
  ref,
) async {
  try {
    final dio = ref.watch(dioClientProvider).dio;
    final res = await dio.get(ApiEndpoints.driverWithdrawalBalance);
    final body = res.data;
    final data = body is Map && body['data'] is Map ? body['data'] : body;
    final v = data is Map ? data['payout_details_on_file'] : null;
    return v is bool ? v : null;
  } catch (_) {
    return null;
  }
});

/// The Documents rows: the shared requirements checklist
/// (`GET /driver/requirements/`, field `checklist`). The old onboarding call
/// is kept for the upload action only.
final docsOverviewProvider = FutureProvider.autoDispose<DocsOverview>((
  ref,
) async {
  final r = await ref.watch(requirementsApiProvider).load();
  return docsFromRequirements(r);
});
