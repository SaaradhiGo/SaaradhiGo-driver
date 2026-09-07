import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
  late final MapController _mapController;

  static const List<double> _darkMatrix = <double>[
    -0.68, -0.24, -0.08, 0, 232, //
    -0.20, -0.72, -0.08, 0, 232, //
    -0.20, -0.24, -0.56, 0, 232, //
    0, 0, 0, 1, 0, //
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

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
    final pickup = _pickupPoint;
    final dest = _destinationPoint;

    if (pickup != null && dest != null) {
      final bounds = LatLngBounds.fromPoints([pickup, dest]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(AppSpacing.xl),
        ),
      );
    } else if (pickup != null) {
      _mapController.move(pickup, 15);
    } else if (dest != null) {
      _mapController.move(dest, 15);
    } else {
      _mapController.move(kFallbackMapCenter, 14);
    }
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceContainer,
            title: Text(
              'Route Map',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.onBackground),
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
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final markers = <Marker>[
      if (pickup != null)
        Marker(
          point: pickup,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      if (dest != null)
        Marker(
          point: dest,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: const Icon(
              Icons.location_on,
              size: 20,
              color: AppColors.background,
            ),
          ),
        ),
    ];

    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14,
              backgroundColor: AppColors.background,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                if (pickup != null && dest != null) {
                  _recenter();
                }
              },
            ),
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(_darkMatrix),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.saaradhigo.saaradhigo_driver',
                  tileProvider: NetworkTileProvider(),
                ),
              ),
              if (pickup != null && dest != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [pickup, dest],
                      strokeWidth: 4,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
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
                  foregroundColor: AppColors.primary,
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
