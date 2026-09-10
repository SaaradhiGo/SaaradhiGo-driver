import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class OnboardingVehicleScreen extends StatelessWidget {
  const OnboardingVehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Vehicle Details', showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              'Register Vehicle',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            _buildInputField('Vehicle Number', 'TS 07 AB 1234'),
            const SizedBox(height: 12),
            _buildInputField('Make & Model', 'Maruti Suzuki Swift Dzire'),
            const SizedBox(height: 12),
            _buildInputField('Vehicle Color', 'Arctic White'),
            const SizedBox(height: 12),
            _buildInputField('Model Year', '2023'),
            const SizedBox(height: AppSpacing.stackLg),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'SAVE VEHICLE',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String initialValue) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
