/// The map drawn when there is no Google Maps key: pure black, a faint street
/// grid in the map-* tokens, the badge, and the app's own route and pins.
/// It makes no claim to be a real map.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../ui/sg_tokens.dart';
import 'sg_map.dart';
import 'package:saaradhigo_driver/ui/sg_brand.dart';

class PlaceholderMapsProvider extends MapsProvider {
  const PlaceholderMapsProvider();

  @override
  Widget build(SgMap map) => _PlaceholderMap(map: map);
}

class _PlaceholderMap extends StatefulWidget {
  const _PlaceholderMap({required this.map});
  final SgMap map;

  @override
  State<_PlaceholderMap> createState() => _PlaceholderMapState();
}

class _PlaceholderMapState extends State<_PlaceholderMap> {
  Offset _pan = Offset.zero;

  LatLng _centerFor(Offset pan) {
    final map = widget.map;
    final c = map.initialCenter;
    final metres = 156543.03392 *
        math.cos(c.latitude * math.pi / 180) /
        math.pow(2, map.initialZoom);
    final dLat = pan.dy * metres / 111320;
    final dLng =
        -pan.dx * metres / (111320 * math.cos(c.latitude * math.pi / 180));
    return LatLng(c.latitude + dLat, c.longitude + dLng);
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.map;
    final canvas = ExcludeSemantics(
      child: Transform.translate(
        offset: _pan,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _GroundPainter()),
            Center(
              child: Opacity(
                opacity: 0.05,
                child: SvgPicture.asset(
                  SgBrandAssets.badgeSmall,
                  width: 190,
                ),
              ),
            ),
            CustomPaint(painter: _OverlayPainter(map)),
          ],
        ),
      ),
    );
    if (!map.interactive ||
        (map.onCameraMove == null && map.onCameraIdle == null)) {
      return canvas;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) {
        setState(() => _pan += d.delta);
        map.onCameraMove?.call(
          SgCamera(_centerFor(_pan), map.initialZoom, byGesture: true),
        );
      },
      onPanEnd: (_) => map.onCameraIdle?.call(),
      child: ClipRect(child: canvas),
    );
  }
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = SgColors.mapGround);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.14);
    canvas.translate(-size.width / 2, -size.height / 2);
    final reach = size.longestSide * 1.4;
    final street = Paint()
      ..color = SgColors.mapStreet
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (var x = -reach; x < reach; x += 44) {
      canvas.drawLine(Offset(x, -reach), Offset(x, reach), street);
    }
    for (var y = -reach; y < reach; y += 52) {
      canvas.drawLine(Offset(-reach, y), Offset(reach, y), street);
    }
    final arterial = Paint()
      ..color = SgColors.mapArterial
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final fy in [0.22, 0.52, 0.8]) {
      final p = Path()
        ..moveTo(-40, size.height * fy)
        ..cubicTo(
          size.width * .3,
          size.height * (fy - .05),
          size.width * .6,
          size.height * (fy + .06),
          size.width + 40,
          size.height * fy,
        );
      canvas.drawPath(p, arterial);
    }
    for (final fx in [0.25, 0.7]) {
      final p = Path()
        ..moveTo(size.width * fx, -40)
        ..cubicTo(
          size.width * (fx + .08),
          size.height * .3,
          size.width * (fx - .08),
          size.height * .65,
          size.width * fx,
          size.height + 40,
        );
      canvas.drawPath(p, arterial);
    }
    final highway = Paint()
      ..color = SgColors.mapArterial
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-40, size.height * .95)
        ..quadraticBezierTo(
          size.width * .45,
          size.height * .3,
          size.width + 40,
          -20,
        ),
      highway,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .55,
          size.height * .6,
          size.width * .3,
          size.height * .09,
        ),
        const Radius.circular(14),
      ),
      Paint()..color = SgColors.mapPark,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .08,
        size.height * .38,
        size.width * .26,
        size.height * .07,
      ),
      Paint()..color = SgColors.mapWater,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroundPainter old) => false;
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter(this.map);
  final SgMap map;

  /// Projects lat/lng into the part of the box the sheet leaves free.
  Offset Function(LatLng) _projector(Size size) {
    if (map.onCameraMove != null) {
      final c = map.initialCenter;
      final k = math.cos(c.latitude * math.pi / 180);
      final perDeg = 111320 / (156543.03392 * k / math.pow(2, map.initialZoom));
      // The visible centre sits above any bottom padding (a sheet).
      final cy = (size.height - map.padding.bottom + map.padding.top) / 2;
      return (p) => Offset(
            size.width / 2 + (p.longitude - c.longitude) * k * perDeg,
            cy - (p.latitude - c.latitude) * perDeg,
          );
    }
    final pad = map.padding;
    final area = Rect.fromLTRB(
      pad.left + 40,
      pad.top + 40,
      size.width - pad.right - 40,
      size.height - pad.bottom - 40,
    );
    final pts = <LatLng>[
      for (final l in map.polylines) ...l.points,
      for (final m in map.markers) m.point,
    ];
    if (pts.length < 2) return (_) => area.center;
    final lat0 =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final k = math.cos(lat0 * math.pi / 180);
    double xOf(LatLng p) => p.longitude * k;
    final minX = pts.map(xOf).reduce(math.min);
    final maxX = pts.map(xOf).reduce(math.max);
    final minY = pts.map((p) => p.latitude).reduce(math.min);
    final maxY = pts.map((p) => p.latitude).reduce(math.max);
    final w = math.max(maxX - minX, 1e-9), h = math.max(maxY - minY, 1e-9);
    final scale = math.min(area.width / w, area.height / h);
    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    return (p) => Offset(
          area.center.dx + (xOf(p) - cx) * scale,
          area.center.dy - (p.latitude - cy) * scale,
        );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final at = _projector(size);
    for (final line in map.polylines) {
      if (line.points.length < 2) continue;
      final path = Path();
      for (var i = 0; i < line.points.length; i++) {
        final o = at(line.points[i]);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = line.width.clamp(4.0, 5.0)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final m in map.markers) {
      _marker(canvas, at(m.point), m);
    }
  }

  /// A circle is the driver or the pickup, a rounded square the drop, any
  /// other icon a heading arrow.
  void _marker(Canvas canvas, Offset c, SgMarker m) {
    final icon = m.icon;
    if (icon is! SgIconMarker) return;
    final color = icon.color;
    if (icon.icon.codePoint == Icons.circle.codePoint) {
      canvas.drawCircle(c, 22, Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawCircle(c, 9, Paint()..color = color);
      canvas.drawCircle(
        c,
        9,
        Paint()
          ..color = SgColors.mapGround
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (icon.icon.codePoint == Icons.square_rounded.codePoint) {
      canvas.drawCircle(c, 22, Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 20, height: 20),
          const Radius.circular(5),
        ),
        Paint()..color = color,
      );
    } else {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(m.rotation * math.pi / 180);
      final arrow = Path()
        ..moveTo(0, -11)
        ..lineTo(8, 9)
        ..lineTo(0, 5)
        ..lineTo(-8, 9)
        ..close();
      canvas.drawPath(arrow, Paint()..color = color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => true;
}
