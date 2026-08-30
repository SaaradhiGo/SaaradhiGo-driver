import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class DocumentVaultScreen extends StatelessWidget {
  const DocumentVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Document Vault', showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              'Required Documents',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All documents must be clear and currently valid.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            _buildDocumentItem(
              title: 'Driving Licence',
              expiry: 'Expires Oct 2028',
              status: 'VERIFIED',
              isVerified: true,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildDocumentItem(
              title: 'Vehicle Registration (RC)',
              expiry: 'Expires Jan 2030',
              status: 'VERIFIED',
              isVerified: true,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildDocumentItem(
              title: 'Commercial Insurance',
              expiry: 'Expires in 5 days',
              status: 'RENEWAL DUE',
              isWarning: true,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildDocumentItem(
              title: 'Vehicle Permit',
              expiry: 'Expires Mar 2027',
              status: 'VERIFIED',
              isVerified: true,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildDocumentItem(
              title: 'Police Verification',
              expiry: 'Submitted Oct 2026',
              status: 'PENDING',
              isPending: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String expiry,
    required String status,
    bool isVerified = false,
    bool isWarning = false,
    bool isPending = false,
  }) {
    Color badgeColor = AppColors.onSurfaceVariant;
    if (isVerified) badgeColor = AppColors.primary;
    if (isWarning) badgeColor = AppColors.error;
    if (isPending) badgeColor = AppColors.secondary;

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expiry,
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              status,
              style: AppTypography.labelCaps.copyWith(
                color: badgeColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
