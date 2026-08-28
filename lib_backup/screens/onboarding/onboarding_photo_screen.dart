import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class OnboardingPhotoScreen extends StatelessWidget {
  const OnboardingPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Profile Photo & Bank',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text('Driver Profile Photo', style: AppTypography.headlineSm.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.stackLg),

            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.camera_alt, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text('Take a clear selfie', style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('No glasses, hat, or dark background.', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('SUBMIT PROFILE PHOTO', style: AppTypography.headlineSm.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
