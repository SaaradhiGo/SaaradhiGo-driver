import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../ui/sg_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_load_state.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../../../requirements/requirements_api.dart' show requirementsProvider;
import '../../../trip_history/presentation/providers/trip_history_providers.dart';
import '../../data/earnings_history_api.dart';

/// The market the driver works in: the requirements' country, else read from the currency.
String earningsCountry(String? requirementsCountry, String currency) =>
    requirementsCountry ?? (currency == 'USD' ? 'US' : 'IN');

/// "October 2026", "Tue, 10 Nov 2026", "2 Nov – 8 Nov 2026", "2026", "Tax year 2026–27", or a
/// custom range in the market's date format.
String earningsPeriodLabel(
  EarningsHistory h,
  AppLocalizations l, {
  required String country,
}) {
  final lang = l.localeName;
  final s = h.start, e = h.end;
  return switch (h.period) {
    'day' => DateFormat('EEE, d MMM y', lang).format(s),
    'week' =>
      '${DateFormat('d MMM', lang).format(s)} – ${DateFormat('d MMM y', lang).format(e)}',
    'month' => DateFormat('MMMM y', lang).format(s),
    'year' => '${s.year}',
    'taxyear' => l.earnTaxYearLabel(
      '${s.year}',
      (e.year % 100).toString().padLeft(2, '0'),
    ),
    _ => '${sgMarketDate(s, country)} – ${sgMarketDate(e, country)}',
  };
}

/// `/earnings/history` (10 Nov v2): Day, Week, Month, Year (and the Indian tax year) or a
/// custom range; five summary cards, the chart, every month, and each month's statement.
class EarningsHistoryScreen extends ConsumerStatefulWidget {
  const EarningsHistoryScreen({super.key});

  @override
  ConsumerState<EarningsHistoryScreen> createState() =>
      _EarningsHistoryScreenState();
}

class _EarningsHistoryScreenState extends ConsumerState<EarningsHistoryScreen> {
  String _period = 'month';
  String? _date, _start, _end;
  String? _downloading;

  HistoryQuery get _query => (
    period: _period,
    date: _date,
    start: _period == 'custom' ? _start : null,
    end: _period == 'custom' ? _end : null,
  );

  static String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Previous or next: the server's anchor; a custom range keeps its length.
  void _move(EarningsHistory h, String? anchor) {
    final a = anchor == null ? null : DateTime.tryParse(anchor);
    if (a == null) return;
    setState(() {
      if (_period == 'custom') {
        _start = _iso(a);
        _end = _iso(a.add(h.end.difference(h.start)));
      } else {
        _date = anchor;
      }
    });
  }

