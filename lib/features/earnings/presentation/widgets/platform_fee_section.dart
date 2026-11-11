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

class PlatformFeeSection extends ConsumerWidget {
  const PlatformFeeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final data = ref.watch(feePlanProvider).asData?.value;
    final plan = data?['plan'];
    if (plan is! Map ||
        plan['plan_type'] == 'percent_commission' ||
        data?['applies_to_my_class'] != true) {
      return const SizedBox.shrink();
    }
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
      if (amounts['per_trip_fee_minor'] != null)
        l.feePerTrip(m(amounts['per_trip_fee_minor'])),
      if (amounts['daily_pass_minor'] != null)
        l.feeDailyPass(m(amounts['daily_pass_minor'])),
      if (plan['daily_cap_minor'] != null) l.feeCap(m(plan['daily_cap_minor'])),
      if ((plan['earnings_floor_minor'] ?? 0) != 0)
        l.feeFloor(m(plan['earnings_floor_minor'])),
      if (plan['waiver_first_days'] != null)
        l.feeWaiver('${plan['waiver_first_days']}'),
      l.feeKeep80,
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
}
