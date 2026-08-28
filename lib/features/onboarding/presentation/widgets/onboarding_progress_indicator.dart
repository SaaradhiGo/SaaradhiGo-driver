import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  const OnboardingProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep(context, 1, 'Personal', currentStep >= 1),
        _buildDivider(currentStep > 1),
        _buildStep(context, 2, 'Vehicle', currentStep >= 2),
        _buildDivider(currentStep > 2),
        _buildStep(context, 3, 'Docs', currentStep >= 3),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    int stepNumber,
    String title,
    bool isActive,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: isActive
                ? null
                : Border.all(color: AppColors.outlineVariant),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber.toString(),
            style: AppTypography.labelCaps.copyWith(
              color: isActive ? AppColors.darkText : AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTypography.labelCaps.copyWith(
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
      ),
    );
  }
}
