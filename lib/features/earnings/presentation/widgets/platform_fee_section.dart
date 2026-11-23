import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../ui/sg_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';

/// Driver fee plans (9 Nov): today's platform fee with its reason, and "How
/// our fee works" written from the active plan's own values. Hidden under the
/// percentage commission, for a class the plan does not cover, or on failure.
final feePlanProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  try {
    final dio = ref.watch(dioClientProvider).dio;
    final res = await dio.get('/driver/fee-plan/');
    final body = res.data;
    final data = body is Map && body['data'] is Map ? body['data'] : body;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  } catch (_) {
    return null;
  }
});

/// The server's own sentence for how the fee works ("No platform fee"), from
/// the day's earnings history; null when it is not there.
final feeNoteProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    final dio = ref.watch(dioClientProvider).dio;
    final res = await dio.get(
      '/driver/earnings/history/',
      queryParameters: {'period': 'day'},
    );
    final body = res.data;
    final data = body is Map && body['data'] is Map ? body['data'] : body;
    final note = data is Map && data['summary'] is Map
        ? '${(data['summary'] as Map)['fee_note'] ?? ''}'.trim()
        : '';
    return note.isEmpty ? null : note;
  } catch (_) {
    return null;
  }
});

/// Whether the driver pays a platform fee plan rather than a commission. A US
/// driver with no plan in force pays nothing, which is still not a commission.
bool usesFeePlan(Map<String, dynamic>? data, {required bool us}) {
  final plan = data?['plan'];
  if (plan is Map) return plan['plan_type'] != 'percent_commission';
  return us;
}

class PlatformFeeSection extends ConsumerWidget {
  const PlatformFeeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final data = ref.watch(feePlanProvider).asData?.value;
    final note = ref.watch(feeNoteProvider).asData?.value;
    final plan = data?['plan'];
    if (data != null && plan == null && note != null) {
      return _noteOnly(l.earnPlatformFee, note);
    }
    final mine = data?['my_amounts'] is Map ? data!['my_amounts'] as Map : const {};
    // 22 Nov: a commission plan with its own percentage is shown like the other plan types.
    if (plan is! Map ||
        (plan['plan_type'] == 'percent_commission' &&
            mine['commission_percent'] == null) ||
        data?['applies_to_my_class'] != true) {
      return const SizedBox.shrink();
    }
    final feeWords = data?['fee_words']?.toString();
    final notice = data?['notice']?.toString();
    final currency = plan['currency']?.toString();
    String m(Object? minor) =>
        sgMoney(
          (num.tryParse('${minor ?? 0}') ?? 0) / 100,
          currency: currency,
          whole: false,
        ) ??
        '';
    final amounts = data?['my_amounts'] is Map
        ? data!['my_amounts'] as Map
        : const {};
    final today = data?['today'];
    final how = <String>[
      ?note,
      if (amounts['per_trip_fee_minor'] != null)
        l.feePerTrip(m(amounts['per_trip_fee_minor'])),
      if (amounts['daily_pass_minor'] != null)
        l.feeDailyPass(m(amounts['daily_pass_minor'])),
      if (amounts['commission_percent'] != null)
        l.feeCommission('${amounts['commission_percent']}'),
      if (plan['daily_cap_minor'] != null) l.feeCap(m(plan['daily_cap_minor'])),
      if ((plan['earnings_floor_minor'] ?? 0) != 0)
        l.feeFloor(m(plan['earnings_floor_minor'])),
      if (plan['waiver_first_days'] != null)
        l.feeWaiver('${plan['waiver_first_days']}'),
      l.feeOncePerDay,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: SgSpace.s3),
      child: Column(
        key: const Key('earn_platform_fee'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.earnPlatformFee,
            style: SgText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (feeWords != null && feeWords.isNotEmpty) ...[
            const SizedBox(height: SgSpace.s2),
            Text(
              l.feeTodayLine(feeWords),
              key: const Key('earn_fee_line'),
              style: SgText.body,
            ),
          ],
          if (notice != null && notice.isNotEmpty && notice != 'null')
            Text(
              notice,
              key: const Key('earn_fee_notice'),
              style: SgText.small.copyWith(color: SgColors.inkMuted),
            ),
          if (today is Map) ...[
            const SizedBox(height: SgSpace.s2),
            Text(
              l.earnPlatformFeeToday(m(today['fee_minor'])),
              style: SgText.body,
            ),
            Text(
              '${today['explanation'] ?? ''}',
              style: SgText.small.copyWith(color: SgColors.inkMuted),
            ),
          ],
          TextButton(
            key: const Key('earn_how_fee_works'),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(SgSpace.s5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.earnHowFeeWorks, style: SgText.title),
                    const SizedBox(height: SgSpace.s3),
                    for (final line in how)
                      Padding(
                        padding: const EdgeInsets.only(bottom: SgSpace.s2),
                        child: Text('• $line', style: SgText.body),
                      ),
                  ],
                ),
              ),
            ),
            child: Text(l.earnHowFeeWorks),
          ),
        ],
      ),
    );
  }

  Widget _noteOnly(String title, String note) => Padding(
    padding: const EdgeInsets.only(top: SgSpace.s3),
    child: Column(
      key: const Key('earn_platform_fee'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: SgText.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: SgSpace.s1),
        Text(note, key: const Key('earn_fee_note'), style: SgText.body),
      ],
    ),
  );
}
