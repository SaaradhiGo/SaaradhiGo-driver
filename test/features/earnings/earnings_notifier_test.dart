import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/earning_model.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_balance_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_block_status_model.dart';
import 'package:saaradhigo_driver/domain/models/withdrawal_model.dart';
import 'package:saaradhigo_driver/features/earnings/domain/repositories/earnings_repository.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_providers.dart';

/// Granular failure control: each dashboard endpoint can fail independently so
/// tests can verify the notifier's per-section error isolation.
class StubEarningsRepository implements EarningsRepository {
  bool failSummary = false;
  bool failEarningsList = false;
  bool failBalance = false;
  bool failWithdrawal = false;
  bool failHistory = false;

  @override
  Future<EarningsSummaryModel> getEarningsSummary({
    String period = 'today',
  }) async {
    if (failSummary) throw Exception('Network error');
    return EarningsSummaryModel(
      totalEarned: period == 'this_week' ? '5000.00' : '1000.00',
      totalCommission: '100.00',
      totalTrips: 10,
    );
  }

  @override
  Future<List<EarningModel>> getEarningsList({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (failEarningsList) throw Exception('Network error');
    return [const EarningModel(id: 1, netEarning: '500.00')];
  }

  @override
  Future<WithdrawalBalanceModel> getWithdrawalBalance() async {
    if (failBalance) throw Exception('Network error');
    return const WithdrawalBalanceModel(
      availableBalance: 1200.0,
      blocked: false,
      minimumWithdrawal: 500.0,
    );
  }

  @override
  Future<WithdrawalModel> requestWithdrawal(double amount) async {
    if (failWithdrawal) throw Exception('Network error');
    return WithdrawalModel(
      id: 55,
      amount: amount.toStringAsFixed(2),
      status: 'pending',
    );
  }

  @override
  Future<List<WithdrawalModel>> getWithdrawalHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (failHistory) throw Exception('Network error');
    return [const WithdrawalModel(id: 1, amount: '500.00', status: 'pending')];
  }

  @override
  Future<WithdrawalBlockStatusModel> getWithdrawalBlockStatus() async {
    return const WithdrawalBlockStatusModel(blocked: false);
  }
}

void main() {
  late ProviderContainer container;
  late StubEarningsRepository stubRepository;

  setUp(() {
    stubRepository = StubEarningsRepository();
    container = ProviderContainer(
      overrides: [earningsRepositoryProvider.overrideWithValue(stubRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('EarningsNotifier', () {
    test('initial state has empty data', () {
      final state = container.read(earningsNotifierProvider);
      expect(state.summary, isNull);
      expect(state.isLoading, isFalse);
      expect(state.selectedPeriodIndex, 0);
    });

    test('loadInitialData populates summary and balances', () async {
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.loadInitialData();

      final state = container.read(earningsNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.summary?.totalEarned, '1000.00');
      expect(state.earningsList.length, 1);
      expect(state.withdrawalBalance?.availableBalance, 1200.0);
      expect(state.withdrawalHistory.length, 1);
      expect(state.errorMessage, isNull);
    });

    test('setPeriod updates selected index and fetches new summary', () async {
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.setPeriod(1); // this_week

      final state = container.read(earningsNotifierProvider);
      expect(state.selectedPeriodIndex, 1);
      expect(state.summary?.totalEarned, '5000.00');
    });

    test('requestWithdrawal fails if amount < minimum withdrawal', () async {
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.requestWithdrawal(200.0); // min is 500
      expect(success, isFalse);

      final state = container.read(earningsNotifierProvider);
      expect(state.errorMessage, contains('Minimum withdrawal amount is ₹500'));
    });

    test('requestWithdrawal fails if amount > available balance', () async {
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.requestWithdrawal(2000.0); // max is 1200
      expect(success, isFalse);

      final state = container.read(earningsNotifierProvider);
      expect(state.errorMessage, contains('exceeds available balance'));
    });

    test('requestWithdrawal succeeds for valid amount', () async {
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.requestWithdrawal(600.0);
      expect(success, isTrue);

      final state = container.read(earningsNotifierProvider);
      expect(state.withdrawalSuccessMessage, contains('ID: 55'));
    });

    test(
      'full failure surfaces fatal error without a fallback summary',
      () async {
        stubRepository.failSummary = true;
        stubRepository.failEarningsList = true;
        stubRepository.failBalance = true;
        stubRepository.failHistory = true;
        final notifier = container.read(earningsNotifierProvider.notifier);
        await notifier.loadInitialData();

        final state = container.read(earningsNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.summary, isNull);
        expect(state.errorMessage, isNotNull);
      },
    );

    test(
      'a failing non-summary section does not blank the dashboard',
      () async {
        // Summary loads fine; only the secondary sections fail.
        stubRepository.failBalance = true;
        stubRepository.failHistory = true;
        final notifier = container.read(earningsNotifierProvider.notifier);
        await notifier.loadInitialData();

        final state = container.read(earningsNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.summary?.totalEarned, '1000.00');
        expect(state.earningsList.length, 1);
        // Failed sections keep the previous (empty) value; no fatal error since
        // the summary — the section the dashboard needs to render — succeeded.
        expect(state.withdrawalBalance, isNull);
        expect(state.withdrawalHistory, isEmpty);
        expect(state.errorMessage, isNull);
      },
    );

    test('partial failure keeps previously loaded data on refresh', () async {
      final notifier = container.read(earningsNotifierProvider.notifier);
      await notifier.loadInitialData();

      // On refresh only the balance endpoint fails: previous balance stays.
      stubRepository.failBalance = true;
      await notifier.refresh();

      final state = container.read(earningsNotifierProvider);
      expect(state.summary?.totalEarned, '1000.00');
      expect(state.withdrawalBalance?.availableBalance, 1200.0);
      expect(state.errorMessage, isNull);
    });

    test(
      'successful withdrawal refresh tolerates a failing balance fetch',
      () async {
        final notifier = container.read(earningsNotifierProvider.notifier);
        await notifier.loadInitialData();

        stubRepository.failBalance = true;
        final success = await notifier.requestWithdrawal(600.0);
        expect(success, isTrue);

        final state = container.read(earningsNotifierProvider);
        expect(state.withdrawalSuccessMessage, contains('ID: 55'));
        // The failing balance refresh must not roll back the stored balance.
        expect(state.withdrawalBalance?.availableBalance, 1200.0);
      },
    );
  });
}
