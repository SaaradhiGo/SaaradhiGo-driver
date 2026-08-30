import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/earning_model.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_balance_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_block_status_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_model.dart';
import 'package:saaradhigo_driver/features/earnings/data/data_sources/earnings_remote_data_source.dart';
import 'package:saaradhigo_driver/features/earnings/data/repositories/earnings_repository_impl.dart';

class FakeEarningsRemoteDataSource implements EarningsRemoteDataSource {
  EarningsSummaryModel summaryToReturn = const EarningsSummaryModel(
    totalEarned: '15000.00',
    totalCommission: '1500.00',
    totalTrips: 100,
    todayEarned: '350.00',
    todayTrips: 2,
  );

  List<EarningModel> earningsListToReturn = [
    const EarningModel(
      id: 1,
      tripId: 101,
      amountCollected: '200.00',
      platformFee: '20.00',
      netEarning: '180.00',
    ),
  ];

  WithdrawalBalanceModel balanceToReturn = const WithdrawalBalanceModel(
    availableBalance: 1500.0,
    blocked: false,
    minimumWithdrawal: 500.0,
  );

  List<WithdrawalModel> historyToReturn = [
    const WithdrawalModel(id: 1, amount: '1000.00', status: 'pending'),
  ];

  WithdrawalBlockStatusModel blockStatusToReturn =
      const WithdrawalBlockStatusModel(blocked: false);

  double? requestedWithdrawalAmount;

  @override
  Future<EarningsSummaryModel> getEarningsSummary({
    String period = 'today',
  }) async {
    return summaryToReturn;
  }

  @override
  Future<List<EarningModel>> getEarningsList({
    int page = 1,
    int pageSize = 20,
  }) async {
    return earningsListToReturn;
  }

  @override
  Future<WithdrawalBalanceModel> getWithdrawalBalance() async {
    return balanceToReturn;
  }

  @override
  Future<WithdrawalModel> requestWithdrawal(double amount) async {
    requestedWithdrawalAmount = amount;
    return WithdrawalModel(
      id: 99,
      amount: amount.toStringAsFixed(2),
      status: 'pending',
    );
  }

  @override
  Future<List<WithdrawalModel>> getWithdrawalHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    return historyToReturn;
  }

  @override
  Future<WithdrawalBlockStatusModel> getWithdrawalBlockStatus() async {
    return blockStatusToReturn;
  }
}

void main() {
  late FakeEarningsRemoteDataSource dataSource;
  late EarningsRepositoryImpl repository;

  setUp(() {
    dataSource = FakeEarningsRemoteDataSource();
    repository = EarningsRepositoryImpl(dataSource);
  });

  group('EarningsRepositoryImpl', () {
    test('getEarningsSummary returns expected data from data source', () async {
      final summary = await repository.getEarningsSummary(period: 'today');
      expect(summary.totalEarned, '15000.00');
      expect(summary.todayEarned, '350.00');
      expect(summary.totalTrips, 100);
    });

    test('getEarningsList returns list of earnings', () async {
      final list = await repository.getEarningsList();
      expect(list.length, 1);
      expect(list.first.netEarning, '180.00');
    });

    test('getWithdrawalBalance returns available balance', () async {
      final balance = await repository.getWithdrawalBalance();
      expect(balance.availableBalance, 1500.0);
      expect(balance.blocked, isFalse);
      expect(balance.minimumWithdrawal, 500.0);
    });

    test(
      'requestWithdrawal passes amount and returns created withdrawal',
      () async {
        final result = await repository.requestWithdrawal(750.0);
        expect(dataSource.requestedWithdrawalAmount, 750.0);
        expect(result.id, 99);
        expect(result.amount, '750.00');
      },
    );

    test('getWithdrawalHistory returns history list', () async {
      final history = await repository.getWithdrawalHistory();
      expect(history.length, 1);
      expect(history.first.amount, '1000.00');
    });

    test('getWithdrawalBlockStatus returns block status', () async {
      final status = await repository.getWithdrawalBlockStatus();
      expect(status.blocked, isFalse);
    });
  });
}
