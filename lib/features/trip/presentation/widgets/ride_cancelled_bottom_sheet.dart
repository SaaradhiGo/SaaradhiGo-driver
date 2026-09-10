import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';

/// Modal bottom sheet presented when a passenger cancels an in-flight ride.
///
/// Provides clear sensory notice, displays the cancellation reason if
/// provided, and features an auto-dismiss safety countdown so the driver
/// is cleanly returned to the dashboard and marked available for new dispatches.
class RideCancelledBottomSheet extends StatefulWidget {
  const RideCancelledBottomSheet({
    super.key,
    this.reason,
    required this.onDismiss,
    this.autoDismissSeconds = 10,
  });

  /// Optional cancellation message/reason received from the backend.
  final String? reason;

  /// Invoked when the driver taps "RETURN TO DASHBOARD" or when the auto-dismiss
  /// timer finishes.
  final VoidCallback onDismiss;

  /// Duration before automatically returning to the dashboard.
  final int autoDismissSeconds;

  @override
  State<RideCancelledBottomSheet> createState() =>
      _RideCancelledBottomSheetState();
}

class _RideCancelledBottomSheetState extends State<RideCancelledBottomSheet> {
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.autoDismissSeconds;
    if (_remainingSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_remainingSeconds > 1) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            _handleDismiss();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _countdownTimer?.cancel();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveReason = (widget.reason != null &&
            widget.reason!.trim().isNotEmpty)
        ? widget.reason!.trim()
        : 'The passenger has cancelled this ride request.';

    return PopScope(
      canPop: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Alert Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'Ride Cancelled by Passenger',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subtitle / Reason
              Text(
                effectiveReason,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Countdown / Online Notice Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.unit,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Returning online in ${_remainingSeconds}s',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Return CTA Button
              PrimaryButton(
                text: 'RETURN TO DASHBOARD',
                onPressed: _handleDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
