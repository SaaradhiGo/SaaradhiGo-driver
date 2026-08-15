import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class IncentivesRewardsScreen extends StatelessWidget {
  const IncentivesRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Incentives & Rewards',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            // Active Goal Banner
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weekend Quest', style: AppTypography.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('₹500 BONUS', style: AppTypography.labelCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Complete 10 trips between Fri 6 PM and Sun 11 PM', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.stackMd),

                  // Progress Bar
                  LinearProgressIndicator(
                    value: 7 / 10,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    color: AppColors.primary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('7 of 10 trips completed', style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
                      Text('3 trips left', style: AppTypography.labelCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            Text('Upcoming Quests', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.stackSm),

            _buildQuestTile('Peak Hour Boost', 'Earn extra ₹50 per trip during 8 AM - 11 AM', 'Starts Mon'),
            const SizedBox(height: 8),
            _buildQuestTile('Weekly Mileage Bonus', 'Complete 50 rides for ₹1,500 extra payout', 'Starts Mon'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestTile(String title, String desc, String badge) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge, style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
