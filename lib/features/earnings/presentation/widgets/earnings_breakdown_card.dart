import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_panel.dart';

class EarningsBreakdownCard extends StatelessWidget {
  final String grossFares;
  final String? commission;
  final String? commissionRate;
  final String? netEarnings;
  final String tips;
  final String bonuses;

  const EarningsBreakdownCard({
    super.key,
    required this.grossFares,
    this.commission,
    this.commissionRate,
    this.netEarnings,
    this.tips = '₹0.00',
    this.bonuses = '₹0.00',
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown',
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
            label: 'Trip Fares (Gross)',
            amount: '₹$grossFares',
            color: AppColors.onBackground,
          ),
          _buildRow(
            icon: Icons.volunteer_activism,
            label: 'Tips',
            amount: tips,
            color: AppColors.onBackground,
          ),
          _buildRow(
            icon: Icons.card_giftcard,
            label: 'Bonuses & Incentives',
            amount: bonuses,
            color: AppColors.primary,
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
                  ? 'Platform Commission'
                  : 'Platform Commission ($commissionRate)',
              amount: '-₹$commission',
              color: AppColors.error,
            ),
          ],
          if (netEarnings != null) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 16,
            ),
            _buildNetRow(netEarnings!),
          ],
        ],
      ),
    );
  }

  Widget _buildNetRow(String netEarnings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Net Driver Earnings',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '₹$netEarnings',
            style: AppTypography.dataMono.copyWith(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
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
