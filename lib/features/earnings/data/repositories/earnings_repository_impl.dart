import '../../../../domain/models/earning_model.dart';
import '../../../../domain/models/earnings_summary_model.dart';
import '../../../../domain/models/withdrawal_balance_model.dart';
import '../../../../domain/models/withdrawal_block_status_model.dart';
import '../../../../domain/models/withdrawal_model.dart';
import '../../domain/repositories/earnings_repository.dart';
import '../data_sources/earnings_remote_data_source.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  final EarningsRemoteDataSource remoteDataSource;

  EarningsRepositoryImpl(this.remoteDataSource);

  @override
  Future<EarningsSummaryModel> getEarningsSummary({
    String period = 'today',
  }) async {
    return await remoteDataSource.getEarningsSummary(period: period);
  }

  @override
  Future<List<EarningModel>> getEarningsList({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await remoteDataSource.getEarningsList(
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<WithdrawalBalanceModel> getWithdrawalBalance() async {
    return await remoteDataSource.getWithdrawalBalance();
  }

  @override
  Future<WithdrawalModel> requestWithdrawal(double amount) async {
    return await remoteDataSource.requestWithdrawal(amount);
  }

  @override
  Future<List<WithdrawalModel>> getWithdrawalHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await remoteDataSource.getWithdrawalHistory(
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<WithdrawalBlockStatusModel> getWithdrawalBlockStatus() async {
    return await remoteDataSource.getWithdrawalBlockStatus();
  }
}
