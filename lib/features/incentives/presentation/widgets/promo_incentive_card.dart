import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/promo_incentive_model.dart';
import '../../../../shared/widgets/glass_panel.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

/// One incentive from `/promotions/driver/incentives/`: name, progress
/// ("12 of 20 trips"), reward, window, status, and the standing reward note.
class PromoIncentiveCard extends StatelessWidget {
  const PromoIncentiveCard({super.key, required this.incentive, this.now});

  final PromoIncentive incentive;

  /// Injected by tests.
  final DateTime? now;

  Color _stateColor(PromoIncentiveState s) {
    switch (s) {
      case PromoIncentiveState.earned:
        return AppColors.primaryText;
      case PromoIncentiveState.pendingReview:
        return AppColors.primaryText;
      case PromoIncentiveState.inProgress:
        return AppColors.primaryText;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final at = now ?? DateTime.now();
    final state = incentive.stateAt(at);
    final color = _stateColor(state);
    final ends = incentive.endsText(at);
    final showBar =
        state == PromoIncentiveState.inProgress ||
        state == PromoIncentiveState.paused ||
        state == PromoIncentiveState.expired ||
        state == PromoIncentiveState.budgetUsedUp;

    return GlassPanel(
      key: Key('promo_incentive_${incentive.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  incentive.name,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                key: Key('promo_incentive_state_${incentive.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  incentive.labelAt(at),
                  style: AppTypography.labelCaps.copyWith(
                    color: color,
                    fontSize: SgText.sizeSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (incentive.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              incentive.description,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  incentive.progressText,
                  key: Key('promo_incentive_progress_${incentive.id}'),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Reward ${incentive.rewardText}',
                key: Key('promo_incentive_reward_${incentive.id}'),
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (showBar) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: incentive.progressFraction,
                minHeight: 6,
                color: color,
                backgroundColor: AppColors.surfaceContainer,
              ),
            ),
          ],
          if (ends != null && state == PromoIncentiveState.inProgress) ...[
            const SizedBox(height: 6),
            Text(
              ends,
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: SgText.sizeSmall,
              ),
            ),
          ],
          if (state == PromoIncentiveState.budgetUsedUp) ...[
            const SizedBox(height: 6),
            Text(
              'This offer has used up its budget, so no more rewards are being added.',
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: SgText.sizeSmall,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            incentive.rewardNote,
            key: Key('promo_incentive_note_${incentive.id}'),
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: SgText.sizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}
