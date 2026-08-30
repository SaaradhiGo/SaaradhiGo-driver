import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/route_indicator.dart';

import '../../services/trip_service.dart';
import '../../models/trip_model.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripId = ModalRoute.of(context)?.settings.arguments as int?;

    if (tripId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppTopBar(title: 'Trip Details', showBackButton: true),
        body: const Center(
          child: Text(
            'Invalid Trip ID',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Trip Details', showBackButton: true),
      body: FutureBuilder<TripModel?>(
        future: TripService.getTripDetails(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                'Failed to load trip details',
                style: AppTypography.bodyLg.copyWith(color: AppColors.error),
              ),
            );
          }

          final trip = snapshot.data!;
          final fare = trip.finalFare ?? trip.estimatedFare ?? '0';
          final paymentMethod = trip.paymentMethod ?? 'Unknown';
          final paymentStatus = trip.paymentStatus ?? 'pending';
          final pickup = trip.pickupAddress ?? 'Unknown Pickup';
          final dropoff = trip.destinationAddress ?? 'Unknown Dropoff';
          final distance = trip.distanceKm ?? '--';
          final duration = trip.durationMin ?? '--';

          final paymentString =
              paymentStatus != 'null' && paymentStatus.isNotEmpty
              ? '${paymentMethod.toUpperCase()} (${paymentStatus.toUpperCase()})'
              : paymentMethod.toUpperCase();

          return SafeArea(
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
                        '₹$fare',
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid via $paymentString',
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
                            Text(
                              pickup,
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Pickup',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              dropoff,
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Dropoff',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
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
                      Text(
                        'Trip Summary',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFareRow('Distance', '$distance km'),
                      _buildFareRow('Duration', '$duration mins'),
                      if (trip.fareBreakdown != null) ...[
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        Text(
                          'FARE BREAKDOWN',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (trip.fareBreakdown!['base_fare'] != null)
                          _buildFareRow(
                            'Base Fare',
                            '₹${trip.fareBreakdown!['base_fare']}',
                          ),
                        if (trip.fareBreakdown!['distance_fare'] != null)
                          _buildFareRow(
                            'Distance Fare',
                            '₹${trip.fareBreakdown!['distance_fare']}',
                          ),
                        if (trip.fareBreakdown!['time_fare'] != null)
                          _buildFareRow(
                            'Time Fare',
                            '₹${trip.fareBreakdown!['time_fare']}',
                          ),
                        if (trip.surgeMultiplier != null &&
                            trip.surgeMultiplier != '1.0' &&
                            trip.surgeMultiplier != '1.00')
                          _buildFareRow(
                            'Surge Multiplier',
                            'x${trip.surgeMultiplier}',
                          ),
                      ],
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.05),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      _buildFareRow('Total Earned', '₹$fare', isTotal: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
