import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../navigation/route_names.dart';

class AcceptedRideScreen extends StatelessWidget {
  const AcceptedRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Ride Accepted',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            children: [
              // Rider Info Header Card
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Icon(Icons.person, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ananya S.',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '4.9 Rating',
                                style: AppTypography.dataMono.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quick Call/Message Buttons
                    IconButton(
                      icon: const Icon(Icons.call, color: AppColors.primary),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: AppColors.primary),
                      onPressed: () => Navigator.pushNamed(context, RouteNames.messages),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Pickup Details Card
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICKUP LOCATION',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'JW Marriott, Juhu, Mumbai',
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '3.2 km away • ~8 mins drive',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Primary Actions
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, RouteNames.arrivedAtPickup);
                  },
                  child: Text(
                    'ARRIVED AT PICKUP',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL RIDE',
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.error,
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
}