  void _choose(String period) => setState(() {
    _period = period;
    _date = null;
  });

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (r == null) return;
    setState(() {
      _period = 'custom';
      _date = null;
      _start = _iso(r.start);
      _end = _iso(r.end);
    });
  }

  Future<void> _statement(String month) async {
    final l = sgL10n(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = month);
    try {
      final bytes = await ref
          .read(earningsHistoryApiProvider)
          .statementPdf(month);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/saaradhigo-statement-$month.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.earnStatementFailed)));
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  Future<void> _dayTrips(DateTime day, String country, String currency) async {
    final l = sgL10n(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SgSpace.s4),
          child: FutureBuilder(
            future: ref
                .read(tripHistoryRemoteDataSourceProvider)
                .getDriverHistory(
                  status: 'completed',
                  dateRange: DateTimeRange(start: day, end: day),
                  pageSize: 50,
                ),
            builder: (c, snap) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.earnTripsOnDay(sgMarketDate(day, country)),
                  style: SgText.title,
                ),
                const SizedBox(height: SgSpace.s3),
                if (snap.connectionState != ConnectionState.done)
                  Center(
                    child: CircularProgressIndicator(color: SgColors.gold500),
                  )
                else if (snap.hasError)
                  Text(l.loadErrEarnings, style: SgText.body)
                else if (snap.data!.isEmpty)
                  Text(l.earnNoTripsDay, style: SgText.body)
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final t in snap.data!)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              t.destinationAddress ?? t.pickupAddress ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              t.createdAt == null
                                  ? ''
                                  : DateFormat('h:mm a', l.localeName).format(
                                      DateTime.parse(t.createdAt!).toLocal(),
                                    ),
                            ),
                            trailing: Text(
                              sgMoney2(
                                    t.driverEarning ?? t.finalFare,
                                    currency: currency,
                                  ) ??
                                  '',
                              style: SgText.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final hist = ref.watch(earningsHistoryProvider(_query));
    final months = ref.watch(earningsMonthsProvider);
    final reqCountry = ref.watch(requirementsProvider).asData?.value.country;
    final currency =
        hist.asData?.value.currency ?? months.asData?.value.currency ?? '';
    final country = earningsCountry(reqCountry, currency);
    final india = country == 'IN';
    final yearly = _period == 'year' || _period == 'taxyear';

    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: Text(l.earnHistTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(earningsHistoryProvider);
            ref.invalidate(earningsMonthsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(SgSpace.s4),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (key, label) in [
                      ('day', l.earnPerDay),
                      ('week', l.earnPerWeek),
                      ('month', l.earnPerMonth),
                      ('year', l.earnPerYear),
                    ])
                      _Chip(
                        key: Key('hist_chip_$key'),
                        label: label,
                        selected:
                            _period == key ||
                            (key == 'year' && _period == 'taxyear'),
                        onTap: () => _choose(key),
                      ),
                    _Chip(
                      key: const Key('hist_chip_custom'),
                      label: l.earnPerCustom,
                      selected: _period == 'custom',
                      onTap: _pickRange,
                    ),
                  ],
                ),
              ),
              if (yearly && india) ...[
                const SizedBox(height: SgSpace.s2),
                Row(
                  children: [
                    _Chip(
                      key: const Key('hist_chip_calendar'),
                      label: l.earnCalendarYear,
                      selected: _period == 'year',
                      onTap: () => _choose('year'),
                    ),
                    Flexible(
                      child: _Chip(
                        key: const Key('hist_chip_taxyear'),
                        label: l.earnTaxYear,
                        selected: _period == 'taxyear',
                        onTap: () => _choose('taxyear'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: SgSpace.s3),
              hist.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: SgSpace.s5),
                  child: SgSkeletonBar(width: double.infinity, height: 160),
                ),
                error: (_, _) => SgLoadError(
                  message: l.loadErrEarnings,
                  retryLabel: l.earnRetry,
                  onRetry: () => ref.invalidate(earningsHistoryProvider),
                ),
                data: (h) => _periodView(h, l, country),
              ),
              const SizedBox(height: SgSpace.s5),
              Text(l.earnAllMonths, style: SgText.title),
              const SizedBox(height: SgSpace.s2),
              months.when(
                loading: () =>
                    const SgSkeletonBar(width: double.infinity, height: 80),
                error: (_, _) => SgLoadError(
                  message: l.loadErrEarnings,
                  retryLabel: l.earnRetry,
                  onRetry: () => ref.invalidate(earningsMonthsProvider),
                ),
                data: (m) => Column(
                  children: [
                    for (final row in m.months) _monthRow(row, m.currency, l),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodView(EarningsHistory h, AppLocalizations l, String country) {
    String? money(String key) => sgMoney2(h.s(key), currency: h.currency);
    final cash = double.tryParse(h.s('cash_collected') ?? '') ?? 0;
    final tipsOn = h.summary['tips_enabled'] == true;
    final paidSub = [
      l.earnPayoutsCount(h.n('payouts')),
      if (cash > 0) l.earnRestInCash,
    ].join(' · ');
    final note = h.s('fee_note');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('hist_prev'),
              tooltip: l.earnPrev,
              onPressed: h.hasPrev ? () => _move(h, h.prev) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                earningsPeriodLabel(h, l, country: country),
                key: const Key('hist_label'),
                textAlign: TextAlign.center,
                style: SgText.title,
              ),
            ),
            IconButton(
              key: const Key('hist_next'),
              tooltip: l.earnNext,
              onPressed: h.hasNext ? () => _move(h, h.next) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: SgSpace.s2),
        _Card(
          key: const Key('hist_earned'),
          label: l.earnYouEarned,
          value: money('earned') ?? '',
          sub: l.earnTripsCount(h.n('trips')),
          big: true,
        ),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - SgSpace.s2) / 2;
            return Wrap(
              spacing: SgSpace.s2,
              children: [
                SizedBox(
                  width: w,
                  child: _Card(
                    key: const Key('hist_fares'),
                    label: l.earnTripFares,
                    value: money('fares') ?? '',
                    sub: l.earnAvgPerTrip(money('avg_fare') ?? ''),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _Card(
                    key: const Key('hist_fee'),
                    label: l.earnPlatformFee,
                    value: '− ${money('platform_fee') ?? ''}',
                    sub: (note == null || note.isEmpty) ? null : note,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _Card(
                    key: const Key('hist_tips'),
                    label: l.earnTips,
                    value: tipsOn ? '+ ${money('tips') ?? ''}' : '',
                    sub: tipsOn
                        ? l.earnTipsFrom(h.n('tip_riders'))
                        : l.earnTipsOff,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _Card(
                    key: const Key('hist_paid'),
                    label: l.earnPaidToBank,
                    value: money('paid_to_bank') ?? '',
                    sub: paidSub,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: SgSpace.s3),
        _Chart(
          history: h,
          onDay: h.unit == 'day'
              ? (d) => _dayTrips(d, country, h.currency)
              : null,
        ),
      ],
    );
  }

  Widget _monthRow(Json m, String currency, AppLocalizations l) {
    final key = m['month'] as String;
    final first = DateTime.parse('$key-01');
    String money(String k) => sgMoney2(m[k], currency: currency) ?? '';
    final name = DateFormat('MMMM y', l.localeName).format(first);
    final trips = int.tryParse('${m['trips']}') ?? 0;
    Widget cell(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: SgText.small.copyWith(color: SgColors.inkMuted),
            ),
          ),
          Text(value, style: SgText.small),
        ],
      ),
    );
    return Container(
      key: Key('hist_month_$key'),
      margin: const EdgeInsets.only(bottom: SgSpace.s2),
      padding: const EdgeInsets.all(SgSpace.s3),
      decoration: BoxDecoration(
        color: SgColors.bg100,
        borderRadius: BorderRadius.circular(SgRadius.md),
        border: Border.all(color: SgColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m['so_far'] == true ? '$name ${l.earnSoFar}' : name,
                  style: SgText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                key: Key('hist_statement_$key'),
                onPressed: _downloading == null ? () => _statement(key) : null,
                icon: _downloading == key
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(l.earnStatement),
              ),
            ],
          ),
          cell(l.earnColTrips, '$trips'),
          cell(l.earnTripFares, money('fares')),
          cell(l.earnPlatformFee, '− ${money('platform_fee')}'),
          cell(l.earnTips, money('tips')),
          cell(l.earnYouEarned, money('earned')),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.big = false,
  });
  final String label, value;
  final String? sub;
  final bool big;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: SgSpace.s2),
    padding: const EdgeInsets.all(SgSpace.s3),
    decoration: BoxDecoration(
      color: big ? SgNoir.sheet : SgColors.bg100,
      borderRadius: BorderRadius.circular(SgRadius.md),
      border: big ? null : Border.all(color: SgColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SgText.small.copyWith(
            color: big ? SgNoir.inkMuted : SgColors.inkMuted,
          ),
        ),
        if (value.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: (big ? SgText.display : SgText.figure).copyWith(
                color: big ? SgNoir.gold : SgColors.ink,
              ),
            ),
          ),
        if (sub != null && sub!.isNotEmpty)
          Text(
            sub!,
            style: SgText.small.copyWith(
              color: big ? SgNoir.inkMuted : SgColors.inkMuted,
            ),
          ),
      ],
    ),
  );
}

