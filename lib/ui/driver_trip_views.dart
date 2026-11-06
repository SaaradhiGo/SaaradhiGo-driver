/// The driver's trip on the design system (group E): to pickup, the PIN check,
/// the trip in progress, and complete and collect. Pure views: the screens in
/// features/trip own the session and pass in what to show.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/market/market_config_store.dart';
import 'driver_home_view.dart';
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

String paymentLabel(String? method) => switch ((method ?? '').toLowerCase()) {
      'cash' => 'Cash',
      'upi' => 'UPI',
      'card' => 'Card',
      'wallet' => 'Wallet',
      _ => 'Online',
    };

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
  });

  final Widget map;
  final Widget sheet;
  final Widget? topActions;
  final Widget? mapButton;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: Stack(
        children: [
          Positioned.fill(child: map),
          if (topActions != null)
            Positioned(
              top: pad.top + SgSpace.s3,
              right: SgSpace.s4,
              child: topActions!,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mapButton != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: SgSpace.s4,
                      bottom: SgSpace.s3,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: mapButton,
                    ),
                  ),
                SgSheetSurface(
                  padding: EdgeInsets.fromLTRB(
                    SgSpace.s4,
                    SgSpace.s3,
                    SgSpace.s4,
                    SgSpace.s4 + pad.bottom,
                  ),
                  child: sheet,
                ),
              ],
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
        label: 'Navigate',
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SgIcon(
                  '<path d="M3 11l18-8-8 18-2-8z"/>',
                  size: 18,
                  color: SgColors.goldText,
                ),
                const SizedBox(width: SgSpace.s2),
                Text(
                  'Navigate',
                  style: SgText.body.copyWith(fontWeight: FontWeight.w700),
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
    final meta = [
      if (rated) rating!.toStringAsFixed(1),
      ?subtitle,
    ].join(' · ');
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
              ? const SgIcon(SgIcons.user, color: SgColors.ink)
              : Text(initials, style: SgText.title),
        ),
        const SizedBox(width: SgSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.isEmpty ? 'Rider' : first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SgText.title,
              ),
              if (meta.isNotEmpty)
                Row(
                  children: [
                    if (rated) ...[
                      const SgIcon(kStarIcon, size: 14, color: SgColors.gold500),
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
            label: 'Message ${first.isEmpty ? 'rider' : first}',
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
                child: const SgIcon(SgIcons.message, color: SgColors.ink),
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
                fontWeight: FontWeight.w700,
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
          Text('HEADING TO PICKUP', style: SgText.label),
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
          RiderRow(
            name: riderName,
            rating: riderRating,
            onMessage: onMessage,
          ),
          const SizedBox(height: SgSpace.s4),
          SgPrimaryButton(
            key: const Key('trip_arrived'),
            label: busy ? 'Please wait' : 'I\'ve arrived',
            onPressed: busy ? null : onArrived,
          ),
          _QuietLink(
            key: const Key('trip_cancel'),
            label: 'Cancel ride',
            onTap: busy ? null : onCancel,
          ),
        ],
      );
}

