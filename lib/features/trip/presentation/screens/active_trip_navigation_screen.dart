import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../core/theme/appearance_controller.dart';
import '../../../../ui/driver_trip_views.dart';
import '../../../../ui/sg_tokens.dart';
import '../../../support/presentation/widgets/sos_widgets.dart';
import '../providers/trip_providers.dart';
import '../trip_navigation.dart';
import '../widgets/trip_route_map.dart';

/// State `in_progress` — trip is underway toward the destination.
class ActiveTripNavigationScreen extends ConsumerWidget {
  const ActiveTripNavigationScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tripSessionNotifierProvider);
    final appearance = ref.watch(appearanceControllerProvider);
    final driver = ref.watch(driverPositionProvider);
    final pickup = (trip.pickupLat != null && trip.pickupLng != null)
        ? LatLng(trip.pickupLat!, trip.pickupLng!)
        : null;
    final destination =
        (trip.destinationLat != null && trip.destinationLng != null)
        ? LatLng(trip.destinationLat!, trip.destinationLng!)
        : null;
    final fare = trip.riderPayable ?? trip.finalFare ?? trip.estimatedFare;

    return DriverTripScaffold(
      map: TripRouteMap(
        driver: driver,
        pickup: pickup,
        destination: destination,
        focus: destination,
        padding: kTripMapPadding,
      ),
      // The light "Open in Maps" banner (no turn-by-turn data), with chat and
      // SOS beside it; the night chip only when Automatic chose dark.
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: destination == null
                    ? const SizedBox.shrink()
                    : OpenInMapsBanner(
                        onTap: () => openNavigation(context, destination),
                      ),
              ),
              const SizedBox(width: SgSpace.s2),
              TripSafetyActions(tripId: trip.id, riderName: trip.riderName),
            ],
          ),
          if (appearance.mode == AppearanceMode.automatic &&
              appearance.brightness == Brightness.dark) ...[
            const SizedBox(height: SgSpace.s2),
            const NightModeChip(),
          ],
        ],
      ),
      sheet: InTripSheet(
        destination: trip.destinationAddress ?? 'Drop point on the map',
        riderName: trip.riderName,
        leftLine: distanceTimeLine(trip.distanceKm, trip.durationMin),
        fare: fare == null ? null : exactMoney(fare),
        earning: trip.driverEarning == null
            ? null
            : exactMoney(trip.driverEarning),
        payment: paymentLabel(trip.paymentMethod),
        busy: session.isBusy,
        onComplete: () =>
            ref.read(tripSessionNotifierProvider.notifier).completeRide(),
      ),
    );
  }
}
