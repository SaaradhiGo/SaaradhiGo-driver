import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../navigation/route_names.dart';

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Verification Status',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                children: [
                  const Icon(
                    Icons.fact_check,
                    size: 60,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Application Under Review',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We are verifying your documents. This usually takes 24-48 hours.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            _buildStepTile(
              'Personal Details',
              'Completed',
              true,
              () => Navigator.pushNamed(context, RouteNames.onboardingPersonal),
            ),
            const SizedBox(height: 8),
            _buildStepTile(
              'Driving License',
              'Completed',
              true,
              () => Navigator.pushNamed(context, RouteNames.onboardingLicense),
            ),
            const SizedBox(height: 8),
            _buildStepTile(
              'Vehicle Details',
              'Completed',
              true,
              () => Navigator.pushNamed(context, RouteNames.onboardingVehicle),
            ),
            const SizedBox(height: 8),
            _buildStepTile(
              'Profile Photo & Bank',
              'Completed',
              true,
              () => Navigator.pushNamed(context, RouteNames.onboardingPhotos),
            ),
            const SizedBox(height: 8),
            _buildStepTile('Background Check', 'In Verification', false, null),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTile(
    String title,
    String status,
    bool isDone,
    VoidCallback? onTap,
  ) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.hourglass_top,
            color: isDone ? Colors.green : AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            status,
            style: AppTypography.labelCaps.copyWith(
              color: isDone ? Colors.green : AppColors.secondary,
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
