import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/trip_history_repository.dart';
import 'trip_history_providers.dart';

class TripHistoryNotifier extends Notifier<TripHistoryState> {
  late TripHistoryRepository _repository;

  @override
  TripHistoryState build() {
    _repository = ref.watch(tripHistoryRepositoryProvider);
    // Trigger initial fetch asynchronously
    Future.microtask(() => fetchTrips());
    return const TripHistoryState();
  }

  /// Fetches the first page of trips according to current filters.
  Future<void> fetchTrips({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      status: refresh
          ? TripHistoryStatus.refreshing
          : TripHistoryStatus.loading,
      errorMessage: null,
      currentPage: 1,
    );

    try {
      final trips = await _repository.getDriverHistory(
        status: state.filter.toApiStatus(),
        dateRange: state.effectiveDateRange,
        page: 1,
        pageSize: 10,
      );

      if (trips.isEmpty) {
        state = state.copyWith(
          status: TripHistoryStatus.empty,
          trips: [],
          hasMore: false,
          currentPage: 1,
        );
      } else {
        state = state.copyWith(
          status: TripHistoryStatus.success,
          trips: trips,
          hasMore: trips.length >= 10,
          currentPage: 1,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: TripHistoryStatus.error,
        errorMessage:
            'Failed to load trip history. Please check your network connection.',
      );
    }
  }

  /// Fetches the next page of trips for infinite scrolling.
  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isLoading ||
        state.isRefreshing) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final moreTrips = await _repository.getDriverHistory(
        status: state.filter.toApiStatus(),
        dateRange: state.effectiveDateRange,
        page: nextPage,
        pageSize: 10,
      );

      if (moreTrips.isEmpty) {
        state = state.copyWith(hasMore: false, isLoadingMore: false);
      } else {
        state = state.copyWith(
          trips: [...state.trips, ...moreTrips],
          currentPage: nextPage,
          hasMore: moreTrips.length >= 10,
          isLoadingMore: false,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Switches status filter (`all`, `completed`, `cancelled`) and resets to page 1.
  void setFilter(TripHistoryFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    fetchTrips();
  }

  /// Sets date range preset (Today, This Week, This Month, Custom).
  void setDatePreset(DateFilterPreset preset, {DateTimeRange? customRange}) {
    state = state.copyWith(
      datePreset: preset,
      customDateRange: customRange,
      clearCustomDateRange: preset != DateFilterPreset.custom,
    );
    fetchTrips();
  }

  /// Clears both date filter and status filter back to All Time / All.
  void clearFilters() {
    state = state.copyWith(
      filter: TripHistoryFilter.all,
      datePreset: DateFilterPreset.allTime,
      clearCustomDateRange: true,
    );
    fetchTrips();
  }
}
