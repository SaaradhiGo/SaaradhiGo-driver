import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/route_indicator.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Trip Details',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            // Fare Summary Header
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                children: [
                  Text(
                    'TRIP FARE',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹480',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid via Digital Wallet',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Route Breakdown
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Row(
                children: [
                  const RouteIndicator(height: 50),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('JW Marriott, Juhu', style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                        Text('Pickup • 10:30 PM', style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 24),
                        Text('Bandra Kurla Complex', style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                        Text('Dropoff • 10:52 PM', style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Fare Breakdown List
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fare Breakdown', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
                  const SizedBox(height: 12),
                  _buildFareRow('Base Fare', '₹100'),
                  _buildFareRow('Distance (8.4 km)', '₹280'),
                  _buildFareRow('Time (22 mins)', '₹100'),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                  _buildFareRow('Total Earned', '₹480', isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: isTotal ? AppColors.onSurface : AppColors.onSurfaceVariant,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTypography.dataMono.copyWith(
              color: isTotal ? AppColors.primary : AppColors.onSurface,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
