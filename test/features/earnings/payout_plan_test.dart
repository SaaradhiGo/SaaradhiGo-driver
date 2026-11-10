import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_model.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/payout_plan.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/screens/earnings_dashboard_screen.dart';
import 'package:saaradhigo_driver/l10n/app_localizations_en.dart';

void main() {
  test('reads the next payout and whether Withdraw now is offered', () {
    final plan = parsePayoutPlan({
      'status': 'success',
      'data': {
        'available_balance': 347.0,
        'currency': 'INR',
        'next_payout': {
          'date': '2026-11-10',
          'at': '2026-11-10T10:00:00+05:30',
          'estimated_amount': '347.00',
          'currency': 'INR',
        },
        'instant': {
          'available': true,
          'provider': 'RazorpayX',
          'saaradhigo_fee': '0',
        },
      },
    })!;
    expect(plan.nextAt!.toUtc(), DateTime.utc(2026, 11, 10, 4, 30));
    expect(plan.estimatedAmount, '347.00');
    expect(plan.instantAvailable, isTrue);
    expect(plan.provider, 'RazorpayX');
  });

  test('on request and instant off: no date, no button', () {
    final plan = parsePayoutPlan({
      'data': {
        'next_payout': null,
        'instant': {'available': false},
      },
    })!;
    expect(plan.nextAt, isNull);
    expect(plan.instantAvailable, isFalse);
  });

  test('the confirmation carries the provider fee and SaaradhiGo fee 0', () {
    final q = parseInstantQuote({
      'data': {
        'amount': '500.00',
        'provider_fee': '4.72',
        'provider_fee_label': 'Provider fee (charged by RazorpayX)',
        'saaradhigo_fee': '0.00',
        'you_receive': '495.28',
        'currency': 'INR',
        'destination': 'UPI ••kaxis',
        'arrival': 'Usually within 30 minutes',
        'valid': true,
      },
    })!;
    expect(q.providerFee, '4.72');
    expect(q.saaradhigoFee, '0.00');
    expect(q.youReceive, '495.28');
    expect(q.valid, isTrue);
  });

  test('the daily limit reason is read for the confirmation (10 Nov)', () {
    final q = parseInstantQuote({
      'data': {
        'amount': '200.00',
        'provider_fee': '4.72',
        'you_receive': '195.28',
        'currency': 'INR',
        'valid': false,
        'limit_reached': true,
        'limit_message':
            'Daily limit reached: 3 instant withdrawals. Your next scheduled payout is 15 Nov.',
      },
    })!;
    expect(q.limitReached, isTrue);
    expect(q.valid, isFalse);
    expect(
      q.limitMessage,
      startsWith('Daily limit reached: 3 instant withdrawals.'),
    );
  });

  test(
    'a Withdraw now row reads its provider fee; a scheduled one has none',
    () {
      final w = WithdrawalModel.fromJson({
        'id': 2,
        'amount': '200.00',
        'status': 'completed',
        'origin': 'instant',
        'fee_minor': 472,
      });
      expect(w.origin, 'instant');
      expect(w.feeMinor, 472);
      expect(
        instantFeeLine(AppLocalizationsEn(), w),
        'Withdrawn ₹200.00 · provider fee ₹4.72 · received ₹195.28',
      );
      expect(
        WithdrawalModel.fromJson({'id': 3, 'amount': '900.00'}).origin,
        '',
      );
    },
  );
}
