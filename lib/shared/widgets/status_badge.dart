import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum BadgeStatus { success, pending, error, neutral }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeStatus status;

  const StatusBadge({
    super.key,
    required this.text,
    this.status = BadgeStatus.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color containerColor;
    Color textColor;

    switch (status) {
      case BadgeStatus.success:
        containerColor = AppColors.successContainer;
        textColor = AppColors.success;
        break;
      case BadgeStatus.pending:
        containerColor = AppColors.pendingContainer;
        textColor = AppColors.secondary;
        break;
      case BadgeStatus.error:
        containerColor = AppColors.errorContainer;
        textColor = AppColors.error;
        break;
      case BadgeStatus.neutral:
        containerColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.onBackground;
        break;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.labelCaps.copyWith(color: textColor),
      ),
    );
  }
}
