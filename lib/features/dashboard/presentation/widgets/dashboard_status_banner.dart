import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum DashboardBannerTone { warning, error, info }

/// Slim top banner for transient, non-blocking conditions: weak GPS
/// (docs/10_LOCATION.md §4), no network, and "Reconnecting…"
/// (docs/14_ERROR_HANDLING.md:18).
class DashboardStatusBanner extends StatelessWidget {
  const DashboardStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    this.tone = DashboardBannerTone.warning,
    this.showProgress = false,
  });

  final String message;
  final IconData icon;
  final DashboardBannerTone tone;
  final bool showProgress;

  Color get _background => switch (tone) {
    DashboardBannerTone.warning => AppColors.pendingContainer,
    DashboardBannerTone.error => AppColors.errorContainer,
    DashboardBannerTone.info => AppColors.surfaceContainerHigh,
  };

  Color get _foreground => switch (tone) {
    DashboardBannerTone.warning => AppColors.onBackground,
    DashboardBannerTone.error => AppColors.whiteText,
    DashboardBannerTone.info => AppColors.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          if (showProgress)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _foreground,
              ),
            )
          else
            Icon(icon, size: 16, color: _foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.labelCaps.copyWith(color: _foreground),
            ),
          ),
        ],
      ),
    );
  }
}
