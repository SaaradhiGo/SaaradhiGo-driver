import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/maps/sg_map.dart';
import '../../../../core/theme/app_colors.dart';

/// Fallback centre used until the first fix lands (Hyderabad — the launch city
/// used throughout the backend docs' sample payloads).
const LatLng kFallbackMapCenter = LatLng(17.3850, 78.4867);

const double kDefaultMapZoom = 15.0;

/// Full-bleed dark map with the driver marker.
///
/// Google Maps with the SaaradhiGo dark style (owner decision D1). It used to
/// push OpenStreetMap's light raster tiles through a colour matrix to fake a
/// dark map, which the OSM tile usage policy does not allow for an app like
/// this.
///
/// The marker points along [heading] (a flat, rotated navigation arrow) and
/// greys out while the fix is stale. Google Maps draws markers as bitmaps, so
/// the animated pulse ring the old widget had is not carried over.
class DriverMap extends StatelessWidget {
  const DriverMap({
    super.key,
    required this.position,
    this.onMapCreated,
    this.onCameraMove,
    this.heading,
    this.pulsing = true,
    this.weakSignal = false,
  });

  /// Null before the first fix — the map still renders, centred on
  /// [kFallbackMapCenter], without a driver marker.
  final LatLng? position;

  final ValueChanged<SgMapController>? onMapCreated;

  /// Reports camera movement so the parent can tell a driver's gesture from
  /// a programmatic recentre.
  final ValueChanged<SgCamera>? onCameraMove;

  final double? heading;
  final bool pulsing;
  final bool weakSignal;

  @override
  Widget build(BuildContext context) {
    final h = heading;
    final pointing = h != null && h.isFinite && h >= 0;
    return SgMap(
      initialCenter: position ?? kFallbackMapCenter,
      initialZoom: kDefaultMapZoom,
      onMapCreated: onMapCreated,
      onCameraMove: onCameraMove,
      markers: [
        if (position != null)
          SgMarker(
            id: 'me',
            point: position!,
            icon: SgIconMarker(
              pointing ? Icons.navigation_rounded : Icons.circle,
              weakSignal ? AppColors.outline : AppColors.primary,
              size: pointing ? 36 : 20,
            ),
            anchor: const Offset(0.5, 0.5),
            rotation: pointing ? h : 0,
            label: 'You',
          ),
      ],
    );
  }
}