/// Six boxes over one hidden field: the rider reads their PIN, the driver
/// types it.
class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.controller,
    this.length = 6,
    this.error = false,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final int length;
  final bool error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.controller.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 1,
              child: TextField(
                key: const Key('trip_pin_field'),
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged?.call(v);
                  if (v.length == widget.length) widget.onCompleted?.call(v);
                },
              ),
            ),
          ),
          Semantics(
            label: 'Trip PIN, ${digits.length} of ${widget.length} digits',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: SgSpace.s2),
                  Container(
                    key: Key('pin_box_$i'),
                    width: 44,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SgColors.bg200,
                      borderRadius: BorderRadius.circular(SgRadius.sm),
                      border: Border.all(
                        color: widget.error
                            ? SgColors.danger
                            : i == digits.length
                                ? SgColors.goldLine
                                : SgColors.lineStrong,
                      ),
                    ),
                    child: Text(
                      i < digits.length ? digits[i] : '',
                      style: SgText.fare.copyWith(fontSize: 24),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The backend's PIN refusals, in the app's voice. Null when there is none.
String? pinErrorText(String? raw, String? riderName) {
  if (raw == null) return null;
  final first = firstNameOf(riderName);
  final who = first.isEmpty ? 'the rider' : first;
  if (raw.toLowerCase().contains('too many')) {
    return 'Too many tries. Ask $who to read the PIN again.';
  }
  if (raw.toLowerCase().contains('invalid')) {
    return 'That PIN does not match. Ask $who again.';
  }
  return raw;
}

/// Reached: the PIN check.
class PinCheckView extends StatelessWidget {
  const PinCheckView({
    super.key,
    required this.controller,
    required this.riderName,
    this.pickupAddress,
    this.error,
    this.busy = false,
    this.onStart,
    this.onCancel,
    this.onChanged,
    this.topActions,
  });

  final TextEditingController controller;
  final String? riderName;
  final String? pickupAddress;
  final String? error;
  final bool busy;
  final VoidCallback? onStart;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onChanged;
  final Widget? topActions;

  @override
  Widget build(BuildContext context) {
    final first = firstNameOf(riderName);
    final who = first.isEmpty ? 'the rider' : first;
    final ready = controller.text.length == 6;
    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SgSpace.s4,
            SgSpace.s3,
            SgSpace.s4,
            SgSpace.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('AT PICKUP', style: SgText.label)),
                  ?topActions,
                ],
              ),
              const SizedBox(height: SgSpace.s5),
              Text('Ask $who for the trip PIN', style: SgText.heading),
              const SizedBox(height: SgSpace.s2),
              Text(
                'Start only once the PIN matches. It keeps the right rider '
                'in the right car.',
                style: SgText.body.copyWith(color: SgColors.inkMuted),
              ),
              const SizedBox(height: SgSpace.s6),
              PinEntry(
                controller: controller,
                error: error != null,
                onChanged: onChanged,
              ),
              const SizedBox(height: SgSpace.s3),
              SizedBox(
                height: 22,
                child: error == null
                    ? null
                    : Text(
                        error!,
                        key: const Key('trip_pin_error'),
                        textAlign: TextAlign.center,
                        style: SgText.body.copyWith(color: SgColors.danger),
                      ),
              ),
              if (pickupAddress != null) ...[
                const SizedBox(height: SgSpace.s4),
                PlaceLine(text: pickupAddress!, drop: false),
              ],
              const Spacer(),
              SgPrimaryButton(
                key: const Key('trip_start'),
                label: busy ? 'Please wait' : 'Start trip',
                onPressed: busy || !ready ? null : onStart,
              ),
              _QuietLink(
                key: const Key('trip_cancel'),
                label: 'Cancel ride',
                onTap: busy ? null : onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In progress: on the way to the drop.
class InTripSheet extends StatelessWidget {
  const InTripSheet({
    super.key,
    required this.destination,
    required this.riderName,
    this.leftLine,
    this.fare,
    this.payment,
    this.busy = false,
    this.onComplete,
  });

  final String destination;
  final String? riderName;

  /// "6.2 km · 14 min".
  final String? leftLine;
  final String? fare;
  final String? payment;
  final bool busy;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final first = firstNameOf(riderName);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          first.isEmpty ? 'ON TRIP' : 'ON TRIP WITH ${first.toUpperCase()}',
          style: SgText.label,
        ),
        const SizedBox(height: SgSpace.s2),
        PlaceLine(text: destination, drop: true, large: true),
        if (leftLine != null) ...[
          const SizedBox(height: SgSpace.s1),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(leftLine!, style: SgText.caption),
          ),
        ],
        if (fare != null) ...[
          const SizedBox(height: SgSpace.s4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SgSpace.s4,
              vertical: SgSpace.s3,
            ),
            decoration: BoxDecoration(
              color: SgColors.bg200,
              borderRadius: BorderRadius.circular(SgRadius.md),
              border: Border.all(color: SgColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Fare${payment == null ? '' : ' · $payment'}',
                    style: SgText.caption,
                  ),
                ),
                Text(fare!, style: SgText.fare),
              ],
            ),
          ),
        ],
        const SizedBox(height: SgSpace.s4),
        SgPrimaryButton(
          key: const Key('trip_complete'),
          label: busy ? 'Please wait' : 'Complete trip',
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
                          style: SgText.fare.copyWith(
                            fontSize: 44,
                            height: 52 / 44,
                          ),
                        ),
                        if (paidLine != null) ...[
                          const SizedBox(height: SgSpace.s2),
                          Row(
                            children: [
                              const SgIcon(
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
                  label: busy ? 'Please wait' : 'Cash collected',
                  onPressed: busy ? null : onConfirmCash,
                )
              else
                SgPrimaryButton(
                  key: const Key('trip_done'),
                  label: 'Done',
                  onPressed: onDone,
                ),
              if (onRate != null)
                _QuietLink(
                  key: const Key('trip_rate'),
                  label: first.isEmpty ? 'Rate the rider' : 'Rate $first',
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
            Text('COLLECT IN CASH', style: SgText.label),
            const SizedBox(height: SgSpace.s2),
            Text(
              amount,
              key: const Key('summary_fare'),
              style: SgText.fare.copyWith(fontSize: 56, height: 64 / 56),
            ),
            const SizedBox(height: SgSpace.s2),
            Text(
              'Collect $amount cash from ${name.isEmpty ? 'the rider' : name}, '
              'then confirm below.',
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
