import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../support/presentation/widgets/sos_widgets.dart';
import '../providers/trip_providers.dart';
import '../widgets/trip_route_map.dart';

/// State `in_progress` — trip is underway toward the destination.
class ActiveTripNavigationScreen extends ConsumerWidget {
  const ActiveTripNavigationScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tripSessionNotifierProvider);
    final driver = ref.watch(driverPositionProvider);
    final pickup = (trip.pickupLat != null && trip.pickupLng != null)
        ? LatLng(trip.pickupLat!, trip.pickupLng!)
        : null;
    final destination =
        (trip.destinationLat != null && trip.destinationLng != null)
        ? LatLng(trip.destinationLat!, trip.destinationLng!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: TripRouteMap(
              driver: driver,
              pickup: pickup,
              destination: destination,
              focus: destination,
            ),
          ),
          // Passenger chat + SOS stay reachable during the whole active trip.
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            right: AppSpacing.margin,
            child: TripSafetyActions(
              tripId: trip.id,
              riderName: trip.riderName,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GlassPanel(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.margin,
                right: AppSpacing.margin,
                top: AppSpacing.lg,
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DESTINATION',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trip.destinationAddress ?? 'Destination',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trip.durationMin != null) ...[
                        const SizedBox(width: AppSpacing.md),
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
                              '${trip.durationMin!.round()} min',
                              style: AppTypography.dataMono.copyWith(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: 'COMPLETE TRIP',
                    isLoading: session.isBusy,
                    onPressed: session.isBusy
                        ? null
                        : () => ref
                              .read(tripSessionNotifierProvider.notifier)
                              .completeRide(),
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
