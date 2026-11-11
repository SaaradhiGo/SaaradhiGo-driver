import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/load_timeout.dart';
import '../../../../ui/driver_shell.dart';
import '../../../../ui/sg_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../widgets/payout_plan_line.dart';
import '../widgets/platform_fee_section.dart';
import '../../../../ui/sg_load_state.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../providers/earnings_providers.dart';

/// One period's totals from `GET /driver/earnings/period/?period=`.
///
/// Null only when the endpoint is not there (a 404 from an older backend):
/// the tab then falls back to the summary. Any other failure, or no answer
/// within [kLoadTimeout], is an error the card shows with Try again; it
/// used to be swallowed into null, which left the card on a dash for good.
final driverEarningsPeriodProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, period) async {
      try {
        final res = await ref
            .watch(dioClientProvider)
            .dio
            .get(
              '/driver/earnings/period/',
              queryParameters: {'period': period},
            )
            .timeout(kLoadTimeout);
        final body = res.data;
        final data = body is Map<String, dynamic> && body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : (body is Map<String, dynamic> ? body : null);
        if (data == null || !data.containsKey('net')) return null;
        return data;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    }, retry: (_, _) => null); // Try again is the driver's call, not a loop.

enum _Phase { loading, ready, failed }

/// The Earnings tab (signed-in designs, 2026-11-08): Today / Week / Month,
/// the net on a dark card, the breakdown and what is ready to withdraw.
/// Every figure is one the API returned. Each card loads on its own and ends
/// as a skeleton (at most [kLoadTimeout]), the figures, zeros, or an error
/// with Try again.
class DriverEarningsTab extends ConsumerStatefulWidget {
  const DriverEarningsTab({super.key});

  @override
  ConsumerState<DriverEarningsTab> createState() => _DriverEarningsTabState();
}

