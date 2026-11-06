import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../ui/driver_trip_views.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../support/presentation/widgets/sos_widgets.dart';
import '../providers/route_providers.dart';
import '../providers/trip_providers.dart';
import '../trip_navigation.dart';
import '../widgets/cancel_trip_sheet.dart';
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
    // The same leg TripRouteMap draws, so this reuses its cached road.
    final away = driver != null && pickup != null
        ? roadLine(
            ref.watch(routeForLegProvider(RouteLeg(driver, pickup))).value ??
                const [],
          )
        : null;

    return DriverTripScaffold(
      map: TripRouteMap(
        driver: driver,
        pickup: pickup,
        focus: pickup,
        padding: kTripMapPadding,
      ),
      // SOS stays reachable; chat is the message button on the rider row.
      topActions: TripSosButton(tripId: trip.id),
      mapButton: pickup == null
          ? null
          : NavigateButton(onTap: () => openNavigation(context, pickup)),
      sheet: ToPickupSheet(
        riderName: trip.riderName,
        riderRating: trip.riderRating,
        pickupAddress: trip.pickupAddress ?? sgL10n(context).tripPickupOnMap,
        awayLine: away,
        busy: session.isBusy,
        onArrived: () =>
            ref.read(tripSessionNotifierProvider.notifier).markReached(),
        onCancel: () => showCancelTripSheet(context, ref),
        onMessage: () => context.push(tripChatPath(trip)),
      ),
    );
  }
}
