import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_providers.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/models/trip_model.dart';
import '../../../shared/widgets/map_controls.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../trip/presentation/providers/trip_providers.dart';
import '../data/data_sources/driver_location_consumer.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_status_banner.dart';
import 'widgets/driver_map.dart';
import '../../../core/notifications/push_providers.dart';
import '../../../core/notifications/ride_offer_coordinator.dart';
import 'widgets/incoming_ride_bottom_sheet.dart';
import 'widgets/limited_background_banner.dart';
import 'widgets/location_blocked_overlay.dart';
import 'widgets/online_toggle.dart';

/// `/` — the driver home dashboard.
///
/// Composition follows `driver_home_dashboard/code.html`: full-bleed map, glass
/// header, floating map controls, and the centre status toggle. The earnings
/// sheet, bottom nav and SOS FAB are deferred to their own phases (their target
/// routes and endpoints do not exist yet).
class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  bool _followDriver = true;
  bool _mapReady = false;
  StreamSubscription<DriverLocationRideRequest>? _rideRequestSub;
  StreamSubscription<PresentableOffer>? _offerSub;
  StreamSubscription<int>? _expiredOfferSub;
  bool _showingRideModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Start GPS on entry so the map has a fix before the driver taps the
      // toggle. Permission prompts are driven from here, not from goOnline().
      ref.read(locationNotifierProvider.notifier).start();

      final profileState = ref.read(driverProfileNotifierProvider);
      if (profileState is ProfileStateInitial ||
          profileState is ProfileStateError) {
        ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
      }

      _subscribeToRideRequests();
      _checkForActiveTrip();
    });
  }

  /// Crash recovery: on entry, ask the backend for an in-flight trip and rejoin
  /// it. Best-effort — a failure here must not block the dashboard.
  Future<void> _checkForActiveTrip() async {
    try {
      final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
      if (!mounted) return;
      if (trip == null || trip.status.isTerminal) {
        if (ref.read(tripSessionNotifierProvider).isActive) {
          ref.read(tripSessionNotifierProvider.notifier).clear();
        }
        return;
      }
      AppLogger.i(
        'Active trip detected: id=${trip.id}, status=${trip.status.name}. Rejoining /ride...',
      );
      ref.read(tripSessionNotifierProvider.notifier).resumeActiveTrip(trip);
      if (mounted) context.go('/ride');
    } catch (e, st) {
      AppLogger.w('Failed checking for active trip: $e\n$st');
      // No active trip / transient error — stay on the dashboard.
    }
  }

  /// Both channels now go through [RideOfferCoordinator].
  ///
  /// Dispatch announces every offer twice -- a `ride_request` frame on this
  /// socket and an FCM push to the same driver -- so that a backgrounded or
  /// terminated app still hears about it. Subscribing to the socket directly,
  /// as this did, meant the push had nowhere to arrive and the same trip
  /// could raise the sheet twice.
  ///
  /// The socket is still the only channel that can PRESENT an offer: the push
  /// carries `{trip_id, type}` and `GET /ride/trip/<id>/` refuses a driver
  /// who is not yet assigned, so there is no way to learn the rider or the
  /// pickup from a push alone.
  void _subscribeToRideRequests() {
    _rideRequestSub?.cancel();
    _offerSub?.cancel();
    _expiredOfferSub?.cancel();

    final coordinator = ref.read(rideOfferCoordinatorProvider);
    final notifier = ref.read(availabilityNotifierProvider.notifier);

    _rideRequestSub = notifier.rideRequests.listen((event) {
      final tripId = event.tripId;
      if (tripId == null) return;
      coordinator.onSocketOffer(tripId, event.payload);
    });

    _offerSub = coordinator.offers.listen((offer) {
      if (!mounted || _showingRideModal) return;
      _showIncomingRideModal(offer);
    });

    _expiredOfferSub = coordinator.expiredOffers.listen((tripId) {
      if (!mounted) return;
      // A push said a ride was coming and the socket never described it: a
      // later wave took it, or the rider cancelled. Say so, rather than
      // leaving the driver staring at a dashboard after tapping a
      // notification.
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('That ride is no longer available.'),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
      );
    });

    // The terminated-app path: main() read the launch notification before any
    // screen existed, and the socket may have described it before this screen
    // subscribed. A retained offer is shown as soon as there is somewhere to
    // show it.
    final pending = coordinator.pendingOffer;
    if (pending != null && !_showingRideModal) {
      _showIncomingRideModal(pending);
    }
  }

  void _showIncomingRideModal(PresentableOffer offer) {
    _showingRideModal = true;
    final request = DriverLocationRideRequest(offer.payload);
    final coordinator = ref.read(rideOfferCoordinatorProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return IncomingRideBottomSheet(
          request: request,
          onAccept: () {
            Navigator.pop(modalCtx);
            _showingRideModal = false;
            // Settle BEFORE accepting. A second wave's push or socket frame
            // for this trip can land while the accept is in flight, and
            // without this the sheet could come back up over the ride screen
            // and invite a second accept of a trip the driver already has.
            coordinator.markSettled(offer.tripId);
            _acceptRideRequest(request);
          },
          onDecline: () {
            Navigator.pop(modalCtx);
            _showingRideModal = false;
            coordinator.markSettled(offer.tripId);
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Ride request declined.'),
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
            );
          },
        );
      },
    ).then((_) {
      _showingRideModal = false;
      // Dismissed by swiping it away: the driver has seen and ignored it, so
      // it must not be re-presented by the other channel.
      coordinator.markSettled(offer.tripId);
    });
  }

  void _acceptRideRequest(DriverLocationRideRequest event) {
    // Hand the offer to the trip session (opens the trip socket + sends accept)
    // and move into the full-screen ride lifecycle.
    ref.read(tripSessionNotifierProvider.notifier).acceptFromRequest(event);
    context.go('/ride');
  }

  @override
  void dispose() {
    _rideRequestSub?.cancel();
    _offerSub?.cancel();
    _expiredOfferSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-run the pre-flight when returning from system settings: the user may
    // have just enabled GPS or granted permission.
    if (state != AppLifecycleState.resumed || !mounted) return;
    final locationState = ref.read(locationNotifierProvider);
    if (locationState is LocationStateServiceDisabled ||
        (locationState is LocationStatePermissionDenied &&
            locationState.permanent)) {
      ref.read(locationNotifierProvider.notifier).retry();
    } else if (locationState is LocationStateTracking) {
      ref.read(locationNotifierProvider.notifier).refreshPermissions();
    }
    // Re-check for active trip when resuming from background
    _checkForActiveTrip();
  }

  void _recenter() {
    final position = ref.read(driverPositionProvider);
    if (position == null || !_mapReady) return;
    setState(() => _followDriver = true);
    _mapController.move(position, kDefaultMapZoom);
  }

  void _resetBearing() {
    if (!_mapReady) return;
    _mapController.rotate(0);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    final availability = ref.watch(availabilityNotifierProvider);
    final profileState = ref.watch(driverProfileNotifierProvider);
    final hasNetwork = ref.watch(isOnlineNetworkProvider);
    final position = ref.watch(driverPositionProvider);

    _listenForSideEffects();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMapLayer(locationState, availability, position),
          Align(
            alignment: Alignment.topCenter,
            child: DashboardHeader(profileState: profileState),
          ),
          _buildToggle(locationState, availability, profileState, hasNetwork),
          _buildBanners(locationState, availability),
          _buildMapControls(position),
          ..._buildBlockingOverlay(locationState),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layers
  // ---------------------------------------------------------------------------

  /// Initial / Loading / Success states of the map surface.
  ///
  /// There is no meaningful Empty state for a map: "no data" is "no fix yet",
  /// which is rendered as the acquiring spinner below.
  Widget _buildMapLayer(
    LocationState locationState,
    AvailabilityState availability,
    LatLng? position,
  ) {
    final heading = switch (locationState) {
      LocationStateTracking(:final heading) => heading,
      _ => null,
    };
    final weakSignal = switch (locationState) {
      LocationStateTracking(:final weakSignal) => weakSignal,
      _ => false,
    };

    return Stack(
      children: [
        Positioned.fill(
          child: DriverMap(
            controller: _mapController,
            position: position,
            onMapReady: () => _mapReady = true,
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _followDriver && mounted) {
                setState(() => _followDriver = false);
              }
            },
            heading: heading,
            weakSignal: weakSignal,
            pulsing: availability.isEngaged,
          ),
        ),
        if (position == null)
          Positioned.fill(child: _buildAcquiring(locationState)),
      ],
    );
  }

  Widget _buildAcquiring(LocationState locationState) {
    final message = switch (locationState) {
      LocationStateError(:final message) => message,
      LocationStateServiceDisabled() =>
        'Location services are off. Turn them on to go online.',
      LocationStatePermissionDenied(:final permanent) => permanent
          ? 'Location permission is blocked. Enable it in Settings to go '
                'online.'
          : 'SaaradhiGo needs your location to receive ride requests.',
      _ => 'Getting your location…',
    };
    final isError =
        locationState is LocationStateError ||
        locationState is LocationStateServiceDisabled ||
        locationState is LocationStatePermissionDenied;

    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isError)
                const Icon(
                  Icons.location_disabled_outlined,
                  color: AppColors.error,
                  size: 40,
                )
              else
                const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              // Every blocking location state now offers the action that
              // actually resolves it. Previously only `error` had a button,
              // so a driver whose location services were off, or whose
              // permission was denied, was told what was wrong and given
              // nothing to do about it.
              if (locationState is LocationStateError) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () =>
                      ref.read(locationNotifierProvider.notifier).retry(),
                  child: const Text('Retry'),
                ),
              ] else if (locationState is LocationStateServiceDisabled) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => ref
                      .read(locationNotifierProvider.notifier)
                      .openLocationSettings(),
                  child: const Text('Turn on location'),
                ),
              ] else if (locationState is LocationStatePermissionDenied) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => locationState.permanent
                      // Permanently denied: only the system settings screen
                      // can change this, asking again does nothing.
                      ? ref
                            .read(locationNotifierProvider.notifier)
                            .openAppSettings()
                      : ref.read(locationNotifierProvider.notifier).retry(),
                  child: Text(
                    locationState.permanent
                        ? 'Open settings'
                        : 'Grant permission',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Reconnecting / weak-GPS indicators.
  ///
  /// The global "No Internet Connection" strip is owned by
  /// [AppConnectivityHost] (docs/14_ERROR_HANDLING.md:11), so it is NOT
  /// duplicated here.
  Widget _buildBanners(
    LocationState locationState,
    AvailabilityState availability,
  ) {
    final banners = <Widget>[];

    if (availability is AvailabilityStateReconnecting) {
      banners.add(
        const DashboardStatusBanner(
          message: 'RECONNECTING TO DISPATCH…',
          icon: Icons.sync,
          tone: DashboardBannerTone.info,
          showProgress: true,
        ),
      );
    }

    if (locationState is LocationStateTracking && locationState.weakSignal) {
      banners.add(
        const DashboardStatusBanner(
          message: 'WEAK GPS SIGNAL',
          icon: Icons.gps_not_fixed,
        ),
      );
    }

    if (availability.isOnline &&
        locationState is LocationStateTracking &&
        !locationState.hasBackgroundAccess) {
      banners.add(const LimitedBackgroundBanner());
    }

    if (banners.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 144,
      left: AppSpacing.margin,
      right: AppSpacing.margin,
      child: Column(
        children: [
          for (final banner in banners)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: banner,
            ),
        ],
      ),
    );
  }

  Widget _buildMapControls(LatLng? position) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 144,
      right: AppSpacing.margin,
      child: Column(
        children: [
          MapControlButton(
            icon: Icons.explore_outlined,
            onPressed: _resetBearing,
          ),
          const SizedBox(height: AppSpacing.sm),
          MapControlButton(
            icon: Icons.my_location,
            isActive: _followDriver,
            onPressed: position == null ? () {} : _recenter,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    LocationState locationState,
    AvailabilityState availability,
    ProfileState profileState,
    bool hasNetwork,
  ) {
    // Disabled state: anything that makes the transition impossible right now.
    final canStart =
        hasNetwork &&
        availability is! AvailabilityStateGoingOffline &&
        locationState is! LocationStateServiceDisabled &&
        locationState is! LocationStatePermissionDenied;
    // A driver must always be able to cancel an in-flight connection or go
    // offline, even after connectivity/GPS has degraded.
    final enabled = availability.isEngaged || canStart;

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 84,
      left: 0,
      right: 0,
      child: Center(
        child: OnlineToggle(
          state: availability,
          enabled: enabled,
          onPressed: () {
            final notifier = ref.read(availabilityNotifierProvider.notifier);
            if (availability is AvailabilityStateBlocked ||
                availability is AvailabilityStateError) {
              notifier.acknowledge();
            }
            notifier.toggle();
          },
        ),
      ),
    );
  }

  List<Widget> _buildBlockingOverlay(LocationState locationState) {
    final notifier = ref.read(locationNotifierProvider.notifier);

    return switch (locationState) {
      LocationStateServiceDisabled() => [
        LocationBlockedOverlay.serviceDisabled(
          onOpenSettings: notifier.openLocationSettings,
          onRetry: notifier.retry,
        ),
      ],
      LocationStatePermissionDenied(:final permanent) => [
        LocationBlockedOverlay.permissionDenied(
          permanent: permanent,
          onOpenSettings: permanent ? notifier.openAppSettings : notifier.retry,
          onRetry: notifier.retry,
        ),
      ],
      _ => const <Widget>[],
    };
  }

  // ---------------------------------------------------------------------------

  /// Keeps the camera on the driver and surfaces availability messages.
  void _listenForSideEffects() {
    ref.listen<LatLng?>(driverPositionProvider, (previous, next) {
      if (next == null || !_followDriver || !_mapReady) return;
      _mapController.move(next, _mapController.camera.zoom);
    });

    ref.listen<AvailabilityState>(availabilityNotifierProvider, (
      previous,
      next,
    ) {
      final message = next.messageOrNull;
      if (message == null || !mounted) return;
      final isNoVehicle =
          next is AvailabilityStateBlocked &&
          next.reason == AvailabilityBlockReason.noActiveVehicle;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: next is AvailabilityStateError
                ? AppColors.errorContainer
                : AppColors.surfaceContainerHigh,
            action: isNoVehicle
                ? SnackBarAction(
                    label: 'Add Vehicle',
                    textColor: AppColors.primary,
                    onPressed: () => context.push('/vehicle/add'),
                  )
                : null,
          ),
        );
    });
  }
}
