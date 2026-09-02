import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../support/presentation/widgets/sos_widgets.dart';
import '../providers/trip_providers.dart';
import '../widgets/cancel_trip_sheet.dart';
import '../widgets/rider_summary_row.dart';

/// State `reached` — driver is at pickup and enters the rider's 6-digit OTP to
/// start the trip. The OTP is validated server-side; the driver never sees it
/// (the backend returns it only to the rider), they type what the rider reads.
class ArrivedAtPickupScreen extends ConsumerStatefulWidget {
  const ArrivedAtPickupScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  ConsumerState<ArrivedAtPickupScreen> createState() =>
      _ArrivedAtPickupScreenState();
}

class _ArrivedAtPickupScreenState extends ConsumerState<ArrivedAtPickupScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _start() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the rider\'s 6-digit OTP.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(tripSessionNotifierProvider.notifier).startRide(otp);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tripSessionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Arrived at Pickup',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          TripChatButton(
            tripId: widget.trip.id,
            riderName: widget.trip.riderName,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.sm),
          TripSosButton(tripId: widget.trip.id, size: 40),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassPanel(
                child: RiderSummaryRow(
                  name: widget.trip.riderName ?? 'Passenger',
                  subtitle: widget.trip.pickupAddress,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'START TRIP OTP',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ask the rider for their 6-digit PIN to start the trip.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primaryContainer,
                  letterSpacing: 12,
                ),
                onChanged: (_) {
                  if (session.otpError != null) {
                    ref
                        .read(tripSessionNotifierProvider.notifier)
                        .acknowledgeError();
                  }
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  errorText: session.otpError,
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'START TRIP',
                isLoading: session.isBusy,
                onPressed: session.isBusy ? null : _start,
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                text: 'CANCEL RIDE',
                onPressed: session.isBusy
                    ? null
                    : () => showCancelTripSheet(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
