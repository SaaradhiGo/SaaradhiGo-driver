/// The driver home on the design system: map first, a status pill on top, and
/// one bottom sheet with today's earnings and the single control that matters.
library;

import 'package:flutter/material.dart';

import '../core/market/market_config_store.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';
import 'sg_l10n.dart';

/// Whole currency units: "₹248". Null for an amount that does not parse.
String? wholeMoney(String? raw) {
  if (raw == null) return null;
  final market = MarketConfigStore.instance.current;
  final value = double.tryParse(market.stripSymbol(raw).replaceAll(',', ''));
  if (value == null) return null;
  final digits = value.round().abs().toString();
  final grouped = market.currencySymbol == '₹'
      ? _indianGroups(digits)
      : _westernGroups(digits);
  return '${value.round() < 0 ? '-' : ''}${market.currencySymbol}$grouped';
}

String _westernGroups(String d) => d.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

String _indianGroups(String d) {
  if (d.length <= 3) return d;
  final head = d.substring(0, d.length - 3);
  final tail = d.substring(d.length - 3);
  final groups = head.replaceAllMapped(
    RegExp(r'\B(?=(\d{2})+(?!\d))'),
    (_) => ',',
  );
  return '$groups,$tail';
}

/// "1h 12m", "12m", "Just started".
String onlineTimeLabel(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return 'Just started';
}

/// Why the driver cannot go online yet, with the one action that fixes it.
class HomeBlocker {
  const HomeBlocker({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
}

class SgSecondaryButton extends StatelessWidget {
  const SgSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(SgRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(SgRadius.md),
          onTap: onPressed,
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: SgSpace.s5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SgRadius.md),
              border: Border.all(color: SgColors.lineStrong),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SgText.button.copyWith(color: SgColors.ink),
            ),
          ),
        ),
      );
}

class InboxBell extends StatelessWidget {
  const InboxBell({
    super.key,
    required this.unread,
    required this.onTap,
    this.label = 'Messages',
  });

  final int unread;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: unread > 0 ? '$label, $unread unread' : label,
        child: GestureDetector(
          key: const Key('home_inbox'),
          onTap: onTap,
          child: SizedBox(
            width: kSgTouch,
            height: kSgTouch,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: SgColors.bg100,
                    shape: BoxShape.circle,
                    border: Border.all(color: SgColors.goldLine),
                  ),
                  child: Center(
                    child: SgIcon(SgIcons.bell, color: SgColors.ink),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      key: const Key('home_inbox_dot'),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: SgColors.gold500,
                        shape: BoxShape.circle,
                        border: Border.all(color: SgColors.bg100, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class OnlinePill extends StatelessWidget {
  const OnlinePill({super.key, required this.label, required this.online});

  final String label;
  final bool online;

  @override
  Widget build(BuildContext context) => Container(
        height: kSgTouch,
        padding: const EdgeInsets.symmetric(horizontal: SgSpace.s4),
        decoration: BoxDecoration(
          color: SgColors.bg100,
          borderRadius: BorderRadius.circular(SgRadius.pill),
          border: Border.all(color: online ? SgColors.goldLine : SgColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? SgColors.pickup : SgColors.lineStrong,
              ),
            ),
            const SizedBox(width: SgSpace.s2),
            Text(
              label,
              style: SgText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: online ? SgColors.ink : SgColors.inkMuted,
              ),
            ),
          ],
        ),
      );
}

/// The driver home (Tier 3, screen 1): a noir earnings card at the top with
/// the menu on its left and a red Safety button on its right, the plain map,
/// and a short panel with the status and the one control.
class DriverHomeView extends StatelessWidget {
  const DriverHomeView({
    super.key,
    required this.map,
    required this.online,
    required this.statusLabel,
    required this.onMenu,
    this.onSafety,
    this.onInbox,
    this.unread = 0,
    this.busy = false,
    this.earnings,
    this.commission,
    this.trips,
    this.onlineFor,
    this.blocker,
    this.notices = const [],
    this.onGoOnline,
    this.onGoOffline,
    this.onEarnings,
    this.mapButton,
  });

  final Widget map;
  final bool online;
  final String statusLabel;
  final bool busy;
  final VoidCallback onMenu;

