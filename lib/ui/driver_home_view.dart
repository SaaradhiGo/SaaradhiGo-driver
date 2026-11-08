/// The driver home on the design system: map first, a status pill on top, and
/// one bottom sheet with today's earnings and the single control that matters.
library;

import 'package:flutter/material.dart';

import '../core/market/market_config_store.dart';
import 'driver_shell.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';
import 'sg_l10n.dart';
import 'sg_load_state.dart';

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

String _westernGroups(String d) =>
    d.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

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
String onlineTimeLabel(Duration d, {String justStarted = 'Just started'}) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return justStarted;
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
    this.height = kSgTouch,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The minimum height; grows when the text wraps.
  final double height;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(SgRadius.md),
    child: InkWell(
      borderRadius: BorderRadius.circular(SgRadius.md),
      onTap: onPressed,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: SgSpace.s5,
          vertical: SgSpace.s2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SgRadius.md),
          border: Border.all(color: SgColors.lineStrong),
        ),
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
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
              child: Center(child: SgIcon(SgIcons.bell, color: SgColors.ink)),
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
            fontWeight: FontWeight.w600,
            color: online ? SgColors.ink : SgColors.inkMuted,
          ),
        ),
      ],
    ),
  );
}

/// The driver home (signed-in designs, 2026-11-08): the map, the dark top bar
/// with the DRIVER badge, warn cards under it, and one dark sheet with the
/// status, today's figures and the one control. The tab bar continues the
/// sheet underneath.
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
    this.earningsFailed = false,
    this.onRetryEarnings,
    this.onlineFor,
    this.blocker,
    this.notices = const [],
    this.onGoOnline,
    this.onGoOffline,
    this.onEarnings,
    this.mapButton,
    this.themeButton,
  });

  final Widget map;
  final bool online;
  final String statusLabel;
  final bool busy;
  final VoidCallback onMenu;

  /// Kept for callers; Safety lives in the menu on this home.
  final VoidCallback? onSafety;

  /// Kept for callers; messages live in the menu on this home.
  final VoidCallback? onInbox;
  final int unread;

  /// Today's figure as formatted text (net when [commission] is known), or
  /// null while it has not loaded.
  final String? earnings;

  /// Today's commission; when set, [earnings] is after commission.
  final String? commission;
  final int? trips;

  /// Today's figures failed or timed out: the tiles give way to the error
  /// line and Try again ([onRetryEarnings]); the rest of the sheet stays.
  final bool earningsFailed;
  final VoidCallback? onRetryEarnings;
  final Duration? onlineFor;
  final HomeBlocker? blocker;

  /// Notices under the top bar: reconnecting, weak GPS.
  final List<Widget> notices;
  final VoidCallback? onGoOnline;
  final VoidCallback? onGoOffline;
  final VoidCallback? onEarnings;
  final Widget? mapButton;

  /// Unused on this home (appearance is in the profile); kept for callers.
  final Widget? themeButton;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    return Stack(
      children: [
        Positioned.fill(child: map),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DriverTopBar(onMenu: onMenu),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SgSpace.s4,
                  SgSpace.s4,
                  SgSpace.s4,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (blocker != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: SgSpace.s2),
                        child: DriverWarnCard(
                          key: const Key('home_blocker'),
                          title: blocker!.title,
                          body: blocker!.actionLabel,
                          onTap: blocker!.onAction,
                        ),
                      ),
                    for (final n in notices) n,
                  ],
                ),
              ),
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
              _sheet(context, l),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sheet(BuildContext context, AppLocalizations l) {
    final hint = online
        ? (onlineFor == null
              ? l.homeLooking
              : '${l.homeLooking} · '
                    '${onlineTimeLabel(onlineFor!, justStarted: l.homeJustStarted)}')
        : (blocker?.body ?? l.homeOfflineHint);
    return Container(
      key: const Key('home_sheet'),
      decoration: const BoxDecoration(
        color: SgNoir.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, SgSpace.s4),
      child: Column(
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
                      online ? l.homeOnlineTitle : l.homeOfflineTitle,
                      key: const Key('home_status'),
                      style: SgText.title.copyWith(color: SgNoir.ink),
                    ),
                    Text(
                      hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SgText.small.copyWith(color: SgNoir.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SgSpace.s3),
              _StatusPill(label: statusLabel, online: online),
            ],
          ),
          const SizedBox(height: SgSpace.s4),
          if (earningsFailed)
            _NoirLoadError(
              key: const Key('home_earnings_error'),
              message: l.loadErrEarnings,
              retryLabel: l.earnRetry,
              onRetry: onRetryEarnings,
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _NoirTile(
                      key: const Key('home_earnings_card'),
                      label: l.homeTodayEarned,
                      value: earnings,
                      valueKey: const Key('home_earnings'),
                      gold: true,
                      onTap: onEarnings,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NoirTile(
                      label: l.homeTripsToday,
                      value: trips == null ? null : '$trips',
                      valueKey: const Key('home_trips'),
                      onTap: onEarnings,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: SgSpace.s4),
          if (online)
            _NoirButton(
              key: const Key('home_go_offline'),
              label: busy ? l.commonPleaseWait : l.homeGoOffline,
              onPressed: busy ? null : onGoOffline,
              primary: false,
            )
          else
            _NoirButton(
              key: const Key('home_go_online'),
              label: busy ? l.commonPleaseWait : l.homeGoOnline,
              onPressed: busy || blocker != null ? null : onGoOnline,
              primary: true,
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.online});

  final String label;
  final bool online;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('home_status_pill'),
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: online ? SgStatus.okBg : SgNoir.pill,
      borderRadius: BorderRadius.circular(SgRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (online) ...[
          Container(
            key: const Key('home_status_dot'),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SgStatus.okInk,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: SgText.small.copyWith(
            fontWeight: FontWeight.w600,
            color: online ? SgStatus.okInk : SgNoir.pillInk,
          ),
        ),
      ],
    ),
  );
}

