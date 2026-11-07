import '../../../../ui/sg_l10n.dart';
import '../../../../core/market/market_format.dart';
import '../earnings_display.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_panel.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

class EarningsBreakdownCard extends StatelessWidget {
  final String grossFares;
  final String? commission;
  final String? commissionRate;
  final String? netEarnings;
  /// Null means "none sent": shown as zero in the market's currency.
  final String? tips;
  final String? bonuses;

  /// Money-phase lines. Each is shown only when the API sent it above zero.
  final String? promoPaid;
  final String? promoPaidToday;
  final String? promoPaidLabel;
  final String? incentiveRewards;
  final String? referralRewards;
  final String? incentiveCommission;
  final String? incentiveTax;
  final String? taxCollected;
  final String? taxCollectedLabel;
  final String? regulatoryFees;

  /// A reward held for review, a recovery of a reward and what is still to be
  /// recovered. Each is the API's amount and shown only when above zero; the
  /// labels are the API's words (a neutral default is used when absent).
  final String? rewardsPendingReview;
  final String? rewardsPendingReviewLabel;
  final String? rewardRecovery;
  final String? rewardRecoveryLabel;
  final String? rewardRecoveryRemaining;

  const EarningsBreakdownCard({
    super.key,
    required this.grossFares,
    this.commission,
    this.commissionRate,
    this.netEarnings,
    this.tips,
    this.bonuses,
    this.promoPaid,
    this.promoPaidToday,
    this.promoPaidLabel,
    this.incentiveRewards,
    this.referralRewards,
    this.incentiveCommission,
    this.incentiveTax,
    this.taxCollected,
    this.taxCollectedLabel,
    this.regulatoryFees,
    this.rewardsPendingReview,
    this.rewardsPendingReviewLabel,
    this.rewardRecovery,
    this.rewardRecoveryLabel,
    this.rewardRecoveryRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.earnBreakdown,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(
            icon: Icons.route,
            label: l.breakdownTripFares,
            amount: '${marketSymbol()}$grossFares',
            color: AppColors.onBackground,
          ),
          // TODO(data): tips. The API sends no tips figure, so the line is
          // hidden rather than shown as a made-up zero; the same for bonuses.
          if (tips != null)
            _buildRow(
              icon: Icons.volunteer_activism,
              label: 'Tips',
              amount: tips!,
              color: AppColors.onBackground,
            ),
          if (bonuses != null)
            _buildRow(
              icon: Icons.card_giftcard,
              label: 'Bonuses & Incentives',
              amount: bonuses!,
              color: AppColors.onBackground,
            ),
          // Commission and net are shown only when the API sent a commission.
          if (commission != null) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 16,
            ),
            _buildRow(
              icon: Icons.money_off,
              label: commissionRate == null
                  ? l.breakdownCommission
                  : '${l.breakdownCommission} ($commissionRate)',
              amount: '-${marketSymbol()}$commission',
              color: AppColors.error,
            ),
          ],
          if (netEarnings != null) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 16,
            ),
            _buildNetRow(netEarnings!, l.breakdownNet),
          ],
          // Paid by SaaradhiGo, on top of the trips' net: a rider promo that a
          // cash driver did not collect, its own line.
          if (isPositiveAmount(promoPaid)) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 16,
            ),
            _buildRow(
              key: const Key('breakdown_promo_paid'),
              icon: Icons.local_offer,
              label: (promoPaidLabel?.trim().isNotEmpty ?? false)
                  ? promoPaidLabel!.trim()
                  : 'Promo paid by SaaradhiGo',
              amount: '${marketSymbol()}$promoPaid',
              color: AppColors.onBackground,
              note: isPositiveAmount(promoPaidToday)
                  ? 'Today ${marketSymbol()}$promoPaidToday'
                  : null,
            ),
          ],
          // Incentive and referral rewards: their own lines, no commission,
          // paid in the weekly payout.
          if (isPositiveAmount(incentiveRewards) ||
              isPositiveAmount(referralRewards)) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 16,
            ),
            if (isPositiveAmount(incentiveRewards))
              _buildRow(
                key: const Key('breakdown_incentive_rewards'),
                icon: Icons.emoji_events,
                label: 'Incentive rewards',
                amount: '${marketSymbol()}$incentiveRewards',
                color: AppColors.onBackground,
              ),
            if (isPositiveAmount(referralRewards))
              _buildRow(
                key: const Key('breakdown_referral_rewards'),
                icon: Icons.group_add,
                label: 'Referral rewards',
                amount: '${marketSymbol()}$referralRewards',
                color: AppColors.onBackground,
              ),
            Padding(
              key: const Key('breakdown_reward_note'),
              padding: const EdgeInsets.only(left: 30, bottom: 4),
              child: Text(
                rewardNote(commission: incentiveCommission, tax: incentiveTax),
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: SgText.sizeSmall,
                ),
              ),
            ),
          ],
          // A reward held for review, and the recovery of a reward. Neutral
          // wording only; the held amount is not part of what can be withdrawn.
          if (isPositiveAmount(rewardsPendingReview) ||
              isPositiveAmount(rewardRecovery) ||
              isPositiveAmount(rewardRecoveryRemaining)) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 16,
            ),
            if (isPositiveAmount(rewardsPendingReview))
              _buildRow(
                key: const Key('breakdown_rewards_pending_review'),
                icon: Icons.hourglass_top_rounded,
                label: _labelOr(rewardsPendingReviewLabel, 'Pending review'),
                amount: '${marketSymbol()}$rewardsPendingReview',
                color: AppColors.onSurfaceVariant,
                note: 'Not included in what you can withdraw yet',
              ),
            if (isPositiveAmount(rewardRecovery))
              _buildRow(
                key: const Key('breakdown_reward_recovery'),
                icon: Icons.undo_rounded,
                label: _labelOr(
                  rewardRecoveryLabel,
                  'Recovery of reward (reviewed)',
                ),
                amount: '-${marketSymbol()}$rewardRecovery',
                color: AppColors.error,
              ),
            if (isPositiveAmount(rewardRecoveryRemaining))
              _buildRow(
                key: const Key('breakdown_reward_recovery_remaining'),
                icon: Icons.hourglass_bottom_rounded,
                label: 'Still to be recovered',
                amount: '${marketSymbol()}$rewardRecoveryRemaining',
                color: AppColors.onSurfaceVariant,
                note: 'Taken from future payouts',
              ),
          ],
          // US pass-through: collected from riders and remitted by SaaradhiGo.
          // Not part of the fares, the commission or the net above.
          if (isPositiveAmount(taxCollected) ||
              isPositiveAmount(regulatoryFees)) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 16,
            ),
            if (isPositiveAmount(taxCollected))
              _buildRow(
                key: const Key('breakdown_tax_collected'),
                icon: Icons.receipt_long,
                label: (taxCollectedLabel?.trim().isNotEmpty ?? false)
                    ? taxCollectedLabel!.trim()
                    : 'Sales tax collected (remitted by SaaradhiGo)',
                amount: '${marketSymbol()}$taxCollected',
                color: AppColors.onSurfaceVariant,
              ),
            if (isPositiveAmount(regulatoryFees))
              _buildRow(
                key: const Key('breakdown_fees_collected'),
                icon: Icons.receipt_long,
                label: 'Regulatory fees collected (remitted by SaaradhiGo)',
                amount: '${marketSymbol()}$regulatoryFees',
                color: AppColors.onSurfaceVariant,
              ),
          ],
        ],
      ),
    );
  }

  static String _labelOr(String? label, String fallback) =>
      (label?.trim().isNotEmpty ?? false) ? label!.trim() : fallback;

  Widget _buildNetRow(String netEarnings, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${marketSymbol()}$netEarnings',
            style: AppTypography.dataMono.copyWith(
              color: AppColors.onBackground,
              fontSize: SgText.sizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    Key? key,
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
    String? note,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                      if (note != null)
                        Text(
                          note,
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: SgText.sizeSmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: AppTypography.dataMono.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
