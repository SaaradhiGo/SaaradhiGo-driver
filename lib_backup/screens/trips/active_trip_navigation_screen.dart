import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../navigation/route_names.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_session_provider.dart';

class ActiveTripNavigationScreen extends StatelessWidget {
  const ActiveTripNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TripSessionProvider>();
    final data = session.tripData;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map Canvas Placeholder
          Container(
            color: const Color(0xFF1A1C23),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    size: 80,
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Active Trip Navigation',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Instruction Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.containerMargin),
                child: GlassPanel(
                  padding: const EdgeInsets.all(AppSpacing.stackMd),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.turn_right,
                          color: AppColors.onPrimary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'In 200m turn right',
                              style: AppTypography.headlineSm.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'onto Western Express Highway',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SOS FAB Floating
          Positioned(
            bottom: 240,
            left: AppSpacing.containerMargin,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorContainer.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.sos,
                  color: AppColors.onErrorContainer,
                  size: 28,
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.safetyCenter),
              ),
            ),
          ),

          // Bottom Navigation Card & Complete Trip Action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassPanel(
              borderRadius: 24,
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DESTINATION',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            data?['destination_address']?.toString() ??
                                'Destination',
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'ETA',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            data?['duration_min'] != null
                                ? '${data!['duration_min']} mins'
                                : '-- mins',
                            style: AppTypography.dataMono.copyWith(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Complete Trip Button
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
                      onPressed: session.isLoading
                          ? null
                          : () {
                              session.completeTrip();
                            },
                      child: session.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'COMPLETE TRIP',
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
        ],
      ),
    );
  }
}
