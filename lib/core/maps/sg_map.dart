/// The one map every screen uses (owner decision D1, 2026-11-02).
///
/// Screens describe WHAT is on the map -- markers, a route, where the camera
/// should be -- in the app's own types (`latlong2` coordinates). The
/// [MapsProvider] decides how a vendor draws it. Google Maps is the provider
/// today, matching the website; the CARTO/OpenStreetMap tiles the app used
/// before are gone (their usage policy does not allow an app like this, and
/// the driver app pushed OpenStreetMap's light tiles through a colour matrix).
///
/// Nothing here imports a vendor SDK, so swapping the provider is one file.
library;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/sg_tokens.dart';
import 'google_maps_provider.dart';
import 'maps_availability.dart';
import 'placeholder_maps_provider.dart';

/// How a marker looks. Rasterised once per look and cached by the provider.
@immutable
sealed class SgMarkerIcon {
  const SgMarkerIcon(this.size);

  /// Logical pixels, square.
  final double size;

  /// A cache key: two icons with the same key draw the same bitmap.
  String get key;
}

/// A Material icon in one colour: the driver, the pickup, the drop.
class SgIconMarker extends SgMarkerIcon {
  const SgIconMarker(this.icon, this.color, {double size = 32}) : super(size);
  final IconData icon;
  final Color color;
  @override
  String get key => 'icon:${icon.codePoint}:${color.toARGB32()}@$size';
}

/// The journey's two ends, drawn (not an icon font): the pickup a filled
/// circle in a white ring, the drop a square with a centre (light: ink with a
/// marigold centre; dark: gold, as built).
class SgJourneyMarker extends SgMarkerIcon {
  const SgJourneyMarker.pickup(this.fill, {double size = 24})
    : drop = false,
      centre = null,
      super(size);

  const SgJourneyMarker.drop(this.fill, {this.centre, double size = 24})
    : drop = true,
      super(size);

  final bool drop;
  final Color fill;

  /// The drop square's centre; none for a plain square.
  final Color? centre;

  @override
  String get key =>
      'journey:${drop ? 'drop' : 'pickup'}:${fill.toARGB32()}:'
      '${centre?.toARGB32()}@$size';

  /// Paints the marker centred on [c], [size] logical pixels across.
  void paint(Canvas canvas, Offset c, double size) {
    if (!drop) {
      canvas.drawCircle(c, size / 2, Paint()..color = SgColors.white);
      canvas.drawCircle(c, size / 2 - size * 0.16, Paint()..color = fill);
      return;
    }
    final outer = Rect.fromCenter(center: c, width: size, height: size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, Radius.circular(size * 0.18)),
      Paint()..color = fill,
    );
    final inner = centre;
    if (inner != null) {
      canvas.drawRect(
        Rect.fromCenter(center: c, width: size * 0.4, height: size * 0.4),
        Paint()..color = inner,
      );
    }
  }
}

/// The pickup: a pickup-green circle in a white ring.
SgJourneyMarker sgPickupMarker({double size = 24}) =>
    SgJourneyMarker.pickup(SgColors.pickup, size: size);

/// The drop: light, an ink square with a marigold centre; dark, the gold
/// square as built.
SgJourneyMarker sgDropMarker({double size = 24}) => SgColors.isDark
    ? SgJourneyMarker.drop(SgColors.gold500, size: size)
    : SgJourneyMarker.drop(SgColors.ink, centre: SgColors.gold500, size: size);

/// The route: light, a 5 px ink line; dark, the gold line as built.
SgPolyline sgRoute(String id, List<LatLng> points) => SgColors.isDark
    ? SgPolyline(
        id: id,
        points: points,
        color: SgColors.gold500.withValues(alpha: 0.85),
      )
    : SgPolyline(id: id, points: points, color: SgColors.ink, width: 5);

@immutable
class SgMarker {
  const SgMarker({
    required this.id,
    required this.point,
    required this.icon,
    this.anchor = const Offset(0.5, 1.0),
    this.rotation = 0,
    this.label,
  });

  final String id;
  final LatLng point;
  final SgMarkerIcon icon;

  /// Which point of the icon sits on [point]: (0.5, 1.0) is the bottom
  /// centre, right for a pin; (0.5, 0.5) for a car seen from above.
  final Offset anchor;
  final double rotation;

  /// Read by screen readers where the provider supports it.
  final String? label;
}

@immutable
class SgPolyline {
  const SgPolyline({
    required this.id,
    required this.points,
    required this.color,
    this.width = 4,
  });

  final String id;
  final List<LatLng> points;
  final Color color;
  final double width;
}

/// Moves the camera. Handed to the screen through [SgMap.onMapCreated].
abstract class SgMapController {
  Future<void> moveTo(LatLng center, {double? zoom});

  /// Shows every point, with [padding] kept clear (for a sheet or a header).
  Future<void> fitPoints(List<LatLng> points, {EdgeInsets padding});
}

/// Where the camera is, reported while it moves.
@immutable
class SgCamera {
  const SgCamera(this.center, this.zoom, {this.byGesture = false});
  final LatLng center;
  final double zoom;
  final bool byGesture;
}

/// The vendor seam. One implementation per maps vendor.
abstract class MapsProvider {
  const MapsProvider();

  Widget build(SgMap map);
}

/// The provider the app uses. Google Maps (D1).
const MapsProvider kMapsProvider = GoogleMapsProvider();

/// Google when the build has a key, else the branded placeholder.
MapsProvider mapsProviderFor({required bool hasKey}) =>
    hasKey ? kMapsProvider : const PlaceholderMapsProvider();

class SgMap extends StatelessWidget {
  const SgMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14,
    this.markers = const [],
    this.polylines = const [],
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.padding = EdgeInsets.zero,
    this.interactive = true,
    this.showMyLocation = false,
    this.provider,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final List<SgMarker> markers;
  final List<SgPolyline> polylines;
  final ValueChanged<SgMapController>? onMapCreated;
  final ValueChanged<SgCamera>? onCameraMove;
  final VoidCallback? onCameraIdle;

  /// Map UI (logo, attribution) is kept clear of this, e.g. a bottom sheet.
  final EdgeInsets padding;
  final bool interactive;
  final bool showMyLocation;

  /// Test seam; production picks Google or the placeholder by key.
  final MapsProvider? provider;

  @override
  Widget build(BuildContext context) {
    final fixed = provider;
    if (fixed != null) return fixed.build(this);
    MapsAvailability.ensureResolved();
    return ValueListenableBuilder<bool>(
      valueListenable: MapsAvailability.hasKey,
      builder: (_, hasKey, _) => mapsProviderFor(hasKey: hasKey).build(this),
    );
  }
}
