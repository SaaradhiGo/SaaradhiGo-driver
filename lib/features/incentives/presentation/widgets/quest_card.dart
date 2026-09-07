import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/incentive_quest_model.dart';
import '../../../../shared/widgets/glass_panel.dart';

class QuestCard extends StatelessWidget {
  final IncentiveQuestModel quest;
  final VoidCallback? onTap;

  const QuestCard({super.key, required this.quest, this.onTap});

  IconData _resolveIcon(QuestType type) {
    switch (type) {
      case QuestType.peakHour:
        return Icons.bolt_rounded;
      case QuestType.marathon:
        return Icons.directions_run_rounded;
      case QuestType.streak:
        return Icons.local_fire_department_rounded;
      case QuestType.dailyGoal:
        return Icons.today_rounded;
      case QuestType.weeklyMilestone:
        return Icons.emoji_events_rounded;
      case QuestType.custom:
        return Icons.card_giftcard_rounded;
    }
  }

  Color _resolveAccent(QuestType type) {
    if (quest.isCompleted) return AppColors.success;
    switch (type) {
      case QuestType.peakHour:
      case QuestType.streak:
        return AppColors.primary;
      case QuestType.marathon:
      case QuestType.weeklyMilestone:
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _resolveAccent(quest.questType);
    final icon = _resolveIcon(quest.questType);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Icon, Title, and Reward Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Icon(icon, color: accent, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quest.title,
                                  style: AppTypography.bodyLg.copyWith(
                                    color: AppColors.onBackground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (quest.formattedExpiry.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        if (quest.isExpiringSoon) ...[
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppColors.secondary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          quest.formattedExpiry,
                                          style: AppTypography.labelCaps
                                              .copyWith(
                                                color: quest.isExpiringSoon
                                                    ? AppColors.secondary
                                                    : AppColors
                                                          .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '₹${quest.rewardAmount}',
                              style: AppTypography.dataMono.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Description
                      if (quest.description.isNotEmpty)
                        Text(
                          quest.description,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),

                      // Progress Bar & Counter
                      if (quest.isCompleted) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Completed • Credited to Wallet',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          child: LinearProgressIndicator(
                            value: quest.progressFraction,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            color: accent,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${quest.progressTrips} of ${quest.targetTrips} trips',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              quest.remainingTrips == 0
                                  ? 'Goal achieved'
                                  : '${quest.remainingTrips} more to unlock',
                              style: AppTypography.labelCaps.copyWith(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
