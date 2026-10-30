import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/elite_status_model.dart';
import '../../../../shared/widgets/glass_panel.dart';

class PrivilegeMatrixCard extends StatelessWidget {
  final EliteTier currentTier;

  const PrivilegeMatrixCard({super.key, required this.currentTier});

  bool _isUnlocked(EliteTier requiredTier) {
    return currentTier.index >= requiredTier.index;
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Partner Privileges & Perks',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPerkRow(
            icon: Icons.flight_takeoff_rounded,
            title: 'Priority Airport & Hub Dispatch',
            subtitle: 'First in queue for high-value airport arrivals',
            requiredTier: EliteTier.gold,
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 20),
          _buildPerkRow(
            icon: Icons.support_agent_rounded,
            title: 'Dedicated 24x7 VIP Support Line',
            subtitle: 'Direct queue-jump access to senior driver support',
            requiredTier: EliteTier.platinum,
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 20),
          _buildPerkRow(
            icon: Icons.local_gas_station_rounded,
            title: 'Elite Partner Fuel & Service Vouchers',
            subtitle: 'Up to ₹2,500 monthly cashback on fuel and tyre care',
            requiredTier: EliteTier.diamond,
          ),
        ],
      ),
    );
  }

  Widget _buildPerkRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required EliteTier requiredTier,
  }) {
    final unlocked = _isUnlocked(requiredTier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: unlocked
                ? AppColors.primaryContainer.withValues(alpha: 0.15)
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: unlocked ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMd.copyWith(
                  color: unlocked
                      ? AppColors.onBackground
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (unlocked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'UNLOCKED',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  requiredTier.name.toUpperCase(),
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
