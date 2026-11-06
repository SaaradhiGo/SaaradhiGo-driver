/// The driver home on the design system: map first, a status pill on top, and
/// one bottom sheet with today's earnings and the single control that matters.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/market/market_config_store.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';

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
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(SgRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(SgRadius.md),
          onTap: onPressed,
          child: Container(
            height: 56,
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
  const InboxBell({super.key, required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: unread > 0 ? 'Messages, $unread unread' : 'Messages',
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
                  child: const Center(
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

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({
    super.key,
    required this.map,
    required this.online,
    required this.statusLabel,
    required this.onMenu,
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

  /// Calm lines above the sheet: reconnecting, weak GPS.
  final List<Widget> notices;
  final VoidCallback? onGoOnline;
  final VoidCallback? onGoOffline;
  final VoidCallback? onEarnings;
  final Widget? mapButton;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(child: map),
        Positioned(
          top: top + SgSpace.s3,
          left: SgSpace.s4,
          right: SgSpace.s4,
          child: Row(
            children: [
              SgMapButton(icon: SgIcons.menu, label: 'Menu', onTap: onMenu),
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/brand/saaradhigo-emblem-gold.svg',
                    height: 30,
                    semanticsLabel: 'SaaradhiGo',
                  ),
                ),
              ),
              if (onInbox != null) ...[
                InboxBell(unread: unread, onTap: onInbox!),
                const SizedBox(width: SgSpace.s2),
              ],
              OnlinePill(label: statusLabel, online: online),
            ],
          ),
        ),
        Positioned(
          left: SgSpace.s4,
          right: SgSpace.s4,
          top: top + SgSpace.s3 + kSgTouch + SgSpace.s3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final n in notices) n],
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
                child: _sheetBody(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _sheetBody() {
    final stats = <(String, String)>[
      if (trips != null) ('Trips', '$trips'),
      if (online && onlineFor != null)
        ('Online time', onlineTimeLabel(onlineFor!)),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: onEarnings != null,
          label: commission == null ? 'Today\'s earnings' : 'You keep today',
          child: InkWell(
            onTap: onEarnings,
            borderRadius: BorderRadius.circular(SgRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kSgTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SgSpace.s1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commission == null
                                ? 'Today\'s earnings'
                                : 'You keep today',
                            style: SgText.caption,
                          ),
                          const SizedBox(height: SgSpace.s1),
                          Text(
                            earnings ?? '–',
                            style: SgText.heading.copyWith(
                              fontSize: 40,
                              height: 44 / 40,
                              fontWeight: FontWeight.w800,
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                            ),
                          ),
                          if (commission != null)
                            Text(
                              'Commission $commission',
                              key: const Key('home_commission'),
                              style: SgText.caption,
                            ),
                        ],
                      ),
                    ),
                    for (final s in stats) ...[
                      const SizedBox(width: SgSpace.s5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1, style: SgText.caption),
                          const SizedBox(height: SgSpace.s1),
                          Text(s.$2, style: SgText.title),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: SgSpace.s4),
        if (blocker != null)
          _BlockerNotice(blocker: blocker!)
        else if (online) ...[
          Text(
            'Looking for rides near you',
            textAlign: TextAlign.center,
            style: SgText.body.copyWith(color: SgColors.inkMuted),
          ),
          const SizedBox(height: SgSpace.s3),
          SgSecondaryButton(
            label: busy ? 'Please wait' : 'Go offline',
            onPressed: busy ? null : onGoOffline,
          ),
        ] else
          SgPrimaryButton(
            label: busy ? 'Please wait' : 'Go online',
            onPressed: busy ? null : onGoOnline,
          ),
      ],
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