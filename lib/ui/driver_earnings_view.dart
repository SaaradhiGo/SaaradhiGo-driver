/// Tier 3 screen 5, earnings: the period card on a noir panel, the 7-day bar
/// chart, and the withdrawable balance with its 64px Withdraw. Pure views.
library;

import 'package:flutter/material.dart';

import 'driver_f_logic.dart';
import 'driver_home_view.dart';
import 'sg_l10n.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';

/// Period tabs, 64px tall.
class EarningsPeriodTabs extends StatelessWidget {
  const EarningsPeriodTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final labels = [l.earnPeriodToday, l.earnPeriodWeek, l.earnPeriodMonth];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SgColors.bg200,
        borderRadius: BorderRadius.circular(SgRadius.md + 4),
        border: Border.all(color: SgColors.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: Material(
                  color: i == selected ? SgColors.bg100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(SgRadius.md),
                  child: InkWell(
                    key: Key('earn_period_$i'),
                    borderRadius: BorderRadius.circular(SgRadius.md),
                    onTap: () => onSelect(i),
                    child: SizedBox(
                      height: 56,
                      child: Center(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SgText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: i == selected
                                ? SgColors.ink
                                : SgColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The period's figure on a noir panel (both themes): "Today · N trips",
/// the amount at 56px with a gold ₹ (net when the API sends it), commission
/// beside it.
class EarningsNoirPanel extends StatelessWidget {
  const EarningsNoirPanel({
    super.key,
    required this.periodLabel,
    required this.trips,
    required this.amount,
    required this.isNet,
    this.commission,
    this.commissionRate,
  });

  final String periodLabel;
  final int trips;
  final String amount;
  final bool isNet;
  final String? commission;
  final String? commissionRate;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    const p = SgPalette.dark;
    return Container(
      key: const Key('earnings_summary'),
      padding: const EdgeInsets.all(SgSpace.s5),
      decoration: BoxDecoration(
        color: p.bg000,
        borderRadius: BorderRadius.circular(SgRadius.xl),
        border: Border.all(color: p.goldLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$periodLabel · ${l.earnTrips(trips)}',
            style: SgText.body.copyWith(
              color: p.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SgSpace.s1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: GoldSymbolAmount(
              amount,
              key: const Key('earnings_amount'),
              symbolColor: p.goldText,
              style: SgText.fareXl.copyWith(color: p.ink),
            ),
          ),
          Text(
            isNet ? l.homeYouKeep : l.earnEarned,
            style: SgText.body.copyWith(color: p.inkMuted),
          ),
          if (commission != null) ...[
            const SizedBox(height: SgSpace.s3),
            Container(height: 1, color: p.line),
            const SizedBox(height: SgSpace.s3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    commissionRate == null
                        ? l.homeCommission
                        : '${l.homeCommission} · $commissionRate',
                    style: SgText.body.copyWith(color: p.inkMuted),
                  ),
                ),
                Text(
                  commission!,
                  key: const Key('earnings_commission'),
                  style: SgText.fare.copyWith(color: p.ink),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Seven bars of the backend's daily net; the last day in gold.
class EarningsWeekChart extends StatelessWidget {
  const EarningsWeekChart({super.key, required this.days, required this.money});

  final List<DailyEarning> days;

  /// Formats an amount in whole currency.
  final String Function(double) money;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final max = days.fold<double>(0, (m, d) => d.net > m ? d.net : m);
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    String dayLabel(DateTime d) =>
        locale == 'en' ? _weekdays[d.weekday - 1] : '${d.day}';
    return Container(
      key: const Key('earnings_week_chart'),
      padding: const EdgeInsets.all(SgSpace.s4),
      decoration: BoxDecoration(
        color: SgColors.bg100,
        borderRadius: BorderRadius.circular(SgRadius.xl),
        border: Border.all(color: SgColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.earnLast7, style: SgText.title)),
              Text(
                money(days.fold<double>(0, (s, d) => s + d.net)),
                style: SgText.fare,
              ),
            ],
          ),
          const SizedBox(height: SgSpace.s4),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: Semantics(
                      label:
                          '${days[i].date.day}/${days[i].date.month}: '
                          '${money(days[i].net)}',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: max <= 0
                                    ? 0.02
                                    : (days[i].net / max).clamp(0.02, 1.0),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i == days.length - 1
                                        ? SgColors.gold500
                                        : SgColors.bg300,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: SgSpace.s2),
                          Text(
                            dayLabel(days[i].date),
                            style: SgText.caption.copyWith(
                              fontWeight: i == days.length - 1
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: i == days.length - 1
                                  ? SgColors.ink
                                  : SgColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Withdrawable balance and the 64px Withdraw, or the reason it is blocked.
class WithdrawPanel extends StatelessWidget {
  const WithdrawPanel({
    super.key,
    required this.balance,
    required this.canWithdraw,
    this.payoutMissing = false,
    this.onWithdraw,
    this.onAddPayout,
  });

  final String balance;
  final bool canWithdraw;

  /// `payout_details_on_file` is false: Withdraw stays off with its reason.
  final bool payoutMissing;
  final VoidCallback? onWithdraw;
  final VoidCallback? onAddPayout;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final enabled = canWithdraw && !payoutMissing && onWithdraw != null;
    return Container(
      key: const Key('earnings_payout'),
      padding: const EdgeInsets.all(SgSpace.s4),
      decoration: BoxDecoration(
        color: SgColors.bg100,
        borderRadius: BorderRadius.circular(SgRadius.xl),
        border: Border.all(color: SgColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.earnWithdrawable, style: SgText.body)),
              Text(balance, style: SgText.fare),
            ],
          ),
          if (payoutMissing) ...[
            const SizedBox(height: SgSpace.s2),
            Text(
              l.earnPayoutMissing,
              key: const Key('earnings_payout_missing'),
              style: SgText.body.copyWith(color: SgColors.danger),
            ),
          ],
          const SizedBox(height: SgSpace.s3),
          Material(
            color: enabled ? SgColors.gold500 : SgColors.bg300,
            borderRadius: BorderRadius.circular(SgRadius.md),
            child: InkWell(
              key: const Key('earnings_withdraw'),
              borderRadius: BorderRadius.circular(SgRadius.md),
              onTap: enabled ? onWithdraw : null,
              child: SizedBox(
                height: kSgTouch,
                child: Center(
                  child: Text(
                    l.earnWithdraw(balance),
                    style: SgText.button.copyWith(
                      fontSize: SgText.sizeTitle,
                      color: enabled ? SgColors.onGold : SgColors.inkSubtle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (payoutMissing && onAddPayout != null)
            InkWell(
              key: const Key('earnings_add_payout'),
              onTap: onAddPayout,
              borderRadius: BorderRadius.circular(SgRadius.md),
              child: SizedBox(
                height: kSgTouch,
                child: Center(
                  child: Text(
                    l.earnAddPayout,
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
}
