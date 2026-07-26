import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../trip/domain/trip.dart';

/// Server-side status filter for the history list. `null` = everything.
class HistoryFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? status) => state = status;
}

final historyFilterProvider =
    NotifierProvider<HistoryFilter, String?>(HistoryFilter.new);

final tripHistoryProvider = FutureProvider.autoDispose<List<Trip>>((ref) {
  final status = ref.watch(historyFilterProvider);
  return ref.watch(historyRepositoryProvider).fetchHistory(status: status);
});
