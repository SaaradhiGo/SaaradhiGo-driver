import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/route_indicator.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  int _selectedFilter = 0; // 0: All, 1: Completed, 2: Cancelled

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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                  vertical: AppSpacing.stackMd,
                ),
                children: [
                  _buildTripCard(
                    date: 'Oct 24, 10:30 PM',
                    riderName: 'Rahul Sharma',
                    fare: '₹480',
                    status: 'Completed',
                    pickup: 'Taj Mahal Palace',
                    pickupDetail: 'Apollo Bunder',
                    dropoff: 'Bandra Kurla Complex',
                    dropoffDetail: 'G Block',
                    distance: '8.4 km',
                    duration: '22m',
                    paymentMethod: 'Digital',
                    isCompleted: true,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _buildTripCard(
                    date: 'Oct 24, 8:15 PM',
                    riderName: 'Priya Desai',
                    fare: '₹0',
                    status: 'Cancelled',
                    pickup: 'Andheri West',
                    pickupDetail: 'Lokhandwala',
                    dropoff: 'Juhu Beach',
                    dropoffDetail: 'Vile Parle',
                    distance: '-- km',
                    duration: '--',
                    paymentMethod: 'N/A',
                    isCompleted: false,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _buildTripCard(
                    date: 'Oct 23, 2:45 PM',
                    riderName: 'Amit Patel',
                    fare: '₹850',
                    status: 'Completed',
                    pickup: 'Chhatrapati Shivaji Int. Airport',
                    pickupDetail: 'T2 Departures',
                    dropoff: 'Nariman Point',
                    dropoffDetail: 'Trident Hotel',
                    distance: '24.2 km',
                    duration: '55m',
                    paymentMethod: 'Cash',
                    isCompleted: true,
                  ),
                  const SizedBox(height: 80),
                ],
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
      onTap: () => setState(() => _selectedFilter = index),
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
