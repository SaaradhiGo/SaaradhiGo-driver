import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../providers/trip_history_providers.dart';
import '../widgets/date_range_picker_sheet.dart';
import '../widgets/trip_history_card.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      ref.read(tripHistoryNotifierProvider.notifier).loadMore();
    }
  }

  void _onTripTap(TripModel trip) {
    if (trip.status.isActive) {
      ref.read(tripSessionNotifierProvider.notifier).resumeActiveTrip(trip);
      context.push('/ride');
    } else {
      context.push('/history/trip/${trip.id}');
    }
  }

  void _openDateFilter(BuildContext context, TripHistoryState state) {
    DateRangePickerSheet.show(
      context,
      activePreset: state.datePreset,
      activeCustomRange: state.customDateRange,
      onSelected: (preset, customRange) {
        ref
            .read(tripHistoryNotifierProvider.notifier)
            .setDatePreset(preset, customRange: customRange);
      },
    );
  }

  String _dateFilterLabel(TripHistoryState state) {
    if (state.datePreset == DateFilterPreset.custom &&
        state.customDateRange != null) {
      final range = state.customDateRange!;
      return '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
    }
    if (state.datePreset != DateFilterPreset.allTime) {
      return state.datePreset.label;
    }
    return 'Date Range';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripHistoryNotifierProvider);
    final notifier = ref.read(tripHistoryNotifierProvider.notifier);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final isDateFilterActive = state.datePreset != DateFilterPreset.allTime;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        title: Text(
          'Trips',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
            onPressed: () => _openDateFilter(context, state),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Date Range Chip
                  _buildChip(
                    label: _dateFilterLabel(state),
                    icon: Icons.calendar_today_outlined,
                    isActive: isDateFilterActive,
                    onTap: () => _openDateFilter(context, state),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // All Chip
                  _buildChip(
                    label: 'All',
                    isActive: state.filter == TripHistoryFilter.all,
                    onTap: () => notifier.setFilter(TripHistoryFilter.all),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Completed Chip
                  _buildChip(
                    label: 'Completed',
                    isActive: state.filter == TripHistoryFilter.completed,
                    onTap: () =>
                        notifier.setFilter(TripHistoryFilter.completed),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Cancelled Chip
                  _buildChip(
                    label: 'Cancelled',
                    isActive: state.filter == TripHistoryFilter.cancelled,
                    onTap: () =>
                        notifier.setFilter(TripHistoryFilter.cancelled),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading) {
                    return _buildLoadingShimmer();
                  }

                  if (state.hasError) {
                    return _buildErrorState(state.errorMessage, notifier);
                  }

                  if (state.isEmpty || state.trips.isEmpty) {
                    return _buildEmptyState(
                      isFiltered:
                          isDateFilterActive ||
                          state.filter != TripHistoryFilter.all,
                      onClear: notifier.clearFilters,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainer,
                    onRefresh: () => notifier.fetchTrips(refresh: true),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.margin,
                        vertical: AppSpacing.md,
                      ),
                      itemCount:
                          state.trips.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        if (index == state.trips.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }

                        final trip = state.trips[index];
                        return TripHistoryCard(
                          trip: trip,
                          onTap: () => _onTripTap(trip),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer.withValues(alpha: 0.18)
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.6),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.margin,
        vertical: AppSpacing.md,
      ),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? message, TripHistoryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to Load Trips',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? 'Please check your connection and try again.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.darkText,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              onPressed: () => notifier.fetchTrips(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isFiltered,
    required VoidCallback onClear,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_rounded,
              size: 56,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isFiltered
                  ? 'No trips found for selected filters'
                  : 'No Recent Trips',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isFiltered
                  ? 'Try selecting a broader date range or clearing the active filters.'
                  : 'Your completed ride history will appear here once you start taking rides.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkText,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Clear Filters'),
                onPressed: onClear,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
