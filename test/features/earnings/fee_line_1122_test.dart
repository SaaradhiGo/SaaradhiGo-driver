// Driver fee models (Srini's ruling, 22 Nov): the driver's fee line and upcoming-change notice.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/platform_fee_section.dart';

import '../../support/driver_ui_fixtures.dart';

Widget _scoped(Map<String, dynamic> body) => ProviderScope(
  overrides: [
    feePlanProvider.overrideWith((ref) async => body),
    feeNoteProvider.overrideWith((ref) async => null),
  ],
  child: sgApp(const Scaffold(body: PlatformFeeSection())),
);

Map<String, dynamic> _daily({String? notice}) => {
  'plan': {
    'plan_type': 'daily_pass', 'currency': 'INR', 'earnings_floor_minor': 0,
    'daily_cap_minor': null, 'waiver_first_days': 60,
  },
  'applies_to_my_class': true,
  'my_amounts': {'daily_pass_minor': 4900},
  'today': null,
  'fee_words': '₹49 daily fee, charged only if you complete a trip',
  'notice': notice,
};

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  testWidgets('shows the daily fee line', (tester) async {
    await tester.pumpWidget(_scoped(_daily()));
    await tester.pumpAndSettle();
    expect(find.text('Today: ₹49 daily fee, charged only if you complete a trip'), findsOneWidget);
    expect(find.byKey(const Key('earn_fee_notice')), findsNothing);
  });

  testWidgets('shows an approved change that has not started', (tester) async {
    await tester.pumpWidget(_scoped(_daily(notice: 'From 30 Nov: ₹49 daily fee, charged only if you complete a trip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('earn_fee_notice')), findsOneWidget);
  });

  testWidgets('a commission plan with its own percentage is shown', (tester) async {
    await tester.pumpWidget(_scoped({
      'plan': {'plan_type': 'percent_commission', 'currency': 'INR', 'earnings_floor_minor': 0},
      'applies_to_my_class': true,
      'my_amounts': {'commission_percent': 10},
      'fee_words': '10% of each fare',
    }));
    await tester.pumpAndSettle();
    expect(find.text('Today: 10% of each fare'), findsOneWidget);
  });
}
