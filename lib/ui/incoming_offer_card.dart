/// The ride offer (signed-in designs, 2026-11-08): the map with the pickup and
/// drop, and a white sheet with the class and distance to pickup, a countdown
/// ring, the pickup and drop, Trip fare / Commission / You earn (each only
/// when the API sent it), Decline and Accept.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/market/market_config_store.dart';
import '../core/notifications/offer_alert.dart';
import '../core/maps/sg_map.dart';
import '../domain/models/trip_model.dart';
import 'driver_home_view.dart';
import 'sg_l10n.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';

/// An address split for a glance: the part before the first comma (the area)
/// and the rest, or null when there is no rest. No geocoding.
(String, String?) splitArea(String address) {
  final t = address.trim();
  final at = t.indexOf(',');
  if (at <= 0) return (t, null);
  final head = t.substring(0, at).trim();
  final rest = t.substring(at + 1).trim();
  return (head, rest.isEmpty ? null : rest);
}

/// "20" for "20.00", "12.5" for "12.50". A rate given as a fraction (0.2) is
/// shown as a percentage (20). Null when it does not parse.
String? percentText(Object? raw) {
  final v = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
  if (v == null || v < 0) return null;
  final pct = v > 0 && v < 1 ? v * 100 : v;
  final fixed = pct.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// What the card shows, read from a `ride_request` frame.
///
/// Fields the frame does not carry are null and their element is left out;
/// the card never invents a figure. The driver's earning is the frame's own
/// `earning` (the backend's figure), never worked out on the phone.
class OfferData {
  const OfferData({
    this.fare,
    this.earning,
    this.commissionPercent,
    this.commissionAmount,
    this.riderRating,
    this.classCode,
    this.className,
    this.cash,
    this.pickupKm,
    this.pickupMin,
    this.tripKm,
    this.tripMin,
    this.pickupAddress,
    this.destinationAddress,
    this.pickup,
    this.destination,
    this.expiresAt,
  });

  /// Whole currency: "₹248".
  final String? fare;

  /// The backend's `earning`, whole currency. Null when the frame has none.
  final String? earning;

  /// "20" from `commission_rate`.
  final String? commissionPercent;

  /// Whole currency from `commission_amount`.
  final String? commissionAmount;
  final double? riderRating;
  final String? classCode;
  final String? className;

  /// True for cash, false for paid in the app, null when unknown.
  final bool? cash;
  final double? pickupKm;
  final double? pickupMin;
  final double? tripKm;
  final double? tripMin;
  final String? pickupAddress;
  final String? destinationAddress;
  final LatLng? pickup;
  final LatLng? destination;
  final DateTime? expiresAt;

  /// The "Fare ₹X − Y% commission ₹Z" line is shown only when every part of
  /// it came from the frame.
  bool get hasFareLine =>
      earning != null &&
      fare != null &&
      commissionPercent != null &&
      commissionAmount != null;

  factory OfferData.fromPayload(Map<String, dynamic> p) {
    TripModel? trip;
    try {
      trip = TripModel.fromJson({...p, 'trip_id': p['trip_id'] ?? 0});
    } catch (_) {}

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

    final pay = (trip?.paymentMethod ?? text(['payment_mode']))
        ?.trim()
        .toLowerCase();
    final klass = trip?.vehicleType ?? text(['ride_class', 'vehicle_class']);
    final rating = number(['rider_rating'])?.toDouble();
    LatLng? point(double? lat, double? lng) =>
        lat == null || lng == null ? null : LatLng(lat, lng);

    return OfferData(
      fare: wholeMoney(trip?.estimatedFare ?? text(['estimated_fare', 'fare'])),
      earning: wholeMoney(text(['earning'])),
      commissionPercent: percentText(p['commission_rate']),
      commissionAmount: wholeMoney(text(['commission_amount'])),
      riderRating: rating != null && rating > 0 ? rating : null,
      classCode: klass,
      className: klass == null || klass.isEmpty
          ? null
          : '${klass[0].toUpperCase()}${klass.substring(1)}',
      cash: pay == null || pay.isEmpty ? null : pay == 'cash',
      pickupKm: number([
        'pickup_distance_km',
        'distance_to_pickup_km',
      ])?.toDouble(),
      pickupMin: number([
        'pickup_eta_min',
        'eta_to_pickup_min',
        'pickup_eta_minutes',
      ])?.toDouble(),
      tripKm: trip?.distanceKm,
      tripMin: trip?.durationMin,
      pickupAddress: trip?.pickupAddress ?? text(['pickup_address']),
      destinationAddress:
          trip?.destinationAddress ?? text(['destination_address']),
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
    this.commissionRate,
    this.topAction,
  });

  /// The commission rate as the earnings API reports it ("15%"), shown when
  /// the frame carries no commission amount of its own.
  final String? commissionRate;

  /// Top right over the map: the SOS button.
  final Widget? topAction;

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
      // Sound and vibration as the phone's ringer and silent mode allow.
      unawaited(const OfferAlert().play());
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
    final l = sgL10n(context);
    // The modal sheet this sits in drops the top inset from MediaQuery, so
    // read the window's own: the top row must clear the status bar.
    final media = MediaQuery.paddingOf(context);
    final view = MediaQueryData.fromView(View.of(context)).padding;
    final top = media.top > view.top ? media.top : view.top;
    final bottom = media.bottom > view.bottom ? media.bottom : view.bottom;
    final tablet = SgText.sizeClass == SgSizeClass.tablet;
    final sheet = Container(
      key: const Key('offer_sheet'),
      decoration: BoxDecoration(
        color: SgColors.bg100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: SgColors.shadow,
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + (tablet ? 0 : bottom)),
      child: _expired
          ? SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  l.offerExpired,
                  textAlign: TextAlign.center,
                  style: SgText.title.copyWith(color: SgColors.inkMuted),
                ),
              ),
            )
          : _body(l, _offer),
    );
    final content = Stack(
      children: [
        Positioned.fill(
          child: _MiniMap(offer: _offer, provider: widget.mapProvider),
        ),
        Positioned(
          top: top + SgSpace.s4,
          left: SgSpace.s4,
          right: SgSpace.s4,
          child: Row(
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: SgStatus.okBg,
                  borderRadius: BorderRadius.circular(SgRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: SgColors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SgStatus.okInk,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.statusOnline,
                      style: SgText.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SgStatus.okInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ?widget.topAction,
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            key: const Key('offer_scroll'),
            child: sheet,
          ),
        ),
      ],
    );
    return Material(
      color: SgColors.bg000,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: tablet ? 860 : double.infinity,
          ),
          child: tablet
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    SgSpace.s5,
                    SgSpace.s5,
                    SgSpace.s5,
                    SgSpace.s5 + bottom,
                  ),
                  child: DecoratedBox(
                    key: const Key('offer_tablet_card'),
                    decoration: BoxDecoration(
                      color: SgColors.bg100,
                      borderRadius: BorderRadius.circular(SgRadius.xl),
                      border: Border.all(color: SgColors.line),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SgRadius.xl),
                      child: content,
                    ),
                  ),
                )
              : content,
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l, OfferData o) {
    final market = MarketConfigStore.instance.current;
    final pickupDistance = o.pickupKm == null
        ? null
        : market.formatDistanceKm(o.pickupKm!);
    final headline = [
      ?o.className,
      if (pickupDistance != null)
        o.pickupMin == null
            ? l.offerToPickupDistance(pickupDistance)
            : l.offerToPickupDistanceMinutes(
                pickupDistance,
                o.pickupMin!.round().clamp(1, 999),
              ),
    ].join(' · ');
    String place(String label, String? address, String? fallback) {
      final area = address == null ? null : splitArea(address).$1;
      final detail = area ?? fallback;
      return detail == null ? label : '$label · $detail';
    }

    final tripDistance = o.tripKm == null
        ? null
        : l.offerTripDistance(market.formatDistanceKm(o.tripKm!));
    // Commission: the frame's own amount, else the rate the earnings API
    // reports (the fee rule: shown as the API sent it, never computed here).
    final commission = o.commissionAmount != null
        ? '− ${o.commissionAmount}'
        : widget.commissionRate;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.offerNewRequest.toUpperCase(),
                    style: SgText.eyebrow.copyWith(color: SgColors.inkMuted),
                  ),
                  const SizedBox(height: 2),
                  if (headline.isNotEmpty)
                    Text(
                      headline,
                      key: const Key('offer_headline'),
                      style: SgText.title,
                    ),
                ],
              ),
            ),
            _CountdownRing(remaining: _remaining, total: _total),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: SgColors.bg000,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlaceLine(
                drop: false,
                text: place(l.offerPickup, o.pickupAddress, null),
              ),
              const SizedBox(height: SgSpace.s2),
              _PlaceLine(
                drop: true,
                text: place(l.offerDrop, o.destinationAddress, tripDistance),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (o.fare != null)
          _FareRow(
            key: const Key('offer_fare_row'),
            label: l.offerTripFare,
            value: o.fare!,
            valueKey: o.earning == null ? const Key('offer_amount') : null,
          ),
        if (commission != null) ...[
          const SizedBox(height: 6),
          _FareRow(
            key: const Key('offer_commission_row'),
            label: l.homeCommission,
            value: commission,
            valueColor: SgColors.danger,
          ),
        ],
        if (o.earning != null) ...[
          const SizedBox(height: 6),
          Container(
            key: const Key('offer_earn_row'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SgStatus.okBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.offerYouEarn,
                    style: SgText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SgStatus.okInk,
                    ),
                  ),
                ),
                Text(
                  o.earning!,
                  key: const Key('offer_amount'),
                  style: SgText.title.copyWith(color: SgStatus.okInk),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: l.offerDecline,
                excludeSemantics: true,
                child: Material(
                  color: SgColors.bg100,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: const Key('offer_decline'),
                    onTap: widget.onDecline,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SgColors.line),
                      ),
                      child: Text(
                        l.offerDecline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SgText.button.copyWith(color: SgColors.ink),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Semantics(
                button: true,
                label: l.offerAccept,
                excludeSemantics: true,
                child: Material(
                  color: SgColors.gold500,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: const Key('offer_accept'),
                    onTap: widget.onAccept,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 64,
                      child: Center(
                        child: Text(
                          l.offerAccept,
                          style: SgText.title.copyWith(color: SgColors.onGold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The pickup and drop on the map behind the sheet; plain ground when there
/// is no pickup point.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.offer, this.provider});

  final OfferData offer;
  final MapsProvider? provider;

  @override
  Widget build(BuildContext context) {
    final pickup = offer.pickup;
    if (pickup == null) return ColoredBox(color: SgColors.bg200);
    final drop = offer.destination;
    return SgMap(
      provider: provider,
      initialCenter: pickup,
      initialZoom: 13,
      interactive: false,
      markers: [
        SgMarker(
          id: 'pickup',
          point: pickup,
          icon: SgJourneyMarker.pickup(SgColors.pickup, size: 20),
          anchor: const Offset(0.5, 0.5),
          label: sgL10n(context).offerPickup,
        ),
        if (drop != null)
          SgMarker(
            id: 'drop',
            point: drop,
            icon: sgDropMarker(size: 20),
            anchor: const Offset(0.5, 0.5),
            label: sgL10n(context).offerDrop,
          ),
      ],
      // Keep the pins clear of the sheet that covers the lower half.
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 420),
    );
  }
}

/// 56px ring: amber for the time left, the seconds inside.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    return Semantics(
      liveRegion: true,
      label: l.offerSecondsLeft(remaining),
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('offer_countdown_ring'),
        width: 56,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: (remaining / total).clamp(0.0, 1.0),
              strokeWidth: 5,
              backgroundColor: SgColors.bg200,
              color: remaining <= 5 ? SgColors.danger : SgColors.gold500,
            ),
            Center(
              child: Text(
                '${remaining}s',
                key: const Key('offer_seconds'),
                style: SgText.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.drop, required this.text});

  final bool drop;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: drop ? 10 : 10,
        height: 10,
        decoration: BoxDecoration(
          color: drop ? SgColors.ink : SgColors.pickup,
          shape: drop ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: drop ? BorderRadius.circular(2) : null,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SgText.body,
        ),
      ),
    ],
  );
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
    this.valueColor,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: SgStatus.rowFill,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: SgText.small.copyWith(color: SgColors.ink)),
        ),
        Text(
          value,
          key: valueKey,
          style: SgText.small.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? SgColors.ink,
          ),
        ),
      ],
    ),
  );
}
