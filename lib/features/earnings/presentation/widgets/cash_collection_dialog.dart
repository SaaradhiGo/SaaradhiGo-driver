import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';

class CashCollectionDialog extends StatelessWidget {
  final double amount;
  final VoidCallback onConfirmed;

  const CashCollectionDialog({
    super.key,
    required this.amount,
    required this.onConfirmed,
  });

  static Future<void> show(
    BuildContext context, {
    required double amount,
    required VoidCallback onConfirmed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          CashCollectionDialog(amount: amount, onConfirmed: onConfirmed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payments,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Collect Cash Payment',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please collect cash payment from the passenger before ending the ride summary.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'TOTAL CASH AMOUNT',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'CASH RECEIVED',
              onPressed: () {
                Navigator.of(context).pop();
                onConfirmed();
              },
            ),
          ],
        ),
      ),
    );
  }
}
