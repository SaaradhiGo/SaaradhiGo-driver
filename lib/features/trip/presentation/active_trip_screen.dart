import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/ws/ws_client.dart';
import '../../duty/presentation/duty_controller.dart';
import '../domain/trip.dart';
import 'trip_controller.dart';
import 'widgets/otp_sheet.dart';
import 'widgets/cancel_sheet.dart';

/// The trip screen: map on top, action panel below.
///
/// The action button is single and always says the one next thing to do —
/// a driver glancing at a mounted phone should never have to choose between
/// two buttons.
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripControllerProvider);
    final trip = state.trip;

    ref.listen(tripControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        showErrorSnack(context, next.error!);
      }
      if (next.justCompleted && !(previous?.justCompleted ?? false)) {
        ref.read(tripControllerProvider.notifier).acknowledgeCompletion();
        context.go(Routes.tripSummary);
      }
      // A trip that ended (cancelled by the rider, say) sends us home rather
      // than leaving a dead trip on screen.
      if (!next.hasTrip && (previous?.hasTrip ?? false)) {
        context.go(Routes.home);
      }
    });

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: EmptyView(
          message: 'No active trip.',
          icon: Icons.local_taxi_outlined,
          action: FilledButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Back to home'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip #${trip.id}'),
        actions: [
          if (state.connection == WsStatus.reconnecting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            tooltip: 'Emergency',
            icon: const Icon(Icons.shield_outlined, color: AppTheme.danger),
            onPressed: () => context.push(Routes.safety),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _TripMap(trip: trip)),
          _TripPanel(trip: trip, isBusy: state.isBusy),
        ],
      ),
    );
  }
}

class _TripMap extends ConsumerWidget {
  const _TripMap({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(dutyControllerProvider).lastPosition;

    // Before the ride starts the driver cares about the pickup; after it
    // starts, about the destination. Centre on whichever is next.
    final targetLat = trip.status == TripStatus.inProgress
        ? trip.destinationLat
        : trip.pickupLat;
    final targetLng = trip.status == TripStatus.inProgress
        ? trip.destinationLng
        : trip.pickupLng;

    final camera = CameraPosition(
      target: LatLng(
        targetLat ?? position?.latitude ?? 17.3850,
        targetLng ?? position?.longitude ?? 78.4867,
      ),
      zoom: 14.5,
    );

    return GoogleMap(
      initialCameraPosition: camera,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      zoomControlsEnabled: false,
      markers: {
        if (trip.pickupLat != null && trip.pickupLng != null)
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(trip.pickupLat!, trip.pickupLng!),
            infoWindow: InfoWindow(
              title: 'Pickup',
              snippet: trip.pickupAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        if (trip.destinationLat != null && trip.destinationLng != null)
          Marker(
            markerId: const MarkerId('drop'),
            position: LatLng(trip.destinationLat!, trip.destinationLng!),
            infoWindow: InfoWindow(
              title: 'Drop',
              snippet: trip.destinationAddress,
            ),
          ),
      },
    );
  }
}

class _TripPanel extends ConsumerWidget {
  const _TripPanel({required this.trip, required this.isBusy});

  final Trip trip;
  final bool isBusy;

  /// Hands navigation to the OS map app. Drivers already trust Google Maps
  /// for turn-by-turn; re-implementing navigation in-app would be worse and
  /// would drain the battery we need for a 10-hour shift.
  Future<void> _navigate(BuildContext context) async {
    final toPickup = trip.status != TripStatus.inProgress;
    final lat = toPickup ? trip.pickupLat : trip.destinationLat;
    final lng = toPickup ? trip.pickupLng : trip.destinationLng;
    if (lat == null || lng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showInfoSnack(context, 'Could not open a maps app.');
      }
    }
  }

  Future<void> _callRider(BuildContext context) async {
    final phone = trip.riderPhone;
    if (phone == null || phone.isEmpty) {
      showInfoSnack(context, 'Rider phone is not available for this trip.');
      return;
    }
    // The number goes straight to the dialer and is never rendered on
    // screen — same phone-privacy posture as the rider app.
    await launchUrl(Uri.parse('tel:$phone'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(tripControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StatusChip(
                    label: trip.status.driverLabel,
                    color: AppTheme.brand,
                    icon: Icons.navigation_rounded,
                  ),
                  const Spacer(),
                  Text(
                    Fmt.money(trip.fareToCollect),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                trip.status == TripStatus.inProgress
                    ? (trip.destinationAddress ?? 'Destination')
                    : (trip.pickupAddress ?? 'Pickup point'),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (trip.riderName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Rider: ${trip.riderName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigate(context),
                      icon: const Icon(Icons.navigation_outlined, size: 20),
                      label: const Text('Navigate'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callRider(context),
                      icon: const Icon(Icons.phone_outlined, size: 20),
                      label: const Text('Call'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PrimaryAction(
                trip: trip,
                isBusy: isBusy,
                onArrived: controller.markArrived,
                onStart: () async {
                  final otp = await showOtpSheet(context, ref);
                  if (otp != null) await controller.startTrip(otp);
                },
                onComplete: controller.completeTrip,
              ),
              if (trip.status == TripStatus.accepted ||
                  trip.status == TripStatus.reached)
                TextButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          final result = await showCancelSheet(context);
                          if (result == null) return;
                          await controller.cancelTrip(
                            reason: result.reason,
                            note: result.note,
                          );
                          if (context.mounted) context.go(Routes.home);
                        },
                  child: const Text(
                    'Cancel trip',
                    style: TextStyle(color: AppTheme.danger),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One button, whose label and action follow the server's state machine.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.trip,
    required this.isBusy,
    required this.onArrived,
    required this.onStart,
    required this.onComplete,
  });

  final Trip trip;
  final bool isBusy;
  final Future<void> Function() onArrived;
  final Future<void> Function() onStart;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    final (String label, Future<void> Function()? action) = switch (trip.status) {
      TripStatus.accepted => ("I've arrived at pickup", onArrived),
      TripStatus.reached => ('Start trip', onStart),
      TripStatus.inProgress => ('Complete trip', onComplete),
      _ => ('Waiting…', null),
    };

    return FilledButton(
      onPressed: (isBusy || action == null) ? null : () => action(),
      child: isBusy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Text(label),
    );
  }
}
