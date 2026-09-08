import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/kyc_checklist_item.dart';

/// Checklist row in VerificationStatusScreen matching the Stitch design with
/// dynamic status badge and inline rejection remediation CTA.
class VerificationStatusRow extends StatelessWidget {
  const VerificationStatusRow({
    super.key,
    required this.item,
    this.onRemediate,
  });

  final KycChecklistItem item;
  final VoidCallback? onRemediate;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status.color;
    final isActionNeeded = item.status == KycItemStatus.actionRequired;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + Title
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: isActionNeeded
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        item.title,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.status.icon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    item.status.label,
                    style: AppTypography.labelCaps.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Remediation Section if Action is Required
          if (item.rejectionReason != null &&
              item.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.unit),
            Container(
              margin: const EdgeInsets.only(left: 32, top: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.unit,
              ),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.rejectionReason!,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: () {
                      onRemediate?.call();
                      context.push(item.targetRoute);
                    },
                    borderRadius: BorderRadius.circular(4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        'Fix',
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
