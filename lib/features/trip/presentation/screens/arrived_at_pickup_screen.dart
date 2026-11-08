import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/maps/sg_map.dart';

import '../../../../domain/models/trip_model.dart';
import '../../../../ui/driver_trip_views.dart';
import '../../../../ui/sg_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../support/presentation/widgets/sos_widgets.dart';
import '../providers/trip_providers.dart';
import '../trip_navigation.dart';
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
    if (otp.length != kTripPinLength) return;
    FocusScope.of(context).unfocus();
    ref.read(tripSessionNotifierProvider.notifier).startRide(otp);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tripSessionNotifierProvider);

    final trip = widget.trip;
    final pickup = trip.pickupLat == null || trip.pickupLng == null
        ? null
        : LatLng(trip.pickupLat!, trip.pickupLng!);
    final klass = trip.vehicleType?.trim();
    return PinCheckView(
      controller: _otpController,
      riderName: widget.trip.riderName,
      vehicleClass: klass == null || klass.isEmpty
          ? null
          : '${klass[0].toUpperCase()}${klass.substring(1)}',
      // Trip detail's own `driver_earning`; nothing when the API sent none.
      earning: sgMoney(trip.driverEarning),
      map: pickup == null
          ? null
          : SgMap(
              initialCenter: pickup,
              initialZoom: 15,
              interactive: false,
              markers: [
                SgMarker(
                  id: 'pickup',
                  point: pickup,
                  icon: sgPickupMarker(size: 20),
                  anchor: const Offset(0.5, 0.5),
                  label: sgL10n(context).offerPickup,
                ),
              ],
            ),
      riderRating: widget.trip.riderRating,
      pickupAddress: widget.trip.pickupAddress,
      error: pinErrorText(
        session.otpError,
        widget.trip.riderName,
        sgL10n(context),
      ),
      busy: session.isBusy,
      onStart: _start,
      onCancel: () => showCancelTripSheet(context, ref),
      onChanged: (_) {
        if (session.otpError != null) {
          ref.read(tripSessionNotifierProvider.notifier).acknowledgeError();
        }
      },
      // Chat moved onto the rider row as the 56px button; SOS stays on top.
      onMessage: () => context.push(tripChatPath(widget.trip)),
      topActions: TripSosButton(tripId: widget.trip.id, size: 48),
    );
  }
}