class _NoirTile extends StatelessWidget {
  const _NoirTile({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
    this.gold = false,
    this.onTap,
  });

  final String label;

  /// Null while loading: a skeleton bar the size of the figure.
  final String? value;
  final Key? valueKey;
  final bool gold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: SgNoir.tile,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              style: SgText.small.copyWith(color: SgNoir.inkMuted),
            ),
            const SizedBox(height: 4),
            if (value == null)
              SgSkeletonBar(
                key: valueKey == null
                    ? null
                    : Key('${_keyName(valueKey!)}_loading'),
                width: 88,
                height: 28,
                color: SgNoir.inkMuted.withValues(alpha: 0.25),
              )
            else
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value!,
                  key: valueKey,
                  maxLines: 1,
                  style: SgText.heading.copyWith(
                    color: gold ? SgNoir.gold : SgNoir.ink,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  static String _keyName(Key k) =>
      k is ValueKey<String> ? k.value : k.toString();
}

/// A section that failed to load, on the dark sheet: what failed and a
/// Try again that refetches.
class _NoirLoadError extends StatelessWidget {
  const _NoirLoadError({
    super.key,
    required this.message,
    required this.retryLabel,
    this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
    decoration: BoxDecoration(
      color: SgNoir.tile,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(message, style: SgText.body.copyWith(color: SgNoir.ink)),
        ),
        TextButton(
          key: const Key('home_earnings_retry'),
          onPressed: onRetry,
          child: Text(
            retryLabel,
            style: SgText.body.copyWith(
              color: SgNoir.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 72px, radius 18: amber "Go online" with the power icon, or an outlined
/// "Go offline" on the dark sheet.
class _NoirButton extends StatelessWidget {
  const _NoirButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    final fg = primary
        ? (on ? SgNoir.onAmber : SgNoir.inkMuted)
        : (on ? SgNoir.ink : SgNoir.inkMuted);
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: primary ? (on ? SgNoir.amber : SgNoir.pill) : SgNoir.sheet,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: primary
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SgNoir.line),
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SgIcon(
                  '<path d="M12 3v9"/><path d="M6.3 7.3a8 8 0 1 0 11.4 0"/>',
                  size: 24,
                  color: fg,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: SgText.title.copyWith(color: fg),
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
          TextSpan(
            text: symbol,
            style: TextStyle(color: symbolColor),
          ),
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
                    fontWeight: FontWeight.w600,
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
                          if (earnings == null)
                            const SgSkeletonBar(width: 120, height: 32)
                          else
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: GoldSymbolAmount(
                                earnings!,
                                key: const Key('home_earnings'),
                                symbolColor: p.goldText,
                                style: SgText.bigFare.copyWith(color: p.ink),
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
      color: SgStatus.warnBg,
      borderRadius: BorderRadius.circular(SgRadius.md),
      border: Border.all(color: SgStatus.warnLine),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: SgText.small.copyWith(
              color: SgColors.ink,
              fontWeight: FontWeight.w600,
            ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
