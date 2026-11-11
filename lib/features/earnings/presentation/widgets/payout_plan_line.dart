import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/sg_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../providers/payout_plan.dart';
import 'instant_withdraw_sheet.dart';

/// "Next payout: {date} · estimated {amount}" and, only where instant
/// cash-out is on for the driver's city, Withdraw now (owner ruling, 9 Nov).
/// Hidden entirely when the balance call fails.
class PayoutPlanLine extends ConsumerWidget {
  const PayoutPlanLine({super.key, required this.available});

  final double? available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final plan = ref.watch(payoutPlanProvider).asData?.value;
    if (plan == null) return const SizedBox.shrink();
    final next = plan.nextAt;
    final text = next == null
        ? l.earnPayoutsOnRequest
        : l.earnNextPayout(
            MaterialLocalizations.of(context).formatMediumDate(next.toLocal()),
            sgMoney(
                  plan.estimatedAmount,
                  currency: plan.currency,
                  whole: false,
                ) ??
                '',
          );
    return Padding(
      padding: const EdgeInsets.only(top: SgSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            key: const Key('earn_next_payout'),
            style: SgText.small.copyWith(color: SgColors.inkMuted),
          ),
          if (plan.instantAvailable && (available ?? 0) > 0) ...[
            const SizedBox(height: SgSpace.s2),
            OutlinedButton(
              key: const Key('earn_withdraw_now'),
              onPressed: () async {
                final sent = await InstantWithdrawSheet.show(
                  context,
                  available ?? 0,
                );
                if (sent == true && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l.instantSent)));
                }
              },
              child: Text(l.instantTitle),
            ),
          ],
        ],
      ),
    );
  }
}
