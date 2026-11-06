import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/maps/sg_map.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';
import '../../../dashboard/presentation/widgets/driver_map.dart'
    show kFallbackMapCenter;

class TripRouteMiniMap extends StatefulWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;

  const TripRouteMiniMap({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  State<TripRouteMiniMap> createState() => _TripRouteMiniMapState();
}

class _TripRouteMiniMapState extends State<TripRouteMiniMap> {
  SgMapController? _mapController;

  LatLng? get _pickupPoint {
    if (widget.pickupLat != null && widget.pickupLng != null) {
      return LatLng(widget.pickupLat!, widget.pickupLng!);
    }
    return null;
  }

  LatLng? get _destinationPoint {
    if (widget.destinationLat != null && widget.destinationLng != null) {
      return LatLng(widget.destinationLat!, widget.destinationLng!);
    }
    return null;
  }

  LatLng get _initialCenter {
    return _pickupPoint ?? _destinationPoint ?? kFallbackMapCenter;
  }

  void _recenter() {
    final points = [?_pickupPoint, ?_destinationPoint];
    if (points.isEmpty) {
      _mapController?.moveTo(kFallbackMapCenter, zoom: 14);
    } else {
      _mapController?.fitPoints(
        points,
        padding: const EdgeInsets.all(AppSpacing.xl),
      );
    }
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Route Map',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.close, color: AppColors.onBackground),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: TripRouteMiniMap(
            pickupLat: widget.pickupLat,
            pickupLng: widget.pickupLng,
            destinationLat: widget.destinationLat,
            destinationLng: widget.destinationLng,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickupPoint;
    final dest = _destinationPoint;

    // Graceful fallback if coordinates are completely absent
    if (pickup == null && dest == null) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: AppColors.outlineVariant.withValues(alpha: 0.8),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Route coordinates unavailable for this archived trip',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: SgText.size(13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final markers = <SgMarker>[
      if (pickup != null)
        SgMarker(
          id: 'pickup',
          point: pickup,
          icon: SgIconMarker(Icons.trip_origin, AppColors.primary, size: 28),
          anchor: const Offset(0.5, 0.5),
          label: 'Pickup',
        ),
      if (dest != null)
        SgMarker(
          id: 'drop',
          point: dest,
          icon: SgIconMarker(
            Icons.location_on,
            AppColors.primaryContainer,
            size: 32,
          ),
          label: 'Drop',
        ),
    ];

    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          SgMap(
            initialCenter: _initialCenter,
            initialZoom: 14,
            markers: markers,
            polylines: [
              if (pickup != null && dest != null)
                SgPolyline(
                  id: 'line',
                  points: [pickup, dest],
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
            ],
            onMapCreated: (c) {
              _mapController = c;
              if (pickup != null && dest != null) _recenter();
            },
          ),
          // Floating Controls: Recenter & Fullscreen
          Positioned(
            right: AppSpacing.margin,
            bottom: AppSpacing.md,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_expand_${pickup?.latitude}_${dest?.latitude}',
                  backgroundColor: AppColors.surfaceContainer.withValues(
                    alpha: 0.9,
                  ),
                  foregroundColor: AppColors.onBackground,
                  elevation: 2,
                  onPressed: () => _openFullscreen(context),
                  child: const Icon(Icons.fullscreen, size: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton.small(
                  heroTag: 'map_recenter_${pickup?.latitude}_${dest?.latitude}',
                  backgroundColor: AppColors.surfaceContainer.withValues(
                    alpha: 0.9,
                  ),
                  foregroundColor: AppColors.primaryText,
                  elevation: 2,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