  /// The red Safety button beside the earnings card (the safety centre).
  final VoidCallback? onSafety;

  /// The bell: messages and notices (Messages left the tab bar in group E).
  final VoidCallback? onInbox;
  final int unread;

  /// Whole-rupee text, or null while it has not loaded.
  final String? earnings;

  /// Today's commission, whole currency; when set, [earnings] is the net.
  final String? commission;
  final int? trips;
  final Duration? onlineFor;
  final HomeBlocker? blocker;

  /// Calm lines under the card: reconnecting, weak GPS.
  final List<Widget> notices;
  final VoidCallback? onGoOnline;
  final VoidCallback? onGoOffline;
  final VoidCallback? onEarnings;
  final Widget? mapButton;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(child: map),
        Positioned(
          top: top + SgSpace.s3,
          left: SgSpace.s4,
          right: SgSpace.s4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SgMapButton(
                    icon: SgIcons.menu,
                    label: l.commonMenu,
                    onTap: onMenu,
                  ),
                  const SizedBox(width: SgSpace.s2),
                  Expanded(
                    child: EarningsNoirCard(
                      earnings: earnings,
                      commission: commission,
                      trips: trips,
                      onTap: onEarnings,
                    ),
                  ),
                  if (onSafety != null) ...[
                    const SizedBox(width: SgSpace.s2),
                    SafetyButton(onTap: onSafety!),
                  ],
                ],
              ),
              if (notices.isNotEmpty) const SizedBox(height: SgSpace.s2),
              for (final n in notices) n,
            ],
          ),
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
                  SgSpace.s4 + bottom,
                ),
                child: _panel(l),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel(AppLocalizations l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kSgTouch,
          child: Row(
            children: [
              Container(
                key: const Key('home_status_dot'),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? SgColors.success : SgColors.lineStrong,
                ),
              ),
              const SizedBox(width: SgSpace.s3),
              Flexible(
                child: Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SgText.heading.copyWith(
                    fontSize: 22,
                    height: 26 / 22,
                    color: online ? SgColors.ink : SgColors.inkMuted,
                  ),
                ),
              ),
              if (online && onlineFor != null) ...[
                const SizedBox(width: SgSpace.s2),
                Text(
                  '· ${onlineTimeLabel(onlineFor!)}',
                  style: SgText.body.copyWith(color: SgColors.inkMuted),
                ),
              ],
              const Spacer(),
              if (onInbox != null)
                InboxBell(unread: unread, onTap: onInbox!, label: l.homeMessages),
            ],
          ),
        ),
        if (blocker != null) ...[
          const SizedBox(height: SgSpace.s2),
          _BlockerNotice(blocker: blocker!),
        ] else if (online) ...[
          Text(
            l.homeLooking,
            style: SgText.body.copyWith(color: SgColors.inkMuted),
          ),
          const SizedBox(height: SgSpace.s3),
          SgSecondaryButton(
            key: const Key('home_go_offline'),
            label: busy ? l.commonPleaseWait : l.homeGoOffline,
            height: kSgTouch,
            onPressed: busy ? null : onGoOffline,
          ),
        ] else ...[
          const SizedBox(height: SgSpace.s2),
          SgPrimaryButton(
            key: const Key('home_go_online'),
            label: busy ? l.commonPleaseWait : l.homeGoOnline,
            height: kSgPrimaryAction,
            onPressed: busy ? null : onGoOnline,
          ),
        ],
      ],
    );
  }
}

/// "₹1,240" with the currency symbol in gold-text. Falls back to plain text
/// when the amount carries no known symbol.
class GoldSymbolAmount extends StatelessWidget {
  const GoldSymbolAmount(
    this.amount, {
    super.key,
    required this.style,
    required this.symbolColor,
  });

  final String amount;
  final TextStyle style;
  final Color symbolColor;

  @override
  Widget build(BuildContext context) {
    final symbol = MarketConfigStore.instance.current.currencySymbol;
    final at = amount.indexOf(symbol);
    if (symbol.isEmpty || at < 0) return Text(amount, style: style);
    return Text.rich(
      TextSpan(
        children: [
          if (at > 0) TextSpan(text: amount.substring(0, at)),
          TextSpan(text: symbol, style: TextStyle(color: symbolColor)),
          TextSpan(text: amount.substring(at + symbol.length)),
        ],
      ),
      style: style,
      maxLines: 1,
    );
  }
}

