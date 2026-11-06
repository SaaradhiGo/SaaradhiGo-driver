import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../ui/driver_trip_views.dart';
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
      ),
      // Passenger chat + SOS stay reachable during the whole active trip.
      topActions: TripSafetyActions(tripId: trip.id, riderName: trip.riderName),
      mapButton: destination == null
          ? null
          : NavigateButton(onTap: () => openNavigation(context, destination)),
      sheet: InTripSheet(
        destination: trip.destinationAddress ?? 'Drop point on the map',
        riderName: trip.riderName,
        leftLine: distanceTimeLine(trip.distanceKm, trip.durationMin),
        fare: fare == null ? null : exactMoney(fare),
        payment: paymentLabel(trip.paymentMethod),
        busy: session.isBusy,
        onComplete: () =>
            ref.read(tripSessionNotifierProvider.notifier).completeRide(),
      ),
    );
  }
}
