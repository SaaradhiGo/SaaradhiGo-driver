import 'earnings.dart';

abstract class EarningsRepository {
  Future<EarningsSummary> fetchSummary();

  /// Paginated settlement rows. [page] is 1-based, matching DRF.
  Future<List<EarningEntry>> fetchEntries({int page = 1, int pageSize = 50});
}
