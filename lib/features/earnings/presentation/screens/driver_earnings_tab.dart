import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../ui/driver_shell.dart';
import '../../../../ui/sg_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../providers/earnings_providers.dart';

/// One period's totals from `GET /driver/earnings/period/?period=`, or null
/// when the endpoint is not there (an older backend) or fails.
final driverEarningsPeriodProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, period) async {
      try {
        final res = await ref
            .watch(dioClientProvider)
            .dio
            .get(
              '/driver/earnings/period/',
              queryParameters: {'period': period},
            );
        final body = res.data;
        final data = body is Map<String, dynamic> && body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : (body is Map<String, dynamic> ? body : null);
        if (data == null || !data.containsKey('net')) return null;
        return data;
      } on Object {
        return null;
      }
    });

/// The Earnings tab (signed-in designs, 2026-11-08): Today / Week / Month,
/// the net on a dark card, the breakdown and what is ready to withdraw.
/// Every figure is one the API returned; a missing one hides its row.
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

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final state = ref.watch(earningsNotifierProvider);
    final summary = state.summary;
    final balance = state.withdrawalBalance;
    // The period endpoint decides whether Week and Month exist at all.
    final todayPeriod = ref.watch(driverEarningsPeriodProvider('today'));
    final hasPeriods = todayPeriod.asData?.value != null;
    final period = hasPeriods
        ? ref.watch(driverEarningsPeriodProvider(_period)).asData?.value
        : null;

    String? currency = period?['currency']?.toString();
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
    final hero = sgMoney(net ?? gross, currency: currency);
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
        : sgMoney(balance.availableBalance, currency: balance.currency);

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
                  if (hasPeriods) ...[
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
                  Container(
                    key: const Key('earn_hero'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SgNoir.sheet,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heroLabel,
                          style: SgText.small.copyWith(color: SgNoir.inkMuted),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            hero ?? '–',
                            key: const Key('earn_hero_amount'),
                            style: SgText.display.copyWith(color: SgNoir.gold),
                          ),
                        ),
                        if (meta.isNotEmpty)
                          Text(
                            meta,
                            style: SgText.small.copyWith(
                              color: SgNoir.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
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
                        ?_row(
                          l.earnTripFares,
                          sgMoney(gross, currency: currency),
                        ),
                        ?_row(
                          l.homeCommission,
                          _minus(sgMoney(commission, currency: currency)),
                          color: SgColors.danger,
                        ),
                        if (DriverDesignFlags.tipsRow) ?_row(l.earnTips, null),
                        ?_row(
                          l.earnYouEarned,
                          sgMoney(net, currency: currency),
                          strong: true,
                          color: SgColors.pickup,
                        ),
                        ?_row(
                          l.earnCashCollected,
                          _minus(sgMoney(cash, currency: currency)),
                        ),
                        ?_row(l.earnReadyToWithdraw, ready, strong: true),
                      ],
                    ),
                  ),
                  if (DriverDesignFlags.withdrawButton && ready != null) ...[
                    const SizedBox(height: SgSpace.s3),
                    Text(l.earnWithdraw(ready)),
                  ],
                  const SizedBox(height: SgSpace.s3),
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

  /// `start` and `end` are the period's first and last local days.
  String? _range(Map<String, dynamic> p) {
    final s = DateTime.tryParse('${p['start']}');
    final e = DateTime.tryParse('${p['end']}');
    if (s == null) return null;
    final start = sgDay(s);
    if (e == null || !e.isAfter(s)) return start;
    return '$start – ${sgDay(e)}';
  }

  /// "− ₹860"; a zero amount carries no minus.
  String? _minus(String? v) {
    if (v == null) return null;
    return RegExp(r'[1-9]').hasMatch(v) ? '− $v' : v;
  }

  Widget? _row(String label, String? value, {bool strong = false, Color? color}) {
    if (value == null) return null;
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
          Text(
            value,
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
