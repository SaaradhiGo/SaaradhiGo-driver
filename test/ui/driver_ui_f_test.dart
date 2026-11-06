import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/auth/presentation/otp_verification_screen.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/earnings_display.dart';

import '../support/driver_ui_fixtures.dart';

void main() {
  test('ledger money is grouped and keeps paise only when there are any', () {
    expect(ledgerMoney('1151.29', symbol: '₹'), '₹1,151.29');
    expect(ledgerMoney('978.60', symbol: '₹'), '₹978.60');
    expect(ledgerMoney('979.00', symbol: '₹'), '₹979');
    expect(ledgerMoney('125000', symbol: '₹'), '₹1,25,000');
    expect(ledgerMoney('-600', symbol: '₹'), '-₹600');
    expect(ledgerMoney('1240.5', symbol: r'$'), r'$1,240.50');
    expect(ledgerMoney(null, symbol: '₹'), '₹0');
  });

  test('the OTP screen shows only the last four digits', () {
    expect(maskedPhone('+919876543210'), '+91 ••••• •3210');
    expect(maskedPhone('9876543210'), '••••• •3210');
    expect(maskedPhone('12'), '12');
  });

  test('summaries are whole currency, ledger lines keep paise', () {
    expect(summaryMoney('1151.29', symbol: '₹'), '₹1,151');
    expect(summaryMoney('978.50', symbol: '₹'), '₹979');
    expect(summaryMoney('172.69', symbol: '₹'), '₹173');
    expect(ledgerMoney('172.69', symbol: '₹'), '₹172.69');
  });

  testWidgets('Home shows what the driver keeps, with commission beside it',
      (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        sgApp(homeFrame(earnings: '₹979', commission: '₹173')));
    expect(find.text('You keep today'), findsOneWidget);
    expect(find.text('₹979'), findsOneWidget);
    expect(find.text('Commission ₹173'), findsOneWidget);

    await tester.pumpWidget(sgApp(homeFrame()));
    expect(find.text("Today's earnings"), findsOneWidget);
    expect(find.byKey(const Key('home_commission')), findsNothing);
  });
}
