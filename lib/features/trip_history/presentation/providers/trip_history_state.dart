import 'package:flutter/material.dart';

import '../../../../core/utils/date_range_utils.dart';
import '../../../../domain/models/trip_model.dart';

/// Status filter for history tab.
enum TripHistoryFilter {
  all,
  completed,
  cancelled;

  String toApiStatus() {
    switch (this) {
      case TripHistoryFilter.all:
        return 'all';
      case TripHistoryFilter.completed:
        return 'completed';
      case TripHistoryFilter.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case TripHistoryFilter.all:
        return 'All';
      case TripHistoryFilter.completed:
        return 'Completed';
      case TripHistoryFilter.cancelled:
        return 'Cancelled';
    }
  }
}

/// Date range preset options for the bottom sheet filter.
enum DateFilterPreset {
  allTime('All Time'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom');

  final String label;
  const DateFilterPreset(this.label);
}

/// 8-state compliant UI statuses for trip history.
enum TripHistoryStatus { initial, loading, success, empty, error, refreshing }

class TripHistoryState {
  final TripHistoryStatus status;
  final List<TripModel> trips;
  final TripHistoryFilter filter;
  final DateFilterPreset datePreset;
  final DateTimeRange? customDateRange;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  const TripHistoryState({
    this.status = TripHistoryStatus.initial,
    this.trips = const [],
    this.filter = TripHistoryFilter.all,
    this.datePreset = DateFilterPreset.allTime,
    this.customDateRange,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get isLoading => status == TripHistoryStatus.loading;
  bool get isRefreshing => status == TripHistoryStatus.refreshing;
  bool get isEmpty => status == TripHistoryStatus.empty;
  bool get hasError => status == TripHistoryStatus.error;

  /// Effective DateTimeRange calculated from preset or custom range.
  DateTimeRange? get effectiveDateRange {
    final now = DateTime.now();
    switch (datePreset) {
      case DateFilterPreset.allTime:
        return null;
      case DateFilterPreset.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case DateFilterPreset.thisWeek:
        final weekday = now.weekday; // 1 = Monday
        final start = DateTime(now.year, now.month, now.day - (weekday - 1));
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case DateFilterPreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case DateFilterPreset.custom:
        final range = customDateRange;
        if (range == null) return null;
        return normalizeDateRange(range);
    }
  }

  TripHistoryState copyWith({
    TripHistoryStatus? status,
    List<TripModel>? trips,
    TripHistoryFilter? filter,
    DateFilterPreset? datePreset,
    DateTimeRange? customDateRange,
    bool clearCustomDateRange = false,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return TripHistoryState(
      status: status ?? this.status,
      trips: trips ?? this.trips,
      filter: filter ?? this.filter,
      datePreset: datePreset ?? this.datePreset,
      customDateRange: clearCustomDateRange
          ? null
          : (customDateRange ?? this.customDateRange),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }
}

/// UI status for single trip details.
enum TripDetailsStatus { initial, loading, success, error }

class TripDetailsState {
  final TripDetailsStatus status;
  final TripModel? trip;
  final String? errorMessage;

  const TripDetailsState({
    this.status = TripDetailsStatus.initial,
    this.trip,
    this.errorMessage,
  });

  bool get isLoading => status == TripDetailsStatus.loading;
  bool get hasError => status == TripDetailsStatus.error;
  bool get isSuccess => status == TripDetailsStatus.success;

  TripDetailsState copyWith({
    TripDetailsStatus? status,
    TripModel? trip,
    String? errorMessage,
  }) {
    return TripDetailsState(
      status: status ?? this.status,
      trip: trip ?? this.trip,
      errorMessage: errorMessage,
    );
  }
}
