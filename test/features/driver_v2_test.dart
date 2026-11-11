import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/earnings/data/earnings_history_api.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/screens/earnings_history_screen.dart';
import 'package:saaradhigo_driver/features/profile/presentation/widgets/profile_sections.dart';
import 'package:saaradhigo_driver/features/requirements/requirements_api.dart'
    show Requirements, requirementsProvider;
import 'package:saaradhigo_driver/l10n/app_localizations.dart';
import 'package:saaradhigo_driver/ui/sg_format.dart';

/// Driver area v2 (10 Nov): money with two decimals, dates in the market's order, and the
/// earnings history's period label, arrows and cards.

Json _history({bool hasNext = false, bool tips = false}) => {
  'period': 'month',
  'start': '2026-10-01',
  'end': '2026-10-31',
  'timezone': 'Asia/Kolkata',
  'currency': 'INR',
  'today': '2026-11-10',
  'joined': '2026-01-05',
  'has_prev': true,
  'has_next': hasNext,
  'prev': '2026-09-01',
  'next': '2026-11-01',
  'summary': {
    'trips': 12,
    'days_driven': 5,
    'fares': '1368.00',
    'avg_fare': '114.00',
    'commission': '100.00',
    'daily_fee': '20.00',
    'platform_fee': '120.00',
    'tips': '0.00',
    'tip_riders': 0,
    'earned': '1248.00',
    'paid_to_bank': '1000.00',
    'payouts': 2,
    'cash_collected': '248.00',
    'unresolved_trips': 0,
    'fee_note': 'Capped at ₹149.00 a day',
    'tips_enabled': tips,
  },
  'chart': {
    'unit': 'day',
    'bars': [
      {'key': '2026-10-01', 'earned': '100.00', 'trips': 1},
      {'key': '2026-10-02', 'earned': '0.00', 'trips': 0},
    ],
  },
};

class _FakeHistory extends EarningsHistoryApi {
  _FakeHistory(this.body) : super(Dio());
  final Json body;
  final asked = <HistoryQuery>[];
  @override
  Future<EarningsHistory> history(HistoryQuery q) async {
    asked.add(q);
    return EarningsHistory.fromJson({...body, 'period': q.period});
  }

  @override
  Future<EarningsMonths> months() async => EarningsMonths.fromJson({
    'currency': 'INR',
    'joined': '2026-01',
    'months': [
      {
        'month': '2026-11',
        'so_far': true,
        'trips': 3,
        'fares': '300.00',
        'platform_fee': '30.00',
        'tips': '0.00',
        'earned': '270.00',
      },
    ],
  });
}

Requirements _req(String country) => Requirements.fromJson({
  'config': {
    'country': country,
    'languages': ['en'],
  },
  'checklist': {
    'items': [],
    'done': 0,
    'total': 0,
    'blocking': [],
    'approved': false,
  },
});

Widget _app(EarningsHistoryApi api) => ProviderScope(
  overrides: [
    earningsHistoryApiProvider.overrideWithValue(api),
    requirementsProvider.overrideWith((ref) async => _req('IN')),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: EarningsHistoryScreen(),
  ),
);

void main() {
  test('money always has two decimals in the driver currency', () {
    expect(sgMoney2('114', currency: 'INR'), '₹114.00');
    expect(sgMoney2('1248.5', currency: 'INR'), '₹1,248.50');
    expect(sgMoney2(5, currency: 'USD'), r'$5.00');
    expect(sgMoney2('abc', currency: 'INR'), isNull);
  });

  test(
    'dates follow the market: dd/MM/yyyy in India, MM/dd/yyyy in the USA',
    () {
      final d = DateTime(2026, 11, 3);
      expect(sgMarketDate(d, 'IN'), '03/11/2026');
      expect(sgMarketDate(d, 'US'), '11/03/2026');
      expect(sgDateHint('IN'), 'dd/mm/yyyy');
      expect(sgDateHint('US'), 'mm/dd/yyyy');
    },
  );

  test('masks keep only the last four', () {
    expect(lastFourMasked('XXXX XXXX 4821'), '•••• 4821');
    expect(lastFourMasked('XXXXXXXX4417', gap: ''), '••••4417');
  });

  testWidgets('the period label, the arrows and the five cards', (t) async {
    t.view.physicalSize = const Size(1000, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final api = _FakeHistory(_history());
    await t.pumpWidget(_app(api));
    await t.pumpAndSettle();

    expect(find.text('October 2026'), findsOneWidget);
    final next = t.widget<IconButton>(find.byKey(const Key('hist_next')));
    final prev = t.widget<IconButton>(find.byKey(const Key('hist_prev')));
    expect(next.onPressed, isNull);
    expect(prev.onPressed, isNotNull);

    expect(find.text('₹1,248.00'), findsOneWidget);
    expect(find.text('Avg ₹114.00 per trip'), findsOneWidget);
    expect(find.text('− ₹120.00'), findsOneWidget);
    expect(find.text('Capped at ₹149.00 a day'), findsOneWidget);
    expect(find.text('Tips are not on yet'), findsOneWidget);
    expect(find.text('2 payouts · rest in cash'), findsOneWidget);
    expect(find.text('November 2026 (so far)'), findsOneWidget);

    await t.tap(find.byKey(const Key('hist_prev')));
    await t.pumpAndSettle();
    expect(api.asked.last.date, '2026-09-01');

    // India drivers get the tax year under Year.
    await t.tap(find.byKey(const Key('hist_chip_year')));
    await t.pumpAndSettle();
    expect(find.text('Indian tax year (Apr–Mar)'), findsOneWidget);
  });

  testWidgets('tips show with their riders once they are on', (t) async {
    t.view.physicalSize = const Size(1000, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(_FakeHistory(_history(hasNext: true, tips: true))));
    await t.pumpAndSettle();
    final next = t.widget<IconButton>(find.byKey(const Key('hist_next')));
    expect(next.onPressed, isNotNull);
    expect(find.text('+ ₹0.00'), findsOneWidget);
    expect(find.text('From 0 riders'), findsOneWidget);
  });
}