/// Today's earnings on a noir panel in both themes: "Today · N trips", the
/// amount at 38px with a gold ₹ (net "You keep" when commission is known),
/// and today's commission beside it.
class EarningsNoirCard extends StatelessWidget {
  const EarningsNoirCard({
    super.key,
    this.earnings,
    this.commission,
    this.trips,
    this.onTap,
  });

  final String? earnings;
  final String? commission;
  final int? trips;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    // Noir in both themes: the dark palette, whatever the app theme is.
    const p = SgPalette.dark;
    final heading = trips == null ? l.homeToday : l.homeTodayTrips(trips!);
    final caption = commission == null ? l.homeTodaysEarnings : l.homeYouKeep;
    return Semantics(
      button: onTap != null,
      label: '$heading, $caption ${earnings ?? ''}',
      hint: onTap == null ? null : l.homeOpenEarnings,
      excludeSemantics: true,
      child: Material(
        key: const Key('home_earnings_card'),
        color: p.bg000,
        borderRadius: BorderRadius.circular(SgRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SgRadius.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.fromLTRB(
              SgSpace.s4,
              SgSpace.s3,
              SgSpace.s4,
              SgSpace.s3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SgRadius.lg),
              border: Border.all(color: p.goldLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SgText.caption.copyWith(
                    color: p.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: GoldSymbolAmount(
                              earnings ?? '–',
                              key: const Key('home_earnings'),
                              symbolColor: p.goldText,
                              style: SgText.fare.copyWith(
                                fontSize: 38,
                                height: 40 / 38,
                                color: p.ink,
                              ),
                            ),
                          ),
                          Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SgText.caption.copyWith(color: p.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    if (commission != null) ...[
                      const SizedBox(width: SgSpace.s3),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            commission!,
                            key: const Key('home_commission'),
                            style: SgText.title.copyWith(color: p.ink),
                          ),
                          Text(
                            l.homeCommission,
                            style: SgText.caption.copyWith(color: p.inkMuted),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The red Safety button: 64px, danger fill.
class SafetyButton extends StatelessWidget {
  const SafetyButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    return Semantics(
      button: true,
      label: l.commonSafety,
      excludeSemantics: true,
      child: Material(
        key: const Key('home_safety'),
        color: SgColors.danger,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: kSgTouch,
            height: kSgTouch,
            child: Center(
              child: SgIcon(SgIcons.shield, size: 26, color: SgColors.onDanger),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockerNotice extends StatelessWidget {
  const _BlockerNotice({required this.blocker});

  final HomeBlocker blocker;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(SgSpace.s4),
        decoration: BoxDecoration(
          color: SgColors.bg200,
          borderRadius: BorderRadius.circular(SgRadius.md),
          border: Border.all(color: SgColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(blocker.title, style: SgText.title),
            const SizedBox(height: SgSpace.s1),
            Text(blocker.body, style: SgText.caption),
            const SizedBox(height: SgSpace.s3),
            InkWell(
              onTap: blocker.onAction,
              borderRadius: BorderRadius.circular(SgRadius.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kSgTouch),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    blocker.actionLabel,
                    style: SgText.body.copyWith(
                      color: SgColors.goldText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// A calm notice above the sheet (reconnecting, weak GPS), with an optional
/// action.
class HomeNotice extends StatelessWidget {
  const HomeNotice(this.text, {super.key, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: SgSpace.s2),
        padding: const EdgeInsets.symmetric(
          horizontal: SgSpace.s4,
          vertical: SgSpace.s1,
        ),
        constraints: const BoxConstraints(minHeight: kSgTouch),
        decoration: BoxDecoration(
          color: SgColors.bgGlass,
          borderRadius: BorderRadius.circular(SgRadius.md),
          border: Border.all(color: SgColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: SgText.caption.copyWith(color: SgColors.ink),
              ),
            ),
            if (actionLabel != null)
              InkWell(
                onTap: onAction,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kSgTouch,
                    minWidth: kSgTouch,
                  ),
                  child: Center(
                    child: Text(
                      actionLabel!,
                      style: SgText.body.copyWith(
                        color: SgColors.goldText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}