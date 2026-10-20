import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/route_providers.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_cached_tile_provider.dart';
import '../../../dashboard/presentation/widgets/driver_map.dart'
    show kFallbackMapCenter;

/// Dark route map for the active-trip screens: driver, pickup and destination
/// markers with the ROAD between them.
///
/// Shares the charcoal tile treatment of the dashboard [DriverMap]. Still an
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
  });

  final LatLng? driver;
  final LatLng? pickup;
  final LatLng? destination;

  /// Point the camera should centre on (defaults to pickup, then destination,
  /// then the driver, then the city fallback).
  final LatLng? focus;

  static const List<double> _darkMatrix = <double>[
    -0.68, -0.24, -0.08, 0, 232, //
    -0.20, -0.72, -0.08, 0, 232, //
    -0.20, -0.24, -0.56, 0, 232, //
    0, 0, 0, 1, 0, //
  ];

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

    final markers = <Marker>[
      if (driver != null)
        _pin(driver!, Icons.navigation_rounded, AppColors.primary),
      if (pickup != null)
        _pin(pickup!, Icons.my_location_rounded, AppColors.primaryContainer),
      if (destination != null)
        _pin(destination!, Icons.location_on_rounded, AppColors.error),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        backgroundColor: AppColors.background,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(_darkMatrix),
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.saaradhigo.saaradhigo_driver',
            tileUpdateTransformer: TileUpdateTransformers.throttle(
              const Duration(milliseconds: 100),
            ),
            tileProvider: AppCachedTileProvider(),
          ),
        ),
        // Only a real road. While the lookup is in flight, or if it failed,
        // the map shows markers and nothing between them.
        if (road.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: road,
                strokeWidth: 4,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _pin(LatLng point, IconData icon, Color color) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: Icon(icon, color: color, size: 32),
    );
  }
}