class _DriverEarningsTabState extends ConsumerState<DriverEarningsTab> {
  String _period = 'today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final n = ref.read(earningsNotifierProvider.notifier);
      if (ref.read(earningsNotifierProvider).summary == null) {
        n.loadInitialData();
      } else {
        n.refresh();
      }
    });
  }

  void _retry() {
    ref.invalidate(driverEarningsPeriodProvider);
    ref.read(earningsNotifierProvider.notifier).loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final state = ref.watch(earningsNotifierProvider);
    final summary = state.summary;
    final balance = state.withdrawalBalance;
    // The period endpoint decides whether Week and Month exist at all; only
    // a 404 (an older backend) takes them away.
    final todayPeriod = ref.watch(driverEarningsPeriodProvider('today'));
    final noPeriods = todayPeriod.hasValue && todayPeriod.value == null;
    final periodAsync = noPeriods
        ? null
        : ref.watch(driverEarningsPeriodProvider(_period));
    final period = periodAsync?.asData?.value;

    final _Phase phase;
    if (periodAsync != null) {
      phase = periodAsync.hasError && !periodAsync.isLoading
          ? _Phase.failed
          : (periodAsync.hasValue && !periodAsync.isLoading
                ? _Phase.ready
                : _Phase.loading);
    } else {
      phase = summary != null
          ? _Phase.ready
          : (state.summaryFailed ? _Phase.failed : _Phase.loading);
    }

    // The period names its currency; the summary does from backend #186; the
    // balance always has. The market's is the last resort inside sgMoney.
    final String? currency =
        period?['currency']?.toString() ??
        summary?.currency ??
        balance?.currency;
    String? money(Object? v) => sgMoney(v, currency: currency, whole: false);
    // While a card loads it shows skeletons, not a stale or partial figure.
    String? shown(Object? v) => phase == _Phase.ready ? money(v) : null;

    Object? gross, commission, net, cash;
    int? trips;
    if (period != null) {
      gross = period['gross'];
      commission = period['commission'];
      net = period['net'];
      cash = period['cash_collected'];
      trips = int.tryParse('${period['trips']}');
    } else if (summary != null && _period == 'today') {
      gross = summary.todayEarned;
      commission = summary.todayCommission;
      net = summary.todayNet;
      trips = summary.todayTrips;
    }
    final hero = money(net ?? gross);
    final heroLabel = switch (_period) {
      'week' => l.earnPeriodWeek,
      'month' => l.earnPeriodMonth,
      _ => l.earnHeroToday,
    };
    final meta = [
      if (period != null)
        ?_range(period)
      else if (_period == 'today')
        sgDay(DateTime.now()),
      if (trips != null) l.earnTripsCount(trips),
      if (net != null && commission != null) l.earnAfterCommission,
    ].join(' · ');
    final ready = balance == null
        ? null
        : sgMoney(
            balance.availableBalance,
            currency: balance.currency ?? currency,
            whole: false,
          );
    final noTrips =
        state.listLoaded && state.earningsList.isEmpty && (trips ?? 0) == 0;
    final noPayouts = state.historyLoaded && state.withdrawalHistory.isEmpty;

    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DriverTopBar(title: l.navEarnings),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(driverEarningsPeriodProvider);
                await ref.read(earningsNotifierProvider.notifier).refresh();
              },
              child: ListView(
                padding: const EdgeInsets.all(SgSpace.s4),
                children: [
                  if (!noPeriods) ...[
                    Row(
                      children: [
                        for (final (key, label) in [
                          ('today', l.homeToday),
                          ('week', l.earnChipWeek),
                          ('month', l.earnChipMonth),
                        ]) ...[
                          _Chip(
                            key: Key('earn_chip_$key'),
                            label: label,
                            selected: _period == key,
                            onTap: () => setState(() => _period = key),
                          ),
                          const SizedBox(width: SgSpace.s2),
                        ],
                      ],
                    ),
                    const SizedBox(height: SgSpace.s3),
                  ],
                  if (phase == _Phase.failed)
                    SgLoadError(
                      key: const Key('earn_error'),
                      retryKey: const Key('earn_retry'),
                      message: l.loadErrEarnings,
                      retryLabel: l.earnRetry,
                      onRetry: _retry,
                    )
                  else
                    _hero(heroLabel, phase == _Phase.ready ? hero : null, meta),
                  const SizedBox(height: SgSpace.s3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SgSpace.s4,
                      vertical: SgSpace.s1,
                    ),
                    decoration: BoxDecoration(
                      color: SgColors.bg100,
                      borderRadius: BorderRadius.circular(SgRadius.md),
                      border: Border.all(color: SgColors.line),
                    ),
                    child: Column(
                      children: [
                        if (phase != _Phase.failed) ...[
                          ?_row(
                            l.earnTripFares,
                            shown(gross),
                            loading: phase == _Phase.loading,
                          ),
                          ?_row(
                            l.homeCommission,
                            _minus(shown(commission)),
                            color: SgColors.danger,
                            loading: phase == _Phase.loading,
                          ),
                          if (DriverDesignFlags.tipsRow)
                            ?_row(l.earnTips, null),
                          ?_row(
                            l.earnYouEarned,
                            shown(net),
                            strong: true,
                            color: SgColors.pickup,
                            loading: phase == _Phase.loading,
                          ),
                          ?_row(
                            l.earnCashCollected,
                            _minus(shown(cash)),
                            loading: phase == _Phase.loading && !noPeriods,
                          ),
                        ],
                        if (balance == null && state.balanceFailed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l.loadErrBalance,
                                    key: const Key('earn_balance_error'),
                                    style: SgText.body,
                                  ),
                                ),
                                TextButton(
                                  key: const Key('earn_balance_retry'),
                                  onPressed: _retry,
                                  child: Text(
                                    l.earnRetry,
                                    style: SgText.body.copyWith(
                                      color: SgColors.goldText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ?_row(
                            l.earnReadyToWithdraw,
                            ready,
                            strong: true,
                            loading: balance == null,
                            valueKey: const Key('earn_ready'),
                          ),
                      ],
                    ),
                  ),
                  if (DriverDesignFlags.withdrawButton && ready != null) ...[
                    const SizedBox(height: SgSpace.s3),
                    Text(l.earnWithdraw(ready)),
                  ],
                  PayoutPlanLine(available: balance?.availableBalance),
                  const PlatformFeeSection(),
                  if (noTrips) ...[
                    const SizedBox(height: SgSpace.s3),
                    _EmptyNote(
                      key: const Key('earn_no_trips'),
                      title: l.earnNoTrips,
                      body: l.earnNoTripsHint,
                    ),
                  ],
                  if (noPayouts) ...[
                    const SizedBox(height: SgSpace.s3),
                    _EmptyNote(
                      key: const Key('earn_no_payouts'),
                      title: l.earnNoPayouts,
                    ),
                  ],
                  const SizedBox(height: SgSpace.s3),
                  Center(
                    child: TextButton(
                      key: const Key('earn_by_period'),
                      onPressed: () => context.push('/earnings/history'),
                      child: Text(
                        l.earnHistOpen,
                        style: SgText.body.copyWith(
                          color: SgColors.goldText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      key: const Key('earn_all_history'),
                      onPressed: () => context.push('/earnings/all'),
                      child: Text(
                        l.earnAllHistory,
                        style: SgText.body.copyWith(
                          color: SgColors.goldText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The dark hero card; [amount] null draws the skeleton in its place.
  Widget _hero(String label, String? amount, String meta) => Container(
    key: const Key('earn_hero'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: SgNoir.sheet,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SgText.small.copyWith(color: SgNoir.inkMuted)),
        if (amount == null) ...[
          const SizedBox(height: 8),
          SgSkeletonBar(
            key: const Key('earn_hero_loading'),
            width: 160,
            height: 40,
            color: SgNoir.inkMuted.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 8),
          SgSkeletonBar(
            width: 120,
            height: 14,
            color: SgNoir.inkMuted.withValues(alpha: 0.25),
          ),
        ] else ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              key: const Key('earn_hero_amount'),
              style: SgText.display.copyWith(color: SgNoir.gold),
            ),
          ),
          if (meta.isNotEmpty)
            Text(meta, style: SgText.small.copyWith(color: SgNoir.inkMuted)),
        ],
      ],
    ),
  );

  /// `start` and `end` are the period's first and last local days.
  String? _range(Map<String, dynamic> p) {
    final s = DateTime.tryParse('${p['start']}');
    final e = DateTime.tryParse('${p['end']}');
    if (s == null) return null;
    final start = sgDay(s);
    if (e == null || !e.isAfter(s)) return start;
    return '$start – ${sgDay(e)}';
  }

  /// "− ₹860.00"; a zero amount carries no minus.
  String? _minus(String? v) {
    if (v == null) return null;
    return RegExp(r'[1-9]').hasMatch(v) ? '− $v' : v;
  }

  /// A breakdown row; hidden when the API sent no such figure, a skeleton
  /// bar while [loading].
  Widget? _row(
    String label,
    String? value, {
    bool strong = false,
    Color? color,
    bool loading = false,
    Key? valueKey,
  }) {
    if (value == null && !loading) return null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: SgColors.bg200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: SgText.body.copyWith(
                fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (value == null)
            const SgSkeletonBar(width: 72, height: 18)
          else
            Text(
              value,
              key: valueKey,
              style: (strong ? SgText.title : SgText.body).copyWith(
                fontWeight: FontWeight.w600,
                color: color ?? SgColors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

/// "No trips yet" / "No payouts yet" for an account with nothing to list.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote({super.key, required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SgSpace.s4),
    decoration: BoxDecoration(
      color: SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.md),
      border: Border.all(color: SgColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: SgText.body.copyWith(fontWeight: FontWeight.w600)),
        if (body != null)
          Text(body!, style: SgText.small.copyWith(color: SgColors.inkMuted)),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? SgColors.ink : SgColors.bg100,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? SgColors.ink : SgColors.line),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: SgText.small.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? SgColors.bg100 : SgColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
