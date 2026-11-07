/// The driver's trip on the design system (group E): to pickup, the PIN check,
/// the trip in progress, and complete and collect. Pure views: the screens in
/// features/trip own the session and pass in what to show.
library;

import 'package:flutter/material.dart';

import '../core/market/market_config_store.dart';
import 'driver_home_view.dart';
import 'sg_l10n.dart';
import '../l10n/app_localizations.dart' show lookupAppLocalizations;
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';

String firstNameOf(String? full) {
  final t = (full ?? '').trim();
  return t.isEmpty ? '' : t.split(RegExp(r'\s+')).first;
}

String initialsOf(String? full) {
  final parts = (full ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  final b = parts.length > 1 ? parts.last[0] : '';
  return (parts.first[0] + b).toUpperCase();
}

/// The exact amount to collect: "₹150", or "$12.40" when there are cents.
/// Cash is never rounded on screen; INR fares already arrive whole.
String exactMoney(String? raw) {
  final market = MarketConfigStore.instance.current;
  final value =
      double.tryParse(market.stripSymbol(raw ?? '').replaceAll(',', '')) ?? 0;
  if (value == value.roundToDouble()) return wholeMoney('$value') ?? '';
  return '${market.currencySymbol}${value.toStringAsFixed(2)}';
}

/// "8.4 km · 20 min"; null when neither is known.
String? distanceTimeLine(double? km, double? minutes) {
  final parts = [
    if (km != null) '${km.toStringAsFixed(1)} km',
    if (minutes != null) '${minutes.round().clamp(1, 999)} min',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// The payment method as the driver reads it. English when [l] is absent.
String paymentLabel(String? method, [AppLocalizations? l]) {
  final s = l ?? lookupAppLocalizations(const Locale('en'));
  return switch ((method ?? '').toLowerCase()) {
    'cash' => s.payCash,
    'upi' => s.payUpi,
    'card' => s.payCard,
    'wallet' => s.payWallet,
    _ => s.payOnline,
  };
}

/// What the trip sheet and top buttons cover, for the map's padding.
const kTripMapPadding = EdgeInsets.only(top: 90, bottom: 380);

/// Map behind, chat and SOS top right, one sheet at the bottom.
class DriverTripScaffold extends StatelessWidget {
  const DriverTripScaffold({
    super.key,
    required this.map,
    required this.sheet,
    this.topActions,
    this.mapButton,
    this.top,
  });

  final Widget map;
  final Widget sheet;
  final Widget? topActions;
  final Widget? mapButton;

  /// A full-width block at the top (the on-trip banner); [topActions] is
  /// ignored when it is set.
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: Stack(
        children: [
          Positioned.fill(child: map),
          if (top != null)
            Positioned(
              top: pad.top + SgSpace.s3,
              left: SgSpace.s4,
              right: SgSpace.s4,
              child: top!,
            )
          else if (topActions != null)
            Positioned(
              top: pad.top + SgSpace.s3,
              right: SgSpace.s4,
              child: topActions!,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // Never taller than the screen below the top buttons: on a
            // landscape phone or at a large text size the sheet scrolls.
            top: pad.top + kSgTouch + SgSpace.s4,
            child: SgBottomSheetArea(
              mapButton: mapButton,
              child: SgSheetSurface(
                padding: EdgeInsets.fromLTRB(
                  SgSpace.s4,
                  SgSpace.s3,
                  SgSpace.s4,
                  SgSpace.s4 + pad.bottom,
                ),
                child: SingleChildScrollView(child: sheet),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Navigate" pill over the map: hands the leg to the phone's map app.
class NavigateButton extends StatelessWidget {
  const NavigateButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: sgL10n(context).tripNavigate,
    child: GestureDetector(
      key: const Key('trip_navigate'),
      onTap: onTap,
      child: Container(
        height: kSgTouch,
        padding: const EdgeInsets.symmetric(horizontal: SgSpace.s4),
        decoration: BoxDecoration(
          color: SgColors.bg100,
          borderRadius: BorderRadius.circular(SgRadius.pill),
          border: Border.all(color: SgColors.goldLine),
          boxShadow: [
            BoxShadow(
              color: SgColors.scrim,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SgIcon(
              '<path d="M3 11l18-8-8 18-2-8z"/>',
              size: 18,
              color: SgColors.goldText,
            ),
            const SizedBox(width: SgSpace.s2),
            Text(
              sgL10n(context).tripNavigate,
              style: SgText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Manrope has no ★, so the star is drawn.
const kStarIcon =
    '<path d="M12 3l2.8 5.7 6.2.9-4.5 4.4 1 6.2L12 17.3 6.5 20.2l1-6.2L3 9.6l6.2-.9z"/>';

/// Initials, first name and rating, with call and message on the right.
class RiderRow extends StatelessWidget {
  const RiderRow({
    super.key,
    required this.name,
    this.rating,
    this.subtitle,
    this.onMessage,
  });

  final String? name;
  final double? rating;
  final String? subtitle;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final first = firstNameOf(name);
    final initials = initialsOf(name);
    final rated = rating != null && rating! > 0;
    final meta = [if (rated) rating!.toStringAsFixed(1), ?subtitle].join(' · ');
    return Row(
      children: [
        Container(
          width: kSgTouch,
          height: kSgTouch,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SgColors.bg300,
            shape: BoxShape.circle,
            border: Border.all(color: SgColors.line),
          ),
          child: initials.isEmpty
              ? SgIcon(SgIcons.user, color: SgColors.ink)
              : Text(initials, style: SgText.title),
        ),
        const SizedBox(width: SgSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.isEmpty ? sgL10n(context).tripRiderFallback : first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SgText.title,
              ),
              if (meta.isNotEmpty)
                Row(
                  children: [
                    if (rated) ...[
                      SgIcon(kStarIcon, size: 14, color: SgColors.gold500),
                      const SizedBox(width: SgSpace.s1),
                    ],
                    Flexible(
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SgText.caption,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (onMessage != null)
          Semantics(
            button: true,
            label: sgL10n(
              context,
            ).pinMessage(first.isEmpty ? sgL10n(context).riderFallback : first),
            child: InkWell(
              key: const Key('trip_message'),
              customBorder: const CircleBorder(),
              onTap: onMessage,
              child: Container(
                width: kSgTouch,
                height: kSgTouch,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SgColors.bg200,
                  shape: BoxShape.circle,
                  border: Border.all(color: SgColors.line),
                ),
                child: SgIcon(SgIcons.message, color: SgColors.ink),
              ),
            ),
          ),
      ],
    );
  }
}

/// A place line with the pickup circle or the drop square.
class PlaceLine extends StatelessWidget {
  const PlaceLine({
    super.key,
    required this.text,
    required this.drop,
    this.large = false,
  });

  final String text;
  final bool drop;
  final bool large;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(top: large ? 8 : 6),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: drop ? SgColors.gold500 : SgColors.pickup,
            shape: drop ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: drop ? BorderRadius.circular(2) : null,
          ),
        ),
      ),
      const SizedBox(width: SgSpace.s3),
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: large ? SgText.title : SgText.body,
        ),
      ),
    ],
  );
}

class _QuietLink extends StatelessWidget {
  const _QuietLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(SgRadius.sm),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kSgTouch),
      child: Center(
        child: Text(
          label,
          style: SgText.body.copyWith(
            color: onTap == null ? SgColors.inkSubtle : SgColors.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

/// Accepted: heading to the rider.
class ToPickupSheet extends StatelessWidget {
  const ToPickupSheet({
    super.key,
    required this.riderName,
    required this.pickupAddress,
    this.riderRating,
    this.awayLine,
    this.busy = false,
    this.onArrived,
    this.onCancel,
    this.onMessage,
  });

  final String? riderName;
  final double? riderRating;
  final String pickupAddress;

  /// "1.2 km · 4 min".
  final String? awayLine;
  final bool busy;
  final VoidCallback? onArrived;
  final VoidCallback? onCancel;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(sgL10n(context).tripHeadingToPickup, style: SgText.label),
      const SizedBox(height: SgSpace.s2),
      PlaceLine(text: pickupAddress, drop: false, large: true),
      if (awayLine != null) ...[
        const SizedBox(height: SgSpace.s1),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(awayLine!, style: SgText.caption),
        ),
      ],
      const SizedBox(height: SgSpace.s4),
      RiderRow(name: riderName, rating: riderRating, onMessage: onMessage),
      const SizedBox(height: SgSpace.s4),
      SgPrimaryButton(
        key: const Key('trip_arrived'),
        label: busy
            ? sgL10n(context).commonPleaseWait
            : sgL10n(context).tripArrived,
        onPressed: busy ? null : onArrived,
      ),
      _QuietLink(
        key: const Key('trip_cancel'),
        label: sgL10n(context).tripCancelRide,
        onTap: busy ? null : onCancel,
      ),
    ],
  );
}

/// The trip PIN's length: six digits, as the rider app shows it (rider #22)
/// and as the backend issues it.
const kTripPinLength = 6;

/// The PIN as boxes, 72px tall, one per digit of the real length.
class PinBoxes extends StatelessWidget {
  const PinBoxes({
    super.key,
    required this.digits,
    this.length = kTripPinLength,
    this.error = false,
    this.height = 72,
  });

  final String digits;
  final int length;
  final bool error;

  /// 72 by default; 56 on a short screen.
  final double height;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    return Semantics(
      label: l.pinDigits(digits.length, length),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < length; i++) ...[
            if (i > 0) const SizedBox(width: SgSpace.s2),
            Expanded(
              child: Container(
                key: Key('pin_box_$i'),
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SgColors.bg200,
                  borderRadius: BorderRadius.circular(SgRadius.md),
                  border: Border.all(
                    width: i == digits.length && !error ? 2 : 1,
                    color: error
                        ? SgColors.danger
                        : i == digits.length
                        ? SgColors.goldText
                        : SgColors.lineStrong,
                  ),
                ),
                child: Text(
                  i < digits.length ? digits[i] : '',
                  style: SgText.figureLg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A 64px number pad that types into [controller], so the phone keyboard
/// never covers the screen.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.controller,
    this.length = kTripPinLength,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  void _type(String d) {
    final t = controller.text;
    if (t.length >= length) return;
    controller.text = t + d;
    onChanged?.call(controller.text);
  }

  void _delete() {
    final t = controller.text;
    if (t.isEmpty) return;
    controller.text = t.substring(0, t.length - 1);
    onChanged?.call(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    Widget key(String d) => _Key(
      key: Key('pin_key_$d'),
      label: d,
      onTap: enabled ? () => _type(d) : null,
      child: Text(d, style: SgText.figureLg),
    );
    Widget row(List<Widget> keys) => Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: SgSpace.s2),
          Expanded(child: keys[i]),
        ],
      ],
    );
    return Column(
      children: [
        row([key('1'), key('2'), key('3')]),
        const SizedBox(height: SgSpace.s2),
        row([key('4'), key('5'), key('6')]),
        const SizedBox(height: SgSpace.s2),
        row([key('7'), key('8'), key('9')]),
        const SizedBox(height: SgSpace.s2),
        row([
          const SizedBox(height: kSgTouch),
          key('0'),
          _Key(
            key: const Key('pin_key_delete'),
            label: l.pinDeleteDigit,
            quiet: true,
            onTap: enabled ? _delete : null,
            child: SgIcon(
              '<path d="M9 5h11v14H9l-6-7z"/><path d="M12 9.5l5 5M17 9.5l-5 5"/>',
              size: 28,
              color: SgColors.ink,
            ),
          ),
        ]),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.quiet = false,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool quiet;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: quiet ? Colors.transparent : SgColors.bg200,
      borderRadius: BorderRadius.circular(SgRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SgRadius.md),
        child: SizedBox(
          height: kSgTouch,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// The backend's PIN refusals, in the app's voice. Null when there is none.
String? pinErrorText(String? raw, String? riderName, [AppLocalizations? l]) {
  if (raw == null) return null;
  final strings = l ?? lookupAppLocalizations(const Locale('en'));
  final first = firstNameOf(riderName);
  final who = first.isEmpty ? strings.riderFallback : first;
  if (raw.toLowerCase().contains('too many')) return strings.pinTooMany(who);
  if (raw.toLowerCase().contains('invalid')) return strings.pinMismatch(who);
  return raw;
}

/// Reached (Tier 3, screen 3): "At pickup" with a check, the rider with a
/// 56px contact button, the PIN boxes, a 64px keypad and a 72px Start trip.
///
/// Start trip sends the PIN through the existing start flow; the trip only
/// moves on when the API accepts it, and a refusal comes back as [error].
class PinCheckView extends StatelessWidget {
  const PinCheckView({
    super.key,
    required this.controller,
    required this.riderName,
    this.riderRating,
    this.pickupAddress,
    this.error,
    this.busy = false,
    this.length = kTripPinLength,
    this.onStart,
    this.onCancel,
    this.onChanged,
    this.onMessage,
    this.topActions,
  });

  final TextEditingController controller;
  final String? riderName;
  final double? riderRating;
  final String? pickupAddress;
  final String? error;
  final bool busy;
  final int length;
  final VoidCallback? onStart;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onChanged;

  /// The existing trip chat. TODO(data): a masked number to call the rider;
  /// there is no call action today, so the 56px button is the message one.
  final VoidCallback? onMessage;
  final Widget? topActions;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final first = firstNameOf(riderName);
    final who = first.isEmpty ? l.riderFallback : first;
    final ready = controller.text.length == length;
    final rated = riderRating != null && riderRating! > 0;
    final initials = initialsOf(riderName);
    // TODO(data): the free-wait timer needs the time the driver reached
    // pickup and cancel_policy.free_wait_minutes; neither reaches this
    // screen yet, so "At pickup" shows without a timer.
    final tablet = SgText.sizeClass == SgSizeClass.tablet;
    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: SafeArea(
        // Tablets: a centred card at most 480 wide (owner brief).
        child: _CentredCard(
          tablet: tablet,
          cardKey: const Key('pin_tablet_card'),
          child: LayoutBuilder(
            builder: (context, box) {
              // A short window (a 360x640 phone, a landscape phone, a large
              // text size): fold the rider row into the header and tighten
              // the gaps so Start trip stays on screen without a scroll.
              final short = box.maxHeight < 700;
              final Widget? message = onMessage == null
                  ? null
                  : Semantics(
                      button: true,
                      label: l.pinMessage(who),
                      excludeSemantics: true,
                      child: Material(
                        color: SgColors.bg200,
                        shape: CircleBorder(
                          side: BorderSide(color: SgColors.lineStrong),
                        ),
                        child: InkWell(
                          key: const Key('trip_message'),
                          customBorder: const CircleBorder(),
                          onTap: onMessage,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: SgIcon(
                                SgIcons.message,
                                size: 24,
                                color: SgColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SgSpace.s4,
                  SgSpace.s2,
                  SgSpace.s4,
                  SgSpace.s3,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: box.maxHeight - SgSpace.s2 - SgSpace.s3,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: kSgTouch,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: SgColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: SgIcon(
                                  SgIcons.check,
                                  size: 20,
                                  color: SgColors.bg000,
                                ),
                              ),
                              const SizedBox(width: SgSpace.s2),
                              Expanded(
                                child: Text(
                                  l.pinAtPickup,
                                  key: const Key('pin_at_pickup'),
                                  style: SgText.sectionTitle.copyWith(
                                    color: SgColors.success,
                                  ),
                                ),
                              ),
                              if (short) ?message,
                              if (short) const SizedBox(width: SgSpace.s2),
                              ?topActions,
                            ],
                          ),
                        ),
                        if (!short) const SizedBox(height: SgSpace.s2),
                        if (!short)
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: SgColors.bg300,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: SgColors.line),
                                ),
                                child: initials.isEmpty
                                    ? SgIcon(SgIcons.user, color: SgColors.ink)
                                    : Text(initials, style: SgText.title),
                              ),
                              const SizedBox(width: SgSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      first.isEmpty ? l.riderFallback : first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: SgText.sectionTitle,
                                    ),
                                    if (rated)
                                      Row(
                                        children: [
                                          SgIcon(
                                            kStarIcon,
                                            size: 14,
                                            color: SgColors.goldText,
                                          ),
                                          const SizedBox(width: SgSpace.s1),
                                          Text(
                                            riderRating!.toStringAsFixed(1),
                                            style: SgText.caption,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (!short) ?message,
                            ],
                          ),
                        SizedBox(height: short ? SgSpace.s2 : SgSpace.s4),
                        Text(l.pinAsk(who), style: SgText.heading),
                        SizedBox(height: short ? SgSpace.s2 : SgSpace.s3),
                        PinBoxes(
                          digits: controller.text,
                          length: length,
                          error: error != null,
                          height: short ? 56 : 72,
                        ),
                        SizedBox(
                          height: short ? 32 : 48,
                          child: error == null
                              ? null
                              : Center(
                                  child: Text(
                                    error!,
                                    key: const Key('trip_pin_error'),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: SgText.body.copyWith(
                                      color: SgColors.danger,
                                    ),
                                  ),
                                ),
                        ),
                        PinKeypad(
                          controller: controller,
                          length: length,
                          enabled: !busy,
                          onChanged: onChanged,
                        ),
                        const Spacer(),
                        SizedBox(height: short ? SgSpace.s2 : SgSpace.s3),
                        SgPrimaryButton(
                          key: const Key('trip_start'),
                          label: busy ? l.commonPleaseWait : l.pinStartTrip,
                          height: kSgPrimaryAction,
                          onPressed: busy || !ready ? null : onStart,
                        ),
                        _QuietLink(
                          key: const Key('trip_cancel'),
                          label: l.tripCancelRide,
                          onTap: busy ? null : onCancel,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Phones: the child, at most 480 wide. Tablets: a bordered card, centred.
class _CentredCard extends StatelessWidget {
  const _CentredCard({required this.tablet, required this.child, this.cardKey});

  final bool tablet;
  final Widget child;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: tablet ? 900 : double.infinity,
      ),
      child: tablet
          ? Padding(
              padding: const EdgeInsets.all(SgSpace.s5),
              child: DecoratedBox(
                key: cardKey,
                decoration: BoxDecoration(
                  color: SgColors.bg100,
                  borderRadius: BorderRadius.circular(SgRadius.xl),
                  border: Border.all(color: SgColors.line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SgRadius.xl),
                  child: child,
                ),
              ),
            )
          : child,
    ),
  );
}

/// The large light banner over the trip map. There is no turn-by-turn data,
/// so it is "Open in Maps" (the existing Navigate action), light in both
/// themes so it reads at a glance.
class OpenInMapsBanner extends StatelessWidget {
  const OpenInMapsBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    const p = SgPalette.light;
    return Semantics(
      button: true,
      label: l.tripOpenInMaps,
      excludeSemantics: true,
      child: Material(
        color: p.bg100,
        borderRadius: BorderRadius.circular(SgRadius.lg),
        elevation: 0,
        child: InkWell(
          key: const Key('trip_open_in_maps'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(SgRadius.lg),
          child: Container(
            height: kSgPrimaryAction,
            padding: const EdgeInsets.symmetric(horizontal: SgSpace.s4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SgRadius.lg),
              border: Border.all(color: p.lineStrong),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.gold500,
                    borderRadius: BorderRadius.circular(SgRadius.sm),
                  ),
                  child: SgIcon(
                    '<path d="M3 11l18-8-8 18-2-8z"/>',
                    size: 24,
                    color: p.onGold,
                  ),
                ),
                const SizedBox(width: SgSpace.s3),
                Expanded(
                  child: Text(
                    l.tripOpenInMaps,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SgText.sectionTitle.copyWith(color: p.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Night mode since sunset": shown only when the automatic theme chose dark.
class NightModeChip extends StatelessWidget {
  const NightModeChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('trip_night_chip'),
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: SgSpace.s3),
    decoration: BoxDecoration(
      color: SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.pill),
      border: Border.all(color: SgColors.goldLine),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SgIcon(
          '<path d="M20 14.5A8 8 0 019.5 4a8 8 0 1010.5 10.5z"/>',
          size: 16,
          color: SgColors.goldText,
        ),
        const SizedBox(width: SgSpace.s2),
        Text(
          sgL10n(context).tripNightMode,
          style: SgText.caption.copyWith(
            color: SgColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// In progress (Tier 3, screen 4): "Dropping {rider}", the destination area
/// at 19px, time and distance, the fare, and a 72px "End trip at drop".
class InTripSheet extends StatelessWidget {
  const InTripSheet({
    super.key,
    required this.destination,
    required this.riderName,
    this.leftLine,
    this.fare,
    this.earning,
    this.payment,
    this.busy = false,
    this.onComplete,
  });

  final String destination;
  final String? riderName;

  /// "6.2 km · 14 min".
  final String? leftLine;
  final String? fare;

  /// What the driver keeps, from the backend's settlement arithmetic. When
  /// present it replaces the fare as the big figure, labelled "You earn".
  final String? earning;
  final String? payment;
  final bool busy;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final first = firstNameOf(riderName);
    final at = destination.indexOf(',');
    final area = at > 0 ? destination.substring(0, at).trim() : destination;
    final rest = at > 0 ? destination.substring(at + 1).trim() : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.tripDropping(first.isEmpty ? l.riderFallback : first),
          key: const Key('trip_dropping'),
          style: SgText.label.copyWith(color: SgColors.goldText),
        ),
        const SizedBox(height: SgSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: SgSpace.s3),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: SgColors.gold500,
                  borderRadius: BorderRadius.circular(3),
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
                  if (rest.isNotEmpty)
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
        const SizedBox(height: SgSpace.s3),
        Row(
          children: [
            if (leftLine != null)
              Expanded(child: Text(leftLine!, style: SgText.fare))
            else
              const Spacer(),
            // The driver's earning when the trip carries it (`driver_earning`),
            // else the fare, labelled as such.
            if (earning != null || fare != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    earning ?? fare!,
                    key: Key(earning != null ? 'trip_earning' : 'trip_fare'),
                    style: SgText.fare,
                  ),
                  Text(
                    earning != null
                        ? (payment == null
                              ? l.offerYouEarn
                              : '${l.offerYouEarn} · $payment')
                        : (payment == null
                              ? l.offerFare
                              : '${l.offerFare} · $payment'),
                    style: SgText.caption,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: SgSpace.s4),
        SgPrimaryButton(
          key: const Key('trip_complete'),
          label: busy ? l.commonPleaseWait : l.tripEndAtDrop,
          height: kSgPrimaryAction,
          onPressed: busy ? null : onComplete,
        ),
      ],
    );
  }
}

/// Completed: collect cash (or see it was paid), then rate and go.
class TripCompleteView extends StatelessWidget {
  const TripCompleteView({
    super.key,
    required this.title,
    required this.riderName,
    this.amount,
    this.amountCaption,
    this.cashToCollect,
    this.paidLine,
    this.facts = const [],
    this.notes = const [],
    this.busy = false,
    this.onConfirmCash,
    this.onDone,
    this.onRate,
  });

  final String title;
  final String? riderName;

  /// The big figure; null when it would mislead (a platform-paid end).
  final String? amount;
  final String? amountCaption;

  /// Set while cash is still to be collected: "₹150".
  final String? cashToCollect;

  /// "Paid by UPI" once nothing is owed.
  final String? paidLine;

  /// Distance, time, payment.
  final List<(String, String)> facts;

  /// Promo and support lines, each its own panel.
  final List<Widget> notes;
  final bool busy;
  final VoidCallback? onConfirmCash;
  final VoidCallback? onDone;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final first = firstNameOf(riderName);
    final collecting = cashToCollect != null;
    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SgSpace.s4,
            SgSpace.s5,
            SgSpace.s4,
            SgSpace.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        key: const Key('summary_title'),
                        style: SgText.heading,
                      ),
                      const SizedBox(height: SgSpace.s5),
                      if (collecting)
                        _CollectPanel(amount: cashToCollect!, name: first)
                      else if (amount != null) ...[
                        if (amountCaption != null)
                          Text(amountCaption!, style: SgText.caption),
                        const SizedBox(height: SgSpace.s1),
                        Text(
                          amount!,
                          key: const Key('summary_fare'),
                          style: SgText.bigFare,
                        ),
                        if (paidLine != null) ...[
                          const SizedBox(height: SgSpace.s2),
                          Row(
                            children: [
                              SgIcon(
                                SgIcons.check,
                                size: 18,
                                color: SgColors.pickup,
                              ),
                              const SizedBox(width: SgSpace.s2),
                              Text(paidLine!, style: SgText.body),
                            ],
                          ),
                        ],
                      ] else if (amountCaption != null)
                        Text(amountCaption!, style: SgText.body),
                      if (facts.isNotEmpty) ...[
                        const SizedBox(height: SgSpace.s5),
                        _Facts(facts),
                      ],
                      for (final n in notes) ...[
                        const SizedBox(height: SgSpace.s3),
                        n,
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SgSpace.s3),
              if (collecting)
                SgPrimaryButton(
                  key: const Key('trip_cash_collected'),
                  label: busy
                      ? sgL10n(context).commonPleaseWait
                      : sgL10n(context).tripCashCollected,
                  onPressed: busy ? null : onConfirmCash,
                )
              else
                SgPrimaryButton(
                  key: const Key('trip_done'),
                  label: sgL10n(context).tripDone,
                  onPressed: onDone,
                ),
              if (onRate != null)
                _QuietLink(
                  key: const Key('trip_rate'),
                  label: first.isEmpty
                      ? sgL10n(context).tripRateRider
                      : sgL10n(context).tripRateName(first),
                  onTap: onRate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectPanel extends StatelessWidget {
  const _CollectPanel({required this.amount, required this.name});

  final String amount;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('summary_collect'),
    padding: const EdgeInsets.all(SgSpace.s5),
    decoration: BoxDecoration(
      color: SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.lg),
      border: Border.all(color: SgColors.goldLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sgL10n(context).tripCollectInCash, style: SgText.label),
        const SizedBox(height: SgSpace.s2),
        Text(amount, key: const Key('summary_fare'), style: SgText.bigFare),
        const SizedBox(height: SgSpace.s2),
        Text(
          sgL10n(context).tripCollectBody(
            amount,
            name.isEmpty ? sgL10n(context).riderFallback : name,
          ),
          style: SgText.body.copyWith(color: SgColors.inkMuted),
        ),
      ],
    ),
  );
}

class _Facts extends StatelessWidget {
  const _Facts(this.facts);

  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: SgSpace.s3),
    decoration: BoxDecoration(
      color: SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.md),
      border: Border.all(color: SgColors.line),
    ),
    child: Row(
      children: [
        for (var i = 0; i < facts.length; i++) ...[
          if (i > 0) Container(width: 1, height: 32, color: SgColors.line),
          Expanded(
            child: Column(
              children: [
                Text(facts[i].$1, style: SgText.caption),
                const SizedBox(height: SgSpace.s1),
                Text(facts[i].$2, style: SgText.title),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

/// A one-line panel under the facts: a promo paid, a support end.
class TripNote extends StatelessWidget {
  const TripNote({super.key, required this.text, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SgSpace.s4),
    decoration: BoxDecoration(
      color: SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.md),
      border: Border.all(color: SgColors.line),
    ),
    child: Row(
      children: [
        Expanded(child: Text(text, style: SgText.body)),
        if (trailing != null) Text(trailing!, style: SgText.fare),
      ],
    ),
  );
}
