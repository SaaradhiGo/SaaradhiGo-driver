import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/payout_plan.dart';

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
        'instant': {'available': true, 'provider': 'RazorpayX', 'saaradhigo_fee': '0'},
      },
    })!;
    expect(plan.nextAt!.toUtc(), DateTime.utc(2026, 11, 10, 4, 30));
    expect(plan.estimatedAmount, '347.00');
    expect(plan.instantAvailable, isTrue);
    expect(plan.provider, 'RazorpayX');
  });

  test('on request and instant off: no date, no button', () {
    final plan = parsePayoutPlan({'data': {'next_payout': null, 'instant': {'available': false}}})!;
    expect(plan.nextAt, isNull);
    expect(plan.instantAvailable, isFalse);
  });

  test('the confirmation carries the provider fee and SaaradhiGo fee 0', () {
    final q = parseInstantQuote({
      'data': {
        'amount': '500.00', 'provider_fee': '4.72',
        'provider_fee_label': 'Provider fee (charged by RazorpayX)',
        'saaradhigo_fee': '0.00', 'you_receive': '495.28', 'currency': 'INR',
        'destination': 'UPI ••kaxis', 'arrival': 'Usually within 30 minutes', 'valid': true,
      },
    })!;
    expect(q.providerFee, '4.72');
    expect(q.saaradhigoFee, '0.00');
    expect(q.youReceive, '495.28');
    expect(q.valid, isTrue);
  });
}
