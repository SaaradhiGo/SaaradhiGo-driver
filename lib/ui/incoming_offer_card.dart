/// The ride offer (Tier 3, screen 2): a full-width countdown bar, the class and
/// the seconds left, "You earn" at 96px from the frame's own `earning`, three
/// tiles (to pickup, trip, rider pays), the pickup and drop areas, an 80px
/// gold Accept and a 52px Decline.
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
import 'driver_trip_views.dart' show kStarIcon;
import 'sg_l10n.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';

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
    // read the window's own: the countdown must clear the status bar.
    final media = MediaQuery.paddingOf(context);
    final view = MediaQueryData.fromView(View.of(context)).padding;
    final pad = EdgeInsets.only(
      top: media.top > view.top ? media.top : view.top,
      bottom: media.bottom > view.bottom ? media.bottom : view.bottom,
    );
    final tablet = SgText.sizeClass == SgSizeClass.tablet;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CountdownBar(remaining: _remaining, total: _total),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SgSpace.s4,
              SgSpace.s4,
              SgSpace.s4,
              SgSpace.s3 + (tablet ? 0 : pad.bottom),
            ),
            child: _expired
                ? Center(
                    child: Text(
                      l.offerExpired,
                      textAlign: TextAlign.center,
                      style: SgText.screenTitle.copyWith(
                        color: SgColors.inkMuted,
                      ),
                    ),
                  )
                : _body(l, _offer),
          ),
        ),
      ],
    );
    return Material(
      color: SgColors.bg000,
      child: Padding(
        padding: EdgeInsets.only(top: pad.top, bottom: tablet ? pad.bottom : 0),
        // Tablets: a centred card, at most 480 wide (owner brief). Phones:
        // the whole screen, still capped at 480 so landscape stays readable.
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: tablet ? 860 : double.infinity,
            ),
            child: tablet
                ? Padding(
                    padding: const EdgeInsets.all(SgSpace.s5),
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
      ),
    );
  }

  Widget _body(AppLocalizations l, OfferData o) {
    final market = MarketConfigStore.instance.current;
    String? km(double? v) => v == null ? null : market.formatDistanceKm(v);
    String? min(double? v) =>
        v == null ? null : l.commonMinutes(v.round().clamp(1, 999));
    final earn = o.earning;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (o.className != null) _ClassChip(o.className!, o.classCode),
            if (o.riderRating != null) ...[
              const SizedBox(width: SgSpace.s2),
              _RatingChip(o.riderRating!, l),
            ],
            const Spacer(),
            Semantics(
              liveRegion: true,
              child: Text(
                l.offerSecondsLeft(_remaining),
                key: const Key('offer_seconds'),
                style: SgText.sectionTitle.copyWith(
                  color: _remaining <= 5 ? SgColors.danger : SgColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SgSpace.s4),
        Text(
          earn != null ? l.offerYouEarn : l.offerFare,
          style: SgText.label.copyWith(color: SgColors.goldText),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: GoldSymbolAmount(
            earn ?? o.fare ?? '–',
            key: const Key('offer_amount'),
            symbolColor: SgColors.goldText,
            style: SgText.driverEarning,
          ),
        ),
        if (o.hasFareLine)
          Text(
            l.offerFareLine(o.fare!, o.commissionPercent!, o.commissionAmount!),
            key: const Key('offer_fare_line'),
            style: SgText.body.copyWith(color: SgColors.inkMuted),
          )
        else if (earn != null && o.fare != null)
          Text(
            '${l.offerFare} ${o.fare}',
            key: const Key('offer_fare_line'),
            style: SgText.body.copyWith(color: SgColors.inkMuted),
          ),
        const SizedBox(height: SgSpace.s4),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  label: l.offerToPickup,
                  value: min(o.pickupMin) ?? km(o.pickupKm),
                  detail: o.pickupMin == null ? null : km(o.pickupKm),
                ),
              ),
              const SizedBox(width: SgSpace.s2),
              Expanded(
                child: _Tile(
                  label: l.offerTrip,
                  value: min(o.tripMin) ?? km(o.tripKm),
                  detail: o.tripMin == null ? null : km(o.tripKm),
                ),
              ),
              const SizedBox(width: SgSpace.s2),
              Expanded(
                child: _Tile(
                  label: l.offerRiderPays,
                  value: o.cash == null
                      ? null
                      : (o.cash! ? l.payCash : l.payOnline),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SgSpace.s4),
        if (o.pickupAddress != null)
          _AreaRow(
            address: o.pickupAddress!,
            drop: false,
            label: l.offerPickup,
          ),
        if (o.pickupAddress != null && o.destinationAddress != null)
          const SizedBox(height: SgSpace.s3),
        if (o.destinationAddress != null)
          _AreaRow(
            address: o.destinationAddress!,
            drop: true,
            label: l.offerDrop,
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            key: const Key('offer_scroll'),
            slivers: [
              SliverToBoxAdapter(child: details),
              SliverLayoutBuilder(
                builder: (context, c) => SliverToBoxAdapter(
                  child: _MiniMap(
                    offer: o,
                    provider: widget.mapProvider,
                    height: c.remainingPaintExtent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SgSpace.s3),
        SgPrimaryButton(
          key: const Key('offer_accept'),
          label: l.offerAccept,
          height: kSgPrimaryAction,
          onPressed: widget.onAccept,
        ),
        Semantics(
          button: true,
          label: l.offerDecline,
          excludeSemantics: true,
          child: InkWell(
            key: const Key('offer_decline'),
            onTap: widget.onDecline,
            borderRadius: BorderRadius.circular(SgRadius.md),
            child: Padding(
              padding: const EdgeInsets.only(top: SgSpace.s2),
              child: Container(
                constraints: const BoxConstraints(minHeight: kSgTouch),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SgRadius.md),
                  border: Border.all(color: SgColors.lineStrong),
                ),
                child: Text(
                  l.offerDecline,
                  textAlign: TextAlign.center,
                  style: SgText.button.copyWith(color: SgColors.inkMuted),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The pickup and drop on a small map in whatever room is left; nothing when
/// there is too little room or no pickup point.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.offer, required this.height, this.provider});

  final OfferData offer;
  final MapsProvider? provider;

  /// The room left under the details; no map under 120 + its padding.
  final double height;

  @override
  Widget build(BuildContext context) {
    final pickup = offer.pickup;
    if (pickup == null || height < 120 + 2 * SgSpace.s4) {
      return const SizedBox.shrink();
    }
    final drop = offer.destination;
    return Builder(
      builder: (context) {
        return Container(
          height: height,
          padding: const EdgeInsets.symmetric(vertical: SgSpace.s4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SgRadius.lg),
            child: SgMap(
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
              padding: const EdgeInsets.all(32),
            ),
          ),
        );
      },
    );
  }
}

class _CountdownBar extends StatelessWidget {
  const _CountdownBar({required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '$remaining',
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('offer_countdown_bar'),
        height: 8,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: remaining / total),
          duration: reduce ? Duration.zero : const Duration(seconds: 1),
          curve: Curves.linear,
          builder: (_, value, _) => Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: SgColors.bg300),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: ColoredBox(
                  color: remaining <= 5 ? SgColors.danger : SgColors.gold500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  const _ClassChip(this.name, this.code);

  final String name;
  final String? code;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: SgSpace.s3),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: SgVehicleClass.tileColorFor(code),
      borderRadius: BorderRadius.circular(SgRadius.pill),
    ),
    child: Text(
      name,
      key: const Key('offer_class'),
      style: SgText.body.copyWith(
        fontWeight: FontWeight.w600,
        color: SgVehicleClass.iconColorFor(code),
      ),
    ),
  );
}

class _RatingChip extends StatelessWidget {
  const _RatingChip(this.rating, this.l);

  final double rating;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final r = rating.toStringAsFixed(1);
    return Semantics(
      label: l.offerRiderRating(r),
      excludeSemantics: true,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: SgSpace.s3),
        decoration: BoxDecoration(
          color: SgColors.bg200,
          borderRadius: BorderRadius.circular(SgRadius.pill),
          border: Border.all(color: SgColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SgIcon(kStarIcon, size: 16, color: SgColors.goldText),
            const SizedBox(width: SgSpace.s1),
            Text(
              r,
              key: const Key('offer_rating'),
              style: SgText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, this.value, this.detail});

  final String label;
  final String? value;
  final String? detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SgSpace.s3),
    decoration: BoxDecoration(
      color: SgColors.bg200,
      borderRadius: BorderRadius.circular(SgRadius.md),
      border: Border.all(color: SgColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          style: SgText.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: SgSpace.s1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value ?? '–', style: SgText.fare),
        ),
        if (detail != null) Text(detail!, maxLines: 1, style: SgText.caption),
      ],
    ),
  );
}

/// The area at 19px with the rest of the address muted under it.
class _AreaRow extends StatelessWidget {
  const _AreaRow({
    required this.address,
    required this.drop,
    required this.label,
  });

  final String address;
  final bool drop;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (area, rest) = splitArea(address);
    return Semantics(
      label: '$label: $address',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: SgSpace.s3),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: drop ? SgColors.gold500 : SgColors.pickup,
                shape: drop ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: drop ? BorderRadius.circular(3) : null,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SgText.sectionTitle,
                ),
                if (rest != null)
                  Text(
                    rest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SgText.caption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
