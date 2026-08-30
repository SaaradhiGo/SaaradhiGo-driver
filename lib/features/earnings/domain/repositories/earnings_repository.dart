import '../../../../domain/models/earning_model.dart';
import '../../../../domain/models/earnings_summary_model.dart';
import '../../../../domain/models/withdrawal_balance_model.dart';
import '../../../../domain/models/withdrawal_block_status_model.dart';
import '../../../../domain/models/withdrawal_model.dart';

abstract class EarningsRepository {
  Future<EarningsSummaryModel> getEarningsSummary({String period = 'today'});
  Future<List<EarningModel>> getEarningsList({int page = 1, int pageSize = 20});
  Future<WithdrawalBalanceModel> getWithdrawalBalance();
  Future<WithdrawalModel> requestWithdrawal(double amount);
  Future<List<WithdrawalModel>> getWithdrawalHistory({
    int page = 1,
    int pageSize = 20,
  });
  Future<WithdrawalBlockStatusModel> getWithdrawalBlockStatus();
}
