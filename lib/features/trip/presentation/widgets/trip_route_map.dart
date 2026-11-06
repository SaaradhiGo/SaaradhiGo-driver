import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/route_providers.dart';

import '../../../../ui/sg_tokens.dart';
import '../../../../core/maps/sg_map.dart';
import '../../../dashboard/presentation/widgets/driver_map.dart'
    show kFallbackMapCenter;

/// Dark route map for the active-trip screens: driver, pickup and destination
/// markers with the ROAD between them.
///
/// Google Maps with the SaaradhiGo dark style, like the dashboard [DriverMap]. Still an
/// overview map, not turn-by-turn navigation — navigation is handed to the
/// device's own map app.
///
/// It used to draw a straight great-circle line, because real routing needed
/// "a directions provider + API key, a product/backend decision". That
/// decision has since been made: Routes API is enabled and the backend
/// proxies it at `/ride/maps/directions`, caching each answer and keeping the
/// key server-side. So the line is now the actual road.
///
/// Which leg is drawn follows what the screen passes: the pickup screen gives
/// driver + pickup, so the driver sees the road to the passenger; the active
/// trip gives pickup + destination. If no route comes back, NO line is drawn.
/// A straight line between two points looks like a road that isn't there, and
/// this app does not draw roads that do not exist.
class TripRouteMap extends ConsumerWidget {
  const TripRouteMap({
    super.key,
    this.driver,
    this.pickup,
    this.destination,
    this.focus,
    this.padding = EdgeInsets.zero,
  });

  /// Room the sheet and top buttons take, so pins are never under them.
  final EdgeInsets padding;

  final LatLng? driver;
  final LatLng? pickup;
  final LatLng? destination;

  /// Point the camera should centre on (defaults to pickup, then destination,
  /// then the driver, then the city fallback).
  final LatLng? focus;

  /// The leg worth drawing for what this screen was given.
  ///
  /// Destination wins when there is one -- that is the active trip. Otherwise
  /// driver -> pickup, which is the leg the driver is actually travelling
  /// before collection.
  RouteLeg? _leg() {
    if (pickup != null && destination != null) {
      return RouteLeg(pickup!, destination!);
    }
    if (driver != null && pickup != null) return RouteLeg(driver!, pickup!);
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center =
        focus ?? pickup ?? destination ?? driver ?? kFallbackMapCenter;

    // Watching a leg-keyed provider means a GPS frame that does not move the
    // driver ~110 m resolves to the same leg and no request is made.
    final leg = _leg();
    final road = leg == null
        ? const <LatLng>[]
        : ref.watch(routeForLegProvider(leg)).maybeWhen(
              data: (points) => points,
              orElse: () => const <LatLng>[],
            );

    final markers = <SgMarker>[
      if (driver != null)
        _pin('driver', driver!, Icons.navigation_rounded, SgColors.gold500),
      if (pickup != null)
        _pin('pickup', pickup!, Icons.circle, SgColors.pickup),
      if (destination != null)
        _pin('drop', destination!, Icons.square_rounded, SgColors.gold500),
    ];

    return SgMap(
      initialCenter: center,
      initialZoom: 14,
      padding: padding,
      markers: markers,
      // Only a real road. While the lookup is in flight, or if it failed,
      // the map shows markers and nothing between them.
      polylines: [
        if (road.length > 1)
          SgPolyline(
            id: 'road',
            points: road,
            color: SgColors.gold500.withValues(alpha: 0.85),
          ),
      ],
    );
  }

  SgMarker _pin(String id, LatLng point, IconData icon, Color color) {
    return SgMarker(
      id: id,
      point: point,
      icon: SgIconMarker(icon, color, size: 32),
      anchor: const Offset(0.5, 0.5),
    );
  }
}
