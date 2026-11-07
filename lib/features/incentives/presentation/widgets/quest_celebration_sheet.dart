import '../../../../core/market/market_format.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/incentive_quest_model.dart';
import '../../../../shared/widgets/bottom_sheet_container.dart';
import '../../../../shared/widgets/buttons.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

class QuestCelebrationSheet extends StatelessWidget {
  final IncentiveQuestModel quest;

  const QuestCelebrationSheet({super.key, required this.quest});

  static void show(BuildContext context, IncentiveQuestModel quest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuestCelebrationSheet(quest: quest),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowGlow,
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primaryText,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Quest Completed!',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              quest.title,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'BONUS REWARD',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+ ${marketSymbol()}${quest.rewardAmount}',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: SgText.sizeHeading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Automatically credited to your driver wallet',
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: SgText.sizeSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'View in Earnings',
              onPressed: () {
                Navigator.pop(context);
                context.push('/earnings');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
