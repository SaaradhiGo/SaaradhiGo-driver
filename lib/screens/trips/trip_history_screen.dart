import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/route_indicator.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip_model.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  int _selectedFilter = 0; // 0: All, 1: Completed, 2: Cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTrips();
    });
  }

  void _onFilterChanged(int index) {
    setState(() => _selectedFilter = index);
    String status = 'all';
    if (index == 1) status = 'completed';
    if (index == 2) status = 'cancelled';
    context.read<TripProvider>().fetchTrips(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Trips',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.onSurfaceVariant),
            onPressed: () {},
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
                horizontal: AppSpacing.containerMargin,
                vertical: AppSpacing.stackSm,
              ),
              child: Row(
                children: [
                  _buildChip('Date Range', icon: Icons.calendar_today),
                  const SizedBox(width: 8),
                  _buildFilterChip('All', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 1),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cancelled', 2),
                ],
              ),
            ),

            // Trip Cards List
            Expanded(
              child: Consumer<TripProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  
                  if (provider.error != null) {
                    return Center(
                      child: Text(
                        provider.error!,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                      ),
                    );
                  }

                  if (provider.trips.isEmpty) {
                    return Center(
                      child: Text(
                        'No trips found.',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainer,
                    onRefresh: () async {
                      String status = 'all';
                      if (_selectedFilter == 1) status = 'completed';
                      if (_selectedFilter == 2) status = 'cancelled';
                      await context.read<TripProvider>().fetchTrips(status: status);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerMargin,
                        vertical: AppSpacing.stackMd,
                      ),
                      itemCount: provider.trips.length + 1, // +1 for bottom padding
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.stackMd),
                      itemBuilder: (context, index) {
                        if (index == provider.trips.length) {
                          return const SizedBox(height: 80);
                        }
                        return _buildDynamicTripCard(provider.trips[index]);
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

  Widget _buildChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => _onFilterChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTripCard(TripModel trip) {
    final isCompleted = trip.status == 'completed';
    return _buildTripCard(
      date: trip.createdAt != null ? _formatDate(trip.createdAt!) : 'Unknown',
      riderName: trip.riderName ?? 'Unknown',
      fare: '₹${trip.estimatedFare ?? '0'}',
      status: trip.status.toUpperCase(),
      pickup: trip.pickupAddress ?? 'Unknown',
      pickupDetail: '',
      dropoff: trip.destinationAddress ?? 'Unknown',
      dropoffDetail: '',
      distance: '${trip.distanceKm ?? '--'} km',
      duration: '${trip.durationMin ?? '--'} mins',
      paymentMethod: trip.paymentMethod ?? 'Digital',
      isCompleted: isCompleted,
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildTripCard({
    required String date,
    required String riderName,
    required String fare,
    required String status,
    required String pickup,
    required String pickupDetail,
    required String dropoff,
    required String dropoffDetail,
    required String distance,
    required String duration,
    required String paymentMethod,
    required bool isCompleted,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date, Rider, Fare, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    riderName,
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fare,
                    style: AppTypography.dataMono.copyWith(
                      color: isCompleted ? AppColors.primary : AppColors.onSurfaceVariant,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primaryContainer.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.primaryContainer.withValues(alpha: 0.3)
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.labelCaps.copyWith(
                        color: isCompleted ? AppColors.primary : AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),

          // Route Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const RouteIndicator(height: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      pickupDetail,
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dropoff,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      dropoffDetail,
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 8),

          // Metadata Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    distance,
                    style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.contactless, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    paymentMethod,
                    style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
