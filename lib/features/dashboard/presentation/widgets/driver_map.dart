import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_cached_tile_provider.dart';
import 'driver_location_marker.dart';

/// Fallback centre used until the first fix lands (Hyderabad — the launch city
/// used throughout the backend docs' sample payloads).
const LatLng kFallbackMapCenter = LatLng(17.3850, 78.4867);

const double kDefaultMapZoom = 15.0;

/// Full-bleed dark map with the driver puck.
///
/// docs/10_LOCATION.md §3 specifies a charcoal map style. OpenStreetMap raster
/// tiles are light, so they are pushed through a desaturate + invert-ish colour
/// matrix to approximate the dark theme. This is an approximation: a true
/// branded style needs a vector tile provider and an API key, which is a
/// product/backend decision (see the phase doc).
class DriverMap extends StatelessWidget {
  const DriverMap({
    super.key,
    required this.controller,
    required this.position,
    this.onPositionChanged,
    this.onMapReady,
    this.heading,
    this.pulsing = true,
    this.weakSignal = false,
  });

  final MapController controller;

  /// Null before the first fix — the map still renders, centred on
  /// [kFallbackMapCenter], without a driver marker.
  final LatLng? position;

  /// Reports camera movement so the parent can distinguish a user's gesture
  /// from a programmatic recenter.
  final PositionCallback? onPositionChanged;
  final VoidCallback? onMapReady;

  final double? heading;
  final bool pulsing;
  final bool weakSignal;

  /// Desaturate, darken and lift the black point so OSM tiles sit against
  /// [AppColors.background] without glowing.
  static const List<double> _darkMatrix = <double>[
    -0.68, -0.24, -0.08, 0, 232, //
    -0.20, -0.72, -0.08, 0, 232, //
    -0.20, -0.24, -0.56, 0, 232, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    final center = position ?? kFallbackMapCenter;

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: kDefaultMapZoom,
        backgroundColor: AppColors.background,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: onPositionChanged,
        onMapReady: onMapReady,
      ),
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(_darkMatrix),
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // Must match the real applicationId — the OSM tile usage policy
            // requires an identifying User-Agent.
            userAgentPackageName: 'com.saaradhigo.saaradhigo_driver',
            tileUpdateTransformer: TileUpdateTransformers.throttle(
              const Duration(milliseconds: 100),
            ),
            tileProvider: AppCachedTileProvider(),
          ),
        ),
        if (position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: position!,
                width: DriverLocationMarker.size,
                height: DriverLocationMarker.size,
                child: DriverLocationMarker(
                  heading: heading,
                  pulsing: pulsing,
                  weakSignal: weakSignal,
                ),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
