import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../data/data_sources/driver_location_consumer.dart';

/// Modal bottom sheet for incoming ride requests (`incoming_ride_request/code.html`).
class IncomingRideBottomSheet extends StatefulWidget {
  const IncomingRideBottomSheet({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
    this.timeoutSeconds = 20,
  });

  final DriverLocationRideRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final int timeoutSeconds;

  @override
  State<IncomingRideBottomSheet> createState() =>
      _IncomingRideBottomSheetState();
}

class _IncomingRideBottomSheetState extends State<IncomingRideBottomSheet> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    _alertDriver();
    _startTimer();
  }

  /// Audible + tactile alert on a new request. Uses the platform alert sound and
  /// haptics from the framework so no extra audio dependency is pulled in; the
  /// 20s timer below is purely a UI affordance (the backend owns dispatch
  /// timeouts — there is no per-offer auto-reject WebSocket event).
  void _alertDriver() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        if (mounted) {
          widget.onDecline();
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.request.payload;
    final riderName = payload['rider_name']?.toString() ?? 'Passenger';
    final pickupAddress =
        payload['pickup_address']?.toString() ?? 'Pickup Location';
    final destinationAddress =
        payload['destination_address']?.toString() ?? 'Destination Address';
    final rawFare = payload['estimated_fare']?.toString() ?? '0.00';
    final fare = rawFare.startsWith('₹') ? rawFare : '₹$rawFare';
    final distance = payload['distance_km'] != null
        ? '${payload['distance_km']} km'
        : '8.4 km';
    final duration = payload['duration_min'] != null
        ? '${payload['duration_min']} mins'
        : '20 mins';

    final progress = _remainingSeconds / widget.timeoutSeconds;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        left: AppSpacing.margin,
        right: AppSpacing.margin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header with Title & Countdown Timer Ring
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Ride Request',
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Standard Ride • Digital Payment',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  Text(
                    '$_remainingSeconds',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Route Details Card
          GlassPanel(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Pickup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICKUP',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pickupAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onBackground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Destination
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.onSurfaceVariant,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DESTINATION',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            destinationAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onBackground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Divider(
                  height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                ),
                const SizedBox(height: AppSpacing.md),

                // Metrics Row (Distance, Duration, Fare)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ESTIMATED FARE',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          fare,
                          style: AppTypography.dataMono.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Rider details row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  riderName,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Buttons: Accept & Decline
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SecondaryButton(
                  text: 'DECLINE',
                  onPressed: widget.onDecline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'ACCEPT RIDE',
                  onPressed: widget.onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