/// Bars from `chart.bars`; with day bars, a tap opens that day's trips.
class _Chart extends StatelessWidget {
  const _Chart({required this.history, this.onDay});
  final EarningsHistory history;
  final ValueChanged<DateTime>? onDay;

  String _tick(EarningsBar b, int i, String lang) {
    switch (history.unit) {
      case 'hour':
        return i % 6 == 0 ? b.key : '';
      case 'month':
        final d = DateTime.tryParse('${b.key}-01');
        return d == null ? '' : DateFormat('MMM', lang).format(d)[0];
      default:
        final d = DateTime.tryParse(b.key);
        final every = history.bars.length > 10 ? 5 : 1;
        return d == null || (i % every != 0) ? '' : '${d.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = sgL10n(context).localeName;
    final values = [
      for (final b in history.bars) (double.tryParse(b.earned) ?? 0),
    ];
    final top = values.fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      key: const Key('hist_chart'),
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < history.bars.length; i++)
            Expanded(
              child: GestureDetector(
                key: Key('hist_bar_${history.bars[i].key}'),
                behavior: HitTestBehavior.opaque,
                onTap: onDay == null
                    ? null
                    : () {
                        final d = DateTime.tryParse(history.bars[i].key);
                        if (d != null) onDay!(d);
                      },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: top <= 0
                          ? 2
                          : 2 + 110 * (values[i] < 0 ? 0 : values[i] / top),
                      decoration: BoxDecoration(
                        color: values[i] > 0
                            ? SgColors.gold500
                            : SgColors.bg300,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 16,
                      child: Text(
                        _tick(history.bars[i], i, lang),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: SgText.small.copyWith(
                          fontSize: 10,
                          color: SgColors.inkMuted,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: SgSpace.s2),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
