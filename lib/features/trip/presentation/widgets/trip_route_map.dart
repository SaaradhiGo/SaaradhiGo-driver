import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/polyline_codec.dart';
import '../../../../core/route_follow.dart';
import '../providers/route_providers.dart';

import '../../../../core/theme/app_colors.dart';
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
class TripRouteMap extends ConsumerStatefulWidget {
  const TripRouteMap({
    super.key,
    this.driver,
    this.pickup,
    this.destination,
    this.focus,
    this.plannedPolyline,
  });

  final LatLng? driver;
  final LatLng? pickup;
  final LatLng? destination;

  /// Point the camera should centre on (defaults to pickup, then destination,
  /// then the driver, then the city fallback).
  final LatLng? focus;

  /// Encoded `planned_route_polyline` from the trip details. When present the
  /// trip leg is drawn from it with no Routes request at all.
  final String? plannedPolyline;

  @override
  ConsumerState<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends ConsumerState<TripRouteMap> {
  // The full line as fetched, and what is still ahead of the driver.
  List<LatLng> _line = const [];
  List<LatLng> _ahead = const [];
  DateTime? _lastFetch;
  String? _legKey;
  bool _inFlight = false;

  /// Where the current leg ends: destination on the active trip, else pickup.
  LatLng? get _target => widget.destination ?? widget.pickup;

  /// Identity of the leg, so a new leg (accept -> start) fetches once and a
  /// moving driver never changes it.
  String? _key() {
    final p = widget.pickup, d = widget.destination;
    if (p != null && d != null) return 'trip:$p>$d';
    if (p != null) return 'arrival:$p';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(TripRouteMap old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final key = _key();
    if (key != _legKey) {
      _legKey = key;
      _line = const [];
      _ahead = const [];
      _lastFetch = null;
      final planned = widget.plannedPolyline;
      if (widget.destination != null && planned != null && planned.isNotEmpty) {
        _line = decodePolyline(planned);
        _ahead = _line;
        _lastFetch = DateTime.now();
      } else if (widget.destination != null && widget.pickup != null) {
        _fetch(widget.pickup!);
      } else if (widget.driver != null) {
        _fetch(widget.driver!);
      }
    }
    final driver = widget.driver;
    if (driver == null || _key() == null) return;
    if (_line.length > 1) _ahead = RouteFollow.trim(driver, _line);
    if (!_inFlight &&
        RouteFollow.shouldRefetch(
          driver: driver,
          line: _line,
          lastFetch: _lastFetch,
          now: DateTime.now(),
        )) {
      _fetch(driver);
    }
  }

  Future<void> _fetch(LatLng from) async {
    final to = _target;
    if (to == null) return;
    final key = _legKey;
    _inFlight = true;
    _lastFetch = DateTime.now();
    final points = await ref
        .read(directionsDataSourceProvider)
        .routeBetween(from, to);
    _inFlight = false;
    // Drop the answer if the leg changed or the screen went while it flew.
    if (!mounted || key != _legKey || points.isEmpty) return;
    setState(() {
      _line = points;
      _ahead = widget.driver == null
          ? points
          : RouteFollow.trim(widget.driver!, points);
    });
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final pickup = widget.pickup;
    final destination = widget.destination;
    final center =
        widget.focus ?? pickup ?? destination ?? driver ?? kFallbackMapCenter;

    final markers = <SgMarker>[
      if (driver != null)
        _pin('driver', driver, Icons.navigation_rounded, AppColors.primary),
      if (pickup != null)
        _pin(
          'pickup',
          pickup,
          Icons.my_location_rounded,
          AppColors.primaryContainer,
        ),
      if (destination != null)
        _pin('drop', destination, Icons.location_on_rounded, AppColors.error),
    ];

    return SgMap(
      initialCenter: center,
      initialZoom: 14,
      markers: markers,
      // Only a real road. While the lookup is in flight, or if it failed,
      // the map shows markers and nothing between them.
      polylines: [
        if (_ahead.length > 1)
          SgPolyline(
            id: 'road',
            points: _ahead,
            color: AppColors.primary.withValues(alpha: 0.8),
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
