import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../navigation/route_names.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_session_provider.dart';

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TripSessionProvider>();
    final data = session.tripData;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Success Checkmark Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryContainer,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 60,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'Trip Completed!',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You earned for this ride',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₹${data?['estimated_fare']?.toString() ?? '0.00'}',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Metrics Card
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(
                      'DISTANCE',
                      data?['distance_km'] != null
                          ? '${data!['distance_km']} km'
                          : '--',
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    _buildMetric(
                      'DURATION',
                      data?['duration_min'] != null
                          ? '${data!['duration_min']} mins'
                          : '--',
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    _buildMetric(
                      'PAYMENT',
                      data?['payment_method']?.toString().toUpperCase() ??
                          'DIGITAL',
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Done CTA
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
                  onPressed: () {
                    session.clearSession();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.dashboard,
                      (route) => false,
                    );
                  },
                  child: Text(
                    'BACK TO DASHBOARD',
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
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.dataMono.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
