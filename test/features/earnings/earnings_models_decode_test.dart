import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/earning_model.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_balance_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_block_status_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_model.dart';

/// Regression tests for the Phase 6 runtime crash.
///
/// The earnings screen threw `TypeError` at runtime while the analyzer was
/// clean because the model decoders used strict casts (`json['x'] as String`)
/// that do not match the real backend payloads (money sometimes arrives as a
/// JSON number even though the docs show decimal strings, and `id` may be
/// absent/null). These tests decode the exact payload shapes documented in
/// `API_Documentation_V2.md` §3.4/3.5/3.15–3.18, plus realistic drift variants.
void main() {
  group('EarningsSummaryModel.fromJson', () {
    test('decodes the documented string-money payload', () {
      final summary = EarningsSummaryModel.fromJson(const {
        'total_earned': '15000.00',
        'total_commission': '1500.00',
        'total_trips': 100,
        'today_earned': '350.00',
        'today_trips': 2,
        'commission_percent': 10,
      });

      expect(summary.totalEarned, '15000.00');
      expect(summary.totalCommission, '1500.00');
      expect(summary.totalTrips, 100);
      expect(summary.todayEarned, '350.00');
      expect(summary.todayTrips, 2);
      expect(summary.commissionPercent, 10);
    });

    test('does not throw when money fields arrive as numbers', () {
      final summary = EarningsSummaryModel.fromJson(const {
        'total_earned': 15000.0, // numeric drift instead of "15000.00"
        'total_commission': 1500, // integer drift
        'total_trips': 100,
        'today_earned': 350,
        'today_trips': '2', // string int drift
        'commission_percent': 10.0,
      });

      expect(summary.totalEarned, '15000.00');
      expect(summary.totalCommission, '1500.00');
      expect(summary.totalTrips, 100);
      expect(summary.todayEarned, '350.00');
      expect(summary.todayTrips, 2);
      expect(summary.commissionPercent, 10);
    });

    test('defaults when payload is missing', () {
      final summary = EarningsSummaryModel.fromJson(const <String, dynamic>{});

      expect(summary.totalEarned, '0.00');
      expect(summary.totalTrips, 0);
      expect(summary.todayTrips, 0);
    });

    test('never invents a commission when the API did not send one', () {
      final summary = EarningsSummaryModel.fromJson(const <String, dynamic>{});

      expect(summary.totalCommission, isNull);
      expect(summary.commissionPercent, isNull);
      expect(summary.commissionPercentMixed, isNull);
    });

    test('decodes the rate and the mixed flag exactly as sent', () {
      final summary = EarningsSummaryModel.fromJson(const {
        'total_earned': '1000.00',
        'total_commission': '150.00',
        'commission_percent': '15.00',
        'commission_percent_mixed': true,
      });

      expect(summary.commissionPercent, 15);
      expect(summary.commissionPercentMixed, isTrue);
      expect(summary.totalCommission, '150.00');
    });
  });

  group('EarningModel.fromJson', () {
    test('decodes the documented payload', () {
      final earning = EarningModel.fromJson(const {
        'id': 1,
        'trip_id': 101,
        'amount_collected': '200.00',
        'platform_fee': '20.00',
        'net_earning': '180.00',
        'created_at': '2026-04-07T10:00:00Z',
      });

      expect(earning.id, 1);
      expect(earning.tripId, 101);
      expect(earning.amountCollected, '200.00');
      expect(earning.platformFee, '20.00');
      expect(earning.netEarning, '180.00');
      expect(earning.createdAt, '2026-04-07T10:00:00Z');
    });

    test('does not throw when money fields are numbers and id is a string', () {
      final earning = EarningModel.fromJson(const {
        'id': '12', // string id drift
        'trip_id': 101,
        'amount_collected': 200.0,
        'platform_fee': 20,
        'net_earning': 180.0,
      });

      expect(earning.id, 12);
      expect(earning.amountCollected, '200.00');
      expect(earning.platformFee, '20.00');
      expect(earning.netEarning, '180.00');
    });

    test('reads the keys the settlements endpoint really sends', () {
      final earning = EarningModel.fromJson(const {
        'id': 7,
        'trip_id_val': 55,
        'amount': '200.00',
        'commission': '30.00',
        'net_amount': '170.00',
        'commission_percent': '15.00',
        'created_at': '2026-04-07T10:00:00Z',
      });

      expect(earning.tripId, 55);
      expect(earning.amountCollected, '200.00');
      expect(earning.platformFee, '30.00');
      expect(earning.netEarning, '170.00');
      expect(earning.commissionPercent, 15);
    });

    test('a row with no commission carries none, not 0.00', () {
      final earning = EarningModel.fromJson(const {
        'id': 8,
        'commission': null,
      });

      expect(earning.platformFee, isNull);
      expect(earning.netEarning, isNull);
      expect(earning.commissionPercent, isNull);
    });

    test('does not throw when id is missing', () {
      final earning = EarningModel.fromJson(const {'net_earning': 520.5});

      expect(earning.id, 0);
      expect(earning.tripId, isNull);
      expect(earning.netEarning, '520.50');
    });
  });

  group('WithdrawalModel.fromJson', () {
    test('decodes the documented payload', () {
      final withdrawal = WithdrawalModel.fromJson(const {
        'id': 1,
        'amount': '1000.00',
        'status': 'pending',
        'requested_at': '2026-06-29T10:00:00Z',
      });

      expect(withdrawal.id, 1);
      expect(withdrawal.amount, '1000.00');
      expect(withdrawal.status, 'pending');
      expect(withdrawal.requestedAt, '2026-06-29T10:00:00Z');
    });

    test('coerces numeric amount and missing id', () {
      final withdrawal = WithdrawalModel.fromJson(const {'amount': 1000.0});

      expect(withdrawal.id, 0);
      expect(withdrawal.amount, '1000.00');
      expect(withdrawal.status, 'pending');
    });
  });

  group('WithdrawalBalanceModel.fromJson', () {
    test('decodes the documented float payload', () {
      final balance = WithdrawalBalanceModel.fromJson(const {
        'available_balance': 1500.0,
        'blocked': false,
        'block_remaining_seconds': null,
        'fee_percent': 2.0,
        'minimum_withdrawal': 500.0,
      });

      expect(balance.availableBalance, 1500.0);
      expect(balance.blocked, isFalse);
      expect(balance.blockRemainingSeconds, isNull);
      expect(balance.feePercent, 2.0);
      expect(balance.minimumWithdrawal, 500.0);
    });

    test('coerces string-number balances', () {
      final balance = WithdrawalBalanceModel.fromJson(const {
        'available_balance': '1500',
        'blocked': 0,
        'fee_percent': '2.0',
        'minimum_withdrawal': '500',
      });

      expect(balance.availableBalance, 1500.0);
      expect(balance.blocked, isFalse);
      expect(balance.feePercent, 2.0);
      expect(balance.minimumWithdrawal, 500.0);
    });
  });

  group('WithdrawalBalanceModel fee and currency', () {
    test('decodes fee_display and currency from the API', () {
      final balance = WithdrawalBalanceModel.fromJson(const {
        'available_balance': 30.0,
        'fee_percent': 1.5,
        'fee_display': '1.5%',
        'minimum_withdrawal': 1.0,
        'currency': 'USD',
      });
      expect(balance.feeDisplay, '1.5%');
      expect(balance.currency, 'USD');
    });

    test('fee_display null means no fee; a missing currency stays null', () {
      final balance = WithdrawalBalanceModel.fromJson(const {
        'available_balance': 30.0,
        'fee_percent': 0.0,
        'fee_display': null,
        'minimum_withdrawal': 500.0,
      });
      expect(balance.feeDisplay, isNull);
      expect(balance.currency, isNull);
    });

    test('there is no client-side minimum default', () {
      final balance = WithdrawalBalanceModel.fromJson(const {});
      expect(balance.minimumWithdrawal, 0.0);
    });
  });

  group('WithdrawalBlockStatusModel.fromJson', () {
    test('decodes the documented payload', () {
      final status = WithdrawalBlockStatusModel.fromJson(const {
        'blocked': false,
        'last_withdrawal_at': '2026-06-20T10:00:00Z',
        'block_remaining_seconds': 0,
      });

      expect(status.blocked, isFalse);
      expect(status.lastWithdrawalAt, '2026-06-20T10:00:00Z');
      expect(status.blockRemainingSeconds, 0);
    });

    test('coerces truthy blocked flags', () {
      final status = WithdrawalBlockStatusModel.fromJson(const {
        'blocked': 1,
        'block_remaining_seconds': '3600',
      });

      expect(status.blocked, isTrue);
      expect(status.blockRemainingSeconds, 3600);
    });
  });
}
