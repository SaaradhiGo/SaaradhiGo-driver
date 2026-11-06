// Tier 3 PR F: the 7-day series, the documents checklist, and the earnings
// and documents views.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/driver_documents_view.dart';
import 'package:saaradhigo_driver/ui/driver_earnings_view.dart';
import 'package:saaradhigo_driver/ui/driver_f_logic.dart';

import '../support/driver_ui_fixtures.dart';

void main() {
  setUpAll(loadSgFonts);

  group('daily earnings', () {
    test('parses and sorts the days by date', () {
      final days = parseDailyEarnings(sampleDailyBody)!;
      expect(days.length, 7);
      expect(days.first.date, DateTime(2026, 10, 31));
      expect(days.last.date, DateTime(2026, 11, 6));
      expect(days.last.net, 364);
      expect(days.last.trips, 3);
    });

    test('anything unexpected hides the chart', () {
      expect(parseDailyEarnings(null), isNull);
      expect(parseDailyEarnings({'days': []}), isNull);
      expect(parseDailyEarnings({'days': [{'date': 'x', 'net': '1'}]}), isNull);
      expect(parseDailyEarnings({'data': {'days': [{'date': '2026-11-06'}]}}),
          isNull);
      expect(
          parseDailyEarnings({
            'data': {
              'days': [
                {'date': '2026-11-06', 'net': '10.5', 'trips': 1}
              ]
            }
          })!
              .single
              .net,
          10.5);
    });
  });

  group('documents', () {
    test('counts done from the real list and puts the rejected one first',
        () {
      final o = parseDocsOverview(sampleDocsBody)!;
      expect(o.total, 5);
      expect(o.done, 1);
      expect(o.vehicleId, 7);
      expect(o.ordered.first.key, 'license_front');
      expect(o.ordered.first.reason, 'The photo is blurred.');
      expect(o.ordered[1].key, 'insurance');
      expect(o.ordered[1].state, DocState.missing);
      final permit = o.items.firstWhere((i) => i.key == 'permit');
      // Present, no per-item status, doc_status pending: never "approved".
      expect(permit.state, DocState.uploaded);
      expect(o.items.firstWhere((i) => i.key == 'rc').state,
          DocState.inReview);
    });

    test('without per-item status, approval follows doc_status only', () {
      expect(docStateOf({'present': true}, 'approved'), DocState.approved);
      expect(docStateOf({'present': true}, 'pending'), DocState.uploaded);
      expect(docStateOf({'present': true}, null), DocState.uploaded);
      expect(docStateOf({'present': false}, 'approved'), DocState.missing);
      expect(docStateOf({'present': true, 'status': 'rejected'}, 'approved'),
          DocState.rejected);
    });

    test('optional documents that are absent are left out', () {
      final o = parseDocsOverview({
        'driver_documents': [
          {'key': 'a', 'label': 'A', 'required': false, 'present': false},
          {'key': 'b', 'label': 'B', 'required': true, 'present': false},
        ],
      })!;
      expect(o.items.map((i) => i.key), ['b']);
      expect(parseDocsOverview({'foo': 1}), isNull);
    });

    test('only documents the existing upload knows get Open camera', () {
      expect(uploadKeyFor('license_front'), 'license_doc');
      expect(uploadKeyFor('license_back'), 'license_doc_back');
      expect(uploadKeyFor('rc'), 'rc_doc');
      expect(uploadKeyFor('insurance'), isNull);
    });

    testWidgets('the view: progress, rejected card, payout card, support',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var opened = 0, called = 0;
      await tester.pumpWidget(sgApp(DriverDocumentsView(
        overview: parseDocsOverview(sampleDocsBody)!,
        payoutMissing: true,
        canOpenCamera: (i) => uploadKeyFor(i.key) != null,
        onOpenCamera: (_) => opened++,
        onAddPayout: () {},
        onCallSupport: () => called++,
      )));
      expect(find.text('1 of 5 done'), findsOneWidget);
      expect(find.byKey(const Key('docs_rejected_license_front')),
          findsOneWidget);
      expect(find.text('The photo is blurred.'), findsOneWidget);
      expect(find.text('Payout details missing'), findsOneWidget);
      expect(find.text('Uploaded'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Not uploaded'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      await tester.tap(find.text('Open camera'));
      expect(opened, 1);
      await tester.scrollUntilVisible(
          find.byKey(const Key('docs_call_support')), 200);
      await tester.tap(find.byKey(const Key('docs_call_support')));
      expect(called, 1);
      expect(
          tester.getSize(find.byKey(const Key('docs_call_support'))).height,
          56);
    });
  });

  group('earnings views', () {
    testWidgets('noir panel, chart and a 56px Withdraw', (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(sgApp(ListView(children: [
        const EarningsNoirPanel(
          periodLabel: 'Today',
          trips: 3,
          amount: '₹364',
          isNet: true,
          commission: '₹64',
          commissionRate: '15%',
        ),
        EarningsWeekChart(
          days: parseDailyEarnings(sampleDailyBody)!,
          money: (v) => '₹${v.round()}',
        ),
        WithdrawPanel(balance: '₹1,240', canWithdraw: true, onWithdraw: () {}),
      ])));
      expect(find.text('Today · 3 trips'), findsOneWidget);
      expect(find.text('You keep'), findsOneWidget);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('₹2,549'), findsNothing);
      expect(find.text('₹2549'), findsOneWidget);
      expect(find.text('Withdraw ₹1,240'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('earnings_withdraw'))).height,
          56);
    });

    testWidgets('missing payout details keep Withdraw off with the reason',
        (tester) async {
      setPhoneSurface(tester);
      addTearDown(tester.view.reset);
      var withdrew = 0;
      await tester.pumpWidget(sgApp(WithdrawPanel(
        balance: '₹1,240',
        canWithdraw: true,
        payoutMissing: true,
        onWithdraw: () => withdrew++,
        onAddPayout: () {},
      )));
      expect(find.byKey(const Key('earnings_payout_missing')), findsOneWidget);
      await tester.tap(find.byKey(const Key('earnings_withdraw')));
      expect(withdrew, 0);
      expect(find.text('Add payout details'), findsOneWidget);
    });
  });
}
