import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../providers/trip_history_providers.dart';
import '../widgets/trip_route_mini_map.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final int tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripDetailsNotifierProvider.notifier).loadTrip(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripDetailsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trip Details',
          style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state.hasError || state.trip == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.margin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.errorMessage ?? 'Failed to load trip details',
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.darkText,
                        ),
                        onPressed: () {
                          ref
                              .read(tripDetailsNotifierProvider.notifier)
                              .loadTrip(widget.tripId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final trip = state.trip!;
            final isCancelled = trip.status == TripStatus.cancelled;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // Route Map Section
                TripRouteMiniMap(
                  pickupLat: trip.pickupLat,
                  pickupLng: trip.pickupLng,
                  destinationLat: trip.destinationLat,
                  destinationLng: trip.destinationLng,
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.margin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Passenger Info Card
                      _buildPassengerCard(trip),
                      const SizedBox(height: AppSpacing.md),

                      // Route Addresses
                      _buildRouteCard(trip),
                      const SizedBox(height: AppSpacing.md),

                      // Quick Stats Grid
                      _buildQuickStats(trip),
                      const SizedBox(height: AppSpacing.md),

                      // Cancellation Banner if cancelled
                      if (isCancelled) ...[
                        _buildCancellationBanner(trip),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Invoicing Breakdown
                      _buildFinancialBreakdown(trip, isCancelled),
                      const SizedBox(height: AppSpacing.md),

                      // Rating Section (Hidden on Cancelled Rides)
                      if (!isCancelled) ...[
                        _buildRatingSection(trip),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Support Help Action
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.help_outline, size: 20),
                        label: Text(
                          'Need Help with this Trip?',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => context.push('/support'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPassengerCard(TripModel trip) {
    final riderName = trip.riderName ?? 'Passenger';
    final riderInitial = riderName.isNotEmpty
        ? riderName[0].toUpperCase()
        : 'P';
    final riderRating = trip.riderRating != null
        ? trip.riderRating!.toStringAsFixed(1)
        : '4.9';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              riderInitial,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderName,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.unit),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      riderRating,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
              ),
              Container(
                width: 2,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.outlineVariant],
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKUP',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trip.pickupAddress ?? 'Pickup Address',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'DESTINATION',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trip.destinationAddress ?? 'Destination Address',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(TripModel trip) {
    final paymentMethod = (trip.paymentMethod ?? 'Digital').toUpperCase();
    final isCash = paymentMethod.contains('CASH');

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            icon: Icons.route_outlined,
            value: trip.distanceKm != null
                ? trip.distanceKm!.toStringAsFixed(1)
                : '--',
            label: 'KM',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatTile(
            icon: Icons.timer_outlined,
            value: trip.durationMin != null
                ? '${trip.durationMin!.toInt()}'
                : '--',
            label: 'MINS',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatTile(
            icon: isCash
                ? Icons.account_balance_wallet_outlined
                : Icons.contactless_outlined,
            value: isCash ? 'Cash' : 'Digital',
            label: 'PAYMENT',
            isPrimaryIcon: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    bool isPrimaryIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isPrimaryIcon ? AppColors.primary : AppColors.outline,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationBanner(TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Trip Cancelled',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            trip.cancellationReason ??
                'This trip was cancelled before completion.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onBackground,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No fare was charged to the rider. Net Earnings: ₹0',
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBreakdown(TripModel trip, bool isCancelled) {
    final fare = trip.finalFare ?? trip.estimatedFare ?? '0';
    final breakdown = trip.fareBreakdown;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Breakdown',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onBackground,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.md),

          if (isCancelled) ...[
            _buildBreakdownRow('Trip Fare', '₹0'),
            const SizedBox(height: AppSpacing.sm),
            _buildBreakdownRow(
              'Cancellation Adjustment',
              '-₹0',
              isDeduction: true,
            ),
          ] else if (breakdown != null && breakdown.isNotEmpty) ...[
            for (final entry in breakdown.entries)
              if (entry.key != 'driver_earnings' &&
                  entry.key != 'net_earnings') ...[
                _buildBreakdownRow(
                  _formatBreakdownKey(entry.key),
                  '₹${entry.value}',
                  isDeduction:
                      entry.key.contains('fee') ||
                      entry.key.contains('commission') ||
                      entry.key.contains('tax'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ] else ...[
            _buildBreakdownRow('Trip Fare', '₹$fare'),
            const SizedBox(height: AppSpacing.sm),
            _buildBreakdownRow(
              'Platform Service Fee',
              '-₹0',
              isDeduction: true,
            ),
          ],

          const Divider(color: AppColors.outlineVariant, height: AppSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver Earnings',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 16,
                ),
              ),
              Text(
                isCancelled ? '₹0' : '₹$fare',
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBreakdownKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  Widget _buildBreakdownRow(
    String label,
    String value, {
    bool isDeduction = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: AppTypography.dataMono.copyWith(
            color: isDeduction ? AppColors.error : AppColors.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'YOUR RATING FOR PASSENGER',
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.star, size: 28, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
