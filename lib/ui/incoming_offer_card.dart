/// The ride offer as a full-height card over the map: fare, route, a visible
/// accept countdown, one gold Accept and a quiet Decline.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../core/maps/sg_map.dart';
import '../core/market/market_config_store.dart';
import '../domain/models/trip_model.dart';
import 'driver_home_view.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';

/// What the card shows, read from a `ride_request` frame.
///
/// Fields the frame does not carry are null and their line is left out; the
/// card never invents a figure.
class OfferData {
  const OfferData({
    this.fare,
    this.className,
    this.payment,
    this.pickupAway,
    this.pickupAddress,
    this.destinationAddress,
    this.tripLine,
    this.pickup,
    this.destination,
    this.expiresAt,
  });

  final String? fare;
  final String? className;
  final String? payment;

  /// "1.2 km · 4 min away".
  final String? pickupAway;
  final String? pickupAddress;
  final String? destinationAddress;

  /// "8.4 km · 20 min".
  final String? tripLine;
  final LatLng? pickup;
  final LatLng? destination;
  final DateTime? expiresAt;

  factory OfferData.fromPayload(Map<String, dynamic> p) {
    TripModel? trip;
    try {
      trip = TripModel.fromJson({...p, 'trip_id': p['trip_id'] ?? 0});
    } catch (_) {}
    final market = MarketConfigStore.instance.current;

    num? number(List<String> keys) {
      for (final k in keys) {
        final v = p[k];
        if (v is num) return v;
        final parsed = num.tryParse('${v ?? ''}');
        if (parsed != null) return parsed;
      }
      return null;
    }

    String? text(List<String> keys) {
      for (final k in keys) {
        final v = p[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final awayKm = number(['pickup_distance_km', 'distance_to_pickup_km']);
    final awayMin = number([
      'pickup_eta_min',
      'eta_to_pickup_min',
      'pickup_eta_minutes',
    ]);
    final away = [
      if (awayKm != null) market.formatDistanceKm(awayKm.toDouble()),
      if (awayMin != null) '${awayMin.round()} min',
    ];

    final km = trip?.distanceKm;
    final min = trip?.durationMin;
    final tripBits = [
      if (km != null) market.formatDistanceKm(km),
      if (min != null) '${min.round()} min',
    ];

    final pay = (trip?.paymentMethod ?? text(['payment_mode']))
        ?.trim()
        .toLowerCase();
    final klass = trip?.vehicleType ?? text(['ride_class', 'vehicle_class']);

    LatLng? point(double? lat, double? lng) =>
        lat == null || lng == null ? null : LatLng(lat, lng);

    return OfferData(
      fare: wholeMoney(trip?.estimatedFare ?? text(['estimated_fare', 'fare'])),
      className: klass == null || klass.isEmpty
          ? null
          : '${klass[0].toUpperCase()}${klass.substring(1)}',
      payment: pay == null || pay.isEmpty
          ? null
          : (pay == 'cash' ? 'Cash' : 'Online'),
      pickupAway: away.isEmpty ? null : '${away.join(' · ')} away',
      pickupAddress: trip?.pickupAddress ?? text(['pickup_address']),
      destinationAddress:
          trip?.destinationAddress ?? text(['destination_address']),
      tripLine: tripBits.isEmpty ? null : tripBits.join(' · '),
      pickup: point(trip?.pickupLat, trip?.pickupLng),
      destination: point(trip?.destinationLat, trip?.destinationLng),
      expiresAt: DateTime.tryParse(text(['expires_at']) ?? '')?.toLocal(),
    );
  }
}

class IncomingOfferCard extends StatefulWidget {
  const IncomingOfferCard({
    super.key,
    required this.payload,
    required this.onAccept,
    required this.onDecline,
    required this.onExpired,
    this.timeoutSeconds = 20,
    this.mapProvider,
    this.alert = true,
  });

  final Map<String, dynamic> payload;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Called a moment after the countdown ends, once "Offer expired" has shown.
  final VoidCallback onExpired;

  /// The UI countdown when the frame carries no `expires_at`.
  final int timeoutSeconds;
  final MapsProvider? mapProvider;

  /// Sound and vibration on arrival; off in tests.
  final bool alert;

  @override
  State<IncomingOfferCard> createState() => _IncomingOfferCardState();
}

class _IncomingOfferCardState extends State<IncomingOfferCard> {
  late final OfferData _offer = OfferData.fromPayload(widget.payload);
  late final int _total;
  late int _remaining;
  Timer? _timer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    final until = _offer.expiresAt?.difference(DateTime.now()).inSeconds;
    _total = math.max(1, until ?? widget.timeoutSeconds);
    _remaining = _total;
    if (widget.alert) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _expired = true;
        });
        _timer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) widget.onExpired();
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = _offer;
    final pickup = o.pickup, drop = o.destination;
    final pins = [
      if (pickup != null)
        SgMarker(
          id: 'pickup',
          point: pickup,
          icon: const SgIconMarker(Icons.circle, SgColors.pickup, size: 20),
          anchor: const Offset(0.5, 0.5),
          label: 'Pickup',
        ),
      if (drop != null)
        SgMarker(
          id: 'drop',
          point: drop,
          icon: const SgIconMarker(
            Icons.square_rounded,
            SgColors.gold500,
            size: 20,
          ),
          anchor: const Offset(0.5, 0.5),
          label: 'Drop',
        ),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: SgColors.bg000,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: SgMap(
              provider: widget.mapProvider,
              initialCenter: pickup ?? const LatLng(17.385, 78.4867),
              initialZoom: 14,
              interactive: false,
              markers: pins,
              padding: const EdgeInsets.only(top: 40, bottom: 40),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: SgColors.bg100,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(SgRadius.lg)),
              border: Border(top: BorderSide(color: SgColors.goldLine)),
            ),
            padding: EdgeInsets.fromLTRB(
              SgSpace.s4,
              SgSpace.s5,
              SgSpace.s4,
              SgSpace.s4 + bottom,
            ),
            child: _expired ? _expiredBody() : _body(o),
          ),
        ],
      ),
    );
  }

  Widget _expiredBody() => SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Offer expired',
            style: SgText.title.copyWith(color: SgColors.inkMuted),
          ),
        ),
      );

  Widget _body(OfferData o) {
    final meta = [if (o.className != null) o.className!, if (o.payment != null) o.payment!];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.fare ?? '–',
                    style: SgText.heading.copyWith(
                      fontSize: 44,
                      height: 48 / 44,
                      fontWeight: FontWeight.w800,
                      fontVariations: const [FontVariation('wght', 800)],
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Text(meta.join(' · '), style: SgText.body),
                  if (o.pickupAway != null) ...[
                    const SizedBox(height: SgSpace.s1),
                    Text(
                      o.pickupAway!,
                      style: SgText.body.copyWith(color: SgColors.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
            _CountdownRing(remaining: _remaining, total: _total),
          ],
        ),
        const SizedBox(height: SgSpace.s5),
        _RouteRow(
          marker: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SgColors.pickup,
            ),
          ),
          label: 'Pickup',
          address: o.pickupAddress ?? 'Pickup location',
        ),
        const SizedBox(height: SgSpace.s4),
        _RouteRow(
          marker: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: SgColors.gold500,
            ),
          ),
          label: 'Drop',
          address: o.destinationAddress ?? 'Destination',
          detail: o.tripLine,
        ),
        const SizedBox(height: SgSpace.s5),
        SgPrimaryButton(label: 'Accept', onPressed: widget.onAccept),
        const SizedBox(height: SgSpace.s2),
        InkWell(
          onTap: widget.onDecline,
          borderRadius: BorderRadius.circular(SgRadius.md),
          child: Container(
            height: kSgTouch,
            alignment: Alignment.center,
            child: Text(
              'Decline',
              style: SgText.body.copyWith(
                color: SgColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.marker,
    required this.label,
    required this.address,
    this.detail,
  });

  final Widget marker;
  final String label;
  final String address;
  final String? detail;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18, right: SgSpace.s3),
            child: marker,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: SgText.label),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SgText.bodyLg,
                ),
                if (detail != null)
                  Text(detail!, style: SgText.caption),
              ],
            ),
          ),
        ],
      );
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$remaining seconds left to accept',
        child: SizedBox(
          width: 64,
          height: 64,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: remaining / total),
            duration: const Duration(seconds: 1),
            builder: (_, value, child) => CustomPaint(
              painter: _RingPainter(value),
              child: child,
            ),
            child: Center(
              child: Text(
                '$remaining',
                style: SgText.title.copyWith(fontSize: 22),
              ),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = SgColors.bg300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = SgColors.gold500
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
