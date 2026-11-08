import '../../../../core/market/market_format.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import 'package:saaradhigo_driver/ui/sg_format.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

class TripHistoryCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const TripHistoryCard({super.key, required this.trip, required this.onTap});

  /// "Sun, 8 Nov · 1:15 am" (the year when it is not this year).
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recent Trip';
    final date = DateTime.tryParse(dateStr)?.toLocal();
    return date == null ? dateStr : sgDayTime(date);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == TripStatus.completed;
    final isCancelled = trip.status == TripStatus.cancelled;
    final fareText = isCancelled
        ? '${marketSymbol()}0'
        : '${marketSymbol()}${trip.finalFare ?? trip.estimatedFare ?? '0'}';

    final paymentMethod = (trip.paymentMethod ?? 'DIGITAL').toUpperCase();
    final isCash = paymentMethod.contains('CASH');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isCompleted
                ? AppColors.outlineVariant.withValues(alpha: 0.6)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: SgColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date & Rider, Fare & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(trip.createdAt),
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: SgText.sizeSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.unit),
                      Text(
                        trip.riderName ?? 'Passenger',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onBackground,
                          fontSize: SgText.sizeTitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fareText,
                      style: AppTypography.dataMono.copyWith(
                        color: isCompleted
                            ? AppColors.primaryText
                            : AppColors.onSurfaceVariant,
                        fontSize: SgText.sizeTitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primaryContainer.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.primaryContainer.withValues(
                                  alpha: 0.4,
                                )
                              : AppColors.outlineVariant,
                        ),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Completed'
                            : (isCancelled ? 'Cancelled' : 'In Progress'),
                        style: AppTypography.labelCaps.copyWith(
                          color: isCompleted
                              ? AppColors.primaryText
                              : AppColors.onSurfaceVariant,
                          fontSize: SgText.sizeSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Cancellation Reason note (if cancelled and present)
            if (isCancelled &&
                trip.cancellationReason != null &&
                trip.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trip.cancellationReason!,
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.error,
                        fontSize: SgText.sizeSmall,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Route Breakdown (Pickup & Dropoff)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Timeline graphic
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primaryText, AppColors.outlineVariant],
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                // Addresses
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.pickupAddress ?? 'Pickup Location',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onBackground,
                          fontSize: SgText.sizeSmall,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        trip.destinationAddress ?? 'Destination Location',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: SgText.sizeSmall,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Footer Row: Distance, Duration, Payment Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.route_outlined,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.distanceKm != null
                          ? '${trip.distanceKm!.toStringAsFixed(1)} km'
                          : '-- km',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: SgText.sizeSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.durationMin != null
                          ? '${trip.durationMin!.toInt()}m'
                          : '--',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: SgText.sizeSmall,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      isCash
                          ? Icons.account_balance_wallet_outlined
                          : Icons.contactless_outlined,
                      size: 16,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCash ? 'Cash' : 'Digital',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: SgText.sizeSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
