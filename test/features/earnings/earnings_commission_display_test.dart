import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/earnings_display.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/earnings_breakdown_card.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('earnings display helpers', () {
    test('commissionRateLabel shows only what the API sent', () {
      expect(commissionRateLabel(null), isNull);
      expect(commissionRateLabel(15), '15%');
      expect(commissionRateLabel(15.0), '15%');
      expect(commissionRateLabel(12.5), '12.5%');
      expect(commissionRateLabel(14.2, mixed: true), '14.2% avg');
    });

    test('net and average are null when commission is unknown', () {
      expect(netFromGrossAndCommission('1000.00', null), isNull);
      expect(netFromGrossAndCommission(null, '150.00'), isNull);
      expect(netFromGrossAndCommission('1000.00', '150.00'), '850.00');
      expect(averageNetPerTrip(null, 4), isNull);
      expect(averageNetPerTrip('850.00', 0), isNull);
      expect(averageNetPerTrip('850.00', 5), '170');
    });

    test('the summary model has no built-in commission rate', () {
      const summary = EarningsSummaryModel();
      expect(summary.commissionPercent, isNull);
      expect(summary.totalCommission, isNull);
    });
  });

  group('EarningsBreakdownCard', () {
    testWidgets('shows commission and its rate exactly as given', (t) async {
      await t.pumpWidget(
        _host(
          const EarningsBreakdownCard(
            grossFares: '1000.00',
            commission: '150.00',
            commissionRate: '15%',
            netEarnings: '850.00',
          ),
        ),
      );
      expect(find.text('Platform Commission (15%)'), findsOneWidget);
      expect(find.text('-₹150.00'), findsOneWidget);
      expect(find.text('Net Driver Earnings'), findsOneWidget);
    });

    testWidgets('shows no commission line when the API sent none', (t) async {
      await t.pumpWidget(
        _host(const EarningsBreakdownCard(grossFares: '1000.00')),
      );
      expect(find.textContaining('Platform Commission'), findsNothing);
      expect(find.text('Net Driver Earnings'), findsNothing);
      expect(find.textContaining('10%'), findsNothing);
    });
  });
}
