import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/earnings.dart';

final earningsSummaryProvider =
    FutureProvider.autoDispose<EarningsSummary>((ref) {
  return ref.watch(earningsRepositoryProvider).fetchSummary();
});

/// One page of settlement rows, deep enough to roll up a month for a busy
/// driver (~10 trips/day × 30 days).
final earningsEntriesProvider =
    FutureProvider.autoDispose<List<EarningEntry>>((ref) {
  return ref.watch(earningsRepositoryProvider).fetchEntries(pageSize: 300);
});

/// Day / week / month rollups computed from [earningsEntriesProvider].
///
/// The backend exposes today and lifetime only. Rather than adding a period
/// endpoint — the brief forbids new endpoints, and rightly so — the app
/// aggregates the rows it already has. The trade-off is honest and worth
/// stating: a driver with more than 300 settlement rows in a month would see
/// a truncated "month" figure, which is why the screen labels it as
/// "recent activity" rather than an accounting total.
final earningsPeriodsProvider =
    Provider.autoDispose<AsyncValue<List<EarningsPeriod>>>((ref) {
  final entries = ref.watch(earningsEntriesProvider);
  return entries.whenData((rows) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month);
    return [
      EarningsPeriod.from('Today', rows, startOfDay),
      EarningsPeriod.from('This week', rows, startOfWeek),
      EarningsPeriod.from('This month', rows, startOfMonth),
    ];
  });
});
