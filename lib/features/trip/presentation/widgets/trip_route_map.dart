import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_cached_tile_provider.dart';
import '../../../dashboard/presentation/widgets/driver_map.dart'
    show kFallbackMapCenter;

/// Dark route map for the active-trip screens: driver, pickup and destination
/// markers with a connecting polyline.
///
/// Shares the charcoal tile treatment of the dashboard [DriverMap]. This is a
/// static overview map, not turn-by-turn navigation — real routing needs a
/// directions provider + API key, a product/backend decision (see the phase
/// doc). The polyline is a straight great-circle line between the two points.
class TripRouteMap extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final center =
        focus ?? pickup ?? destination ?? driver ?? kFallbackMapCenter;

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
        if (pickup != null && destination != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [pickup!, destination!],
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
