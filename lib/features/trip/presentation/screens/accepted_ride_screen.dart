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
import '../widgets/cancel_trip_sheet.dart';
import '../widgets/rider_summary_row.dart';
import '../widgets/trip_route_map.dart';

/// State `accepted` — driver is en route to the pickup point.
class AcceptedRideScreen extends ConsumerWidget {
  const AcceptedRideScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tripSessionNotifierProvider);
    final driver = ref.watch(driverPositionProvider);
    final pickup = (trip.pickupLat != null && trip.pickupLng != null)
        ? LatLng(trip.pickupLat!, trip.pickupLng!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: TripRouteMap(driver: driver, pickup: pickup, focus: pickup),
          ),
          // Passenger chat + SOS stay reachable while en route to pickup.
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
                  Text(
                    'HEADING TO PICKUP',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          trip.pickupAddress ?? 'Pickup location',
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (trip.distanceKm != null || trip.durationMin != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _distanceDuration(trip),
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  RiderSummaryRow(name: trip.riderName ?? 'Passenger'),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: 'ARRIVED AT PICKUP',
                    isLoading: session.isBusy,
                    onPressed: session.isBusy
                        ? null
                        : () => ref
                              .read(tripSessionNotifierProvider.notifier)
                              .markReached(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    text: 'CANCEL RIDE',
                    onPressed: session.isBusy
                        ? null
                        : () => showCancelTripSheet(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _distanceDuration(TripModel trip) {
    final parts = <String>[];
    if (trip.distanceKm != null) {
      parts.add('${trip.distanceKm!.toStringAsFixed(1)} km');
    }
    if (trip.durationMin != null) {
      parts.add('~${trip.durationMin!.round()} mins');
    }
    return parts.join(' • ');
  }
}
