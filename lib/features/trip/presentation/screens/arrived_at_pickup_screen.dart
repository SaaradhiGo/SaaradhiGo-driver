import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/trip_model.dart';
import '../../../../ui/driver_trip_views.dart';
import '../../../support/presentation/widgets/sos_widgets.dart';
import '../providers/trip_providers.dart';
import '../widgets/cancel_trip_sheet.dart';

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
    if (otp.length != 6) return;
    FocusScope.of(context).unfocus();
    ref.read(tripSessionNotifierProvider.notifier).startRide(otp);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tripSessionNotifierProvider);

    return PinCheckView(
      controller: _otpController,
      riderName: widget.trip.riderName,
      pickupAddress: widget.trip.pickupAddress,
      error: pinErrorText(session.otpError, widget.trip.riderName),
      busy: session.isBusy,
      onStart: _start,
      onCancel: () => showCancelTripSheet(context, ref),
      onChanged: (_) {
        setState(() {});
        if (session.otpError != null) {
          ref.read(tripSessionNotifierProvider.notifier).acknowledgeError();
        }
      },
      topActions: TripSafetyActions(
        tripId: widget.trip.id,
        riderName: widget.trip.riderName,
        size: 44,
      ),
    );
  }
}
