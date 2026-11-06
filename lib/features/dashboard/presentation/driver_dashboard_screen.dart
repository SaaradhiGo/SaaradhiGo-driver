import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_providers.dart';
import '../../../core/maps/sg_map.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/notifications/push_providers.dart';
import '../../../core/notifications/ride_offer_coordinator.dart';
import '../../../core/utils/app_logger.dart';
import '../../../ui/driver_home_view.dart';
import '../../../ui/incoming_offer_card.dart';
import '../../../ui/sg_l10n.dart';
import '../../../ui/sg_text.dart';
import '../../../ui/sg_tokens.dart';
import '../../../ui/sg_widgets.dart';
import '../../earnings/presentation/providers/earnings_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../trip/presentation/providers/trip_providers.dart';
import '../data/data_sources/driver_location_consumer.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/driver_map.dart';
import 'widgets/limited_background_banner.dart';

/// `/` -- the driver home: a map, the online status, today's earnings and the
/// one control that goes online or offline. An incoming offer opens as a
/// full-height card over it.
class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen>
    with WidgetsBindingObserver {
  SgMapController? _mapController;
  bool _followDriver = true;
  bool _mapReady = false;
  StreamSubscription<DriverLocationRideRequest>? _rideRequestSub;
  StreamSubscription<PresentableOffer>? _offerSub;
  StreamSubscription<int>? _expiredOfferSub;
  bool _showingRideModal = false;

  /// When the offer sheet last closed. Accept on the sheet and "Go offline"
  /// on Home sit at the same spot, so a tap meant for Accept that lands just
  /// after the sheet closed (it expired, or was taken) would otherwise take
  /// the driver offline.
  DateTime? _offerSheetClosedAt;
  static const Duration _offlineTapGuard = Duration(milliseconds: 1500);
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The online-time figure only needs minute resolution.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && ref.read(availabilityNotifierProvider).isOnline) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Start GPS on entry so the map has a fix before the driver taps the
      // button. Permission prompts are driven from here, not from goOnline().
      ref.read(locationNotifierProvider.notifier).start();

      final profileState = ref.read(driverProfileNotifierProvider);
      if (profileState is ProfileStateInitial ||
          profileState is ProfileStateError) {
        ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
      }

      // Home is rebuilt on the way back from a trip, so today's figure is
      // fetched again rather than kept from before the trip.
      final earnings = ref.read(earningsNotifierProvider.notifier);
      if (ref.read(earningsNotifierProvider).summary == null) {
        earnings.loadInitialData();
      } else {
        earnings.refresh();
      }

      _subscribeToRideRequests();
      _checkForActiveTrip();
    });
  }

  /// Crash recovery: on entry, ask the backend for an in-flight trip and rejoin
  /// it. Best-effort: a failure here must not block the home.
  ///
  /// Also runs on every resume, which is exactly when a driver taps Accept
  /// on an offer that arrived in the background. The session notifier
  /// decides whether the answer still applies, so a stale "no active trip"
  /// can no longer clear an accept that started after it was asked.
  Future<void> _checkForActiveTrip() async {
    try {
      final session = ref.read(tripSessionNotifierProvider.notifier);
      final trip = await session.reconcileWithServer();
      if (!mounted || trip == null) return;
      AppLogger.i(
        'Active trip detected: id=${trip.id}, status=${trip.status.name}. Rejoining /ride...',
      );
      session.resumeActiveTrip(trip);
      context.go('/ride');
    } catch (e, st) {
      AppLogger.w('Failed checking for active trip: $e\n$st');
    }
  }

  /// Both channels go through [RideOfferCoordinator].
  ///
  /// Dispatch announces every offer twice -- a `ride_request` frame on this
  /// socket and an FCM push to the same driver -- so that a backgrounded or
  /// terminated app still hears about it. The socket is still the only
  /// channel that can PRESENT an offer: the push carries `{trip_id, type}`
  /// and `GET /ride/trip/<id>/` refuses a driver who is not yet assigned.
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
      // later wave took it, or the rider cancelled.
      _snack(sgL10n(context).homeOfferGone);
    });

    // The terminated-app path: main() read the launch notification before any
    // screen existed. A retained offer is shown as soon as there is
    // somewhere to show it.
    final pending = coordinator.pendingOffer;
    if (pending != null && !_showingRideModal) {
      _showIncomingRideModal(pending);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(text), backgroundColor: SgColors.bg200),
    );
  }

  void _showIncomingRideModal(PresentableOffer offer) {
    _showingRideModal = true;
    final request = DriverLocationRideRequest(offer.payload);
    final coordinator = ref.read(rideOfferCoordinatorProvider);

    // The root navigator, so the card covers the tab bar as well.
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: false,
      // A ride is lost only by the driver's own choice. While the sheet is
      // still sliding in -- which is what a resume looks like, because an
      // offer that arrived in the background had no frames to animate in --
      // the barrier covers the lower screen where Accept is about to be,
      // and a tap there dismissed the offer silently.
      isDismissible: false,
      backgroundColor: SgColors.bg000,
      builder: (modalCtx) {
        return SizedBox(
          height: MediaQuery.sizeOf(modalCtx).height,
          child: IncomingOfferCard(
            payload: offer.payload,
            onAccept: () {
              Navigator.pop(modalCtx);
              _showingRideModal = false;
              // Settle BEFORE accepting. A second wave's push or socket frame
              // for this trip can land while the accept is in flight, and
              // without this the card could come back up over the ride screen.
              coordinator.markSettled(offer.tripId);
              _acceptRideRequest(request);
            },
            onDecline: () {
              Navigator.pop(modalCtx);
              _showingRideModal = false;
              coordinator.markSettled(offer.tripId);
              _snack(sgL10n(context).homeOfferDeclined);
            },
            onExpired: () {
              Navigator.pop(modalCtx);
              _showingRideModal = false;
              coordinator.markSettled(offer.tripId);
            },
          ),
        );
      },
    ).then((_) {
      _showingRideModal = false;
      _offerSheetClosedAt = DateTime.now();
      // Home went away under the sheet (a redirect or rebuild during
      // resume): the driver did not choose anything, so the offer stays
      // pending and the next Home presents it again.
      if (!mounted) {
        if (coordinator.pendingOffer?.tripId == offer.tripId) {
          AppLogger.i(
            'Offer ${offer.tripId} closed by navigation; kept for re-display',
          );
        }
        return;
      }
      // Dismissed with the back button: the driver has seen and ignored it,
      // so it must not be re-presented by the other channel.
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
    _clock?.cancel();
    _rideRequestSub?.cancel();
    _offerSub?.cancel();
    _expiredOfferSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
    _checkForActiveTrip();
  }

  void _recenter() {
    final position = ref.read(driverPositionProvider);
    if (position == null || !_mapReady) return;
    setState(() => _followDriver = true);
    _mapController?.moveTo(position, zoom: kDefaultMapZoom);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    final availability = ref.watch(availabilityNotifierProvider);
    final profileState = ref.watch(driverProfileNotifierProvider);
    final hasNetwork = ref.watch(isOnlineNetworkProvider);
    final position = ref.watch(driverPositionProvider);
    final summary = ref.watch(earningsNotifierProvider).summary;

    _listenForSideEffects();

    final engaged = availability.isEngaged;
    final canStart =
        hasNetwork &&
        availability is! AvailabilityStateGoingOffline &&
        locationState is! LocationStateServiceDisabled &&
        locationState is! LocationStatePermissionDenied;
    final blocker = engaged ? null : _blocker(profileState, locationState);
    final heading = switch (locationState) {
      LocationStateTracking(:final heading) => heading,
      _ => null,
    };
    final weakSignal = switch (locationState) {
      LocationStateTracking(:final weakSignal) => weakSignal,
      _ => false,
    };

    final l = sgL10n(context);
    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: DriverHomeView(
        map: DriverMap(
          position: position,
          onMapCreated: (c) {
            _mapController = c;
            _mapReady = true;
          },
          onCameraMove: (camera) {
            if (camera.byGesture && _followDriver && mounted) {
              setState(() => _followDriver = false);
            }
          },
          heading: heading,
          weakSignal: weakSignal,
          pulsing: engaged,
        ),
        online: engaged,
        statusLabel: switch (availability) {
          AvailabilityStateOnline() => l.statusOnline,
          AvailabilityStateGoingOnline() => l.statusGoingOnline,
          AvailabilityStateReconnecting() => l.statusReconnecting,
          AvailabilityStateGoingOffline() => l.statusGoingOffline,
          _ => l.statusOffline,
        },
        busy: availability is AvailabilityStateGoingOffline,
        // Net with commission beside it; gross only from an older API.
        earnings: summary == null
            ? null
            : wholeMoney(
                (summary.todayCommission == null ? null : summary.todayNet) ??
                    summary.todayEarned,
              ),
        commission:
            summary?.todayNet == null || summary?.todayCommission == null
            ? null
            : wholeMoney(summary!.todayCommission),
        trips: summary?.todayTrips,
        onlineFor: switch (availability) {
          AvailabilityStateOnline(:final since) =>
            DateTime.now().difference(since),
          _ => null,
        },
        blocker: blocker,
        notices: [
          if (availability is AvailabilityStateReconnecting)
            HomeNotice(l.homeNoticeReconnecting),
          if (weakSignal) HomeNotice(l.homeNoticeWeakGps),
          if (availability.isOnline &&
              locationState is LocationStateTracking &&
              !locationState.hasBackgroundAccess)
            const LimitedBackgroundBanner(),
          if (position == null && blocker == null && !engaged)
            HomeNotice(l.homeNoticeFindingLocation),
        ],
        onMenu: _showMenu,
        onSafety: () => context.push('/safety'),
        onInbox: () => context.push('/notifications'),
        unread: ref.watch(unreadNotificationsCountProvider),
        onEarnings: () => context.push('/earnings'),
        onGoOnline: canStart ? () => _toggle(availability) : null,
        onGoOffline: () => _toggle(availability),
        mapButton: SgMapButton(
          icon: SgIcons.pin,
          label: l.homeCentreOnMe,
          onTap: position == null ? () {} : _recenter,
        ),
      ),
    );
  }

  void _toggle(AvailabilityState availability) {
    final closedAt = _offerSheetClosedAt;
    if (availability.isEngaged &&
        closedAt != null &&
        DateTime.now().difference(closedAt) < _offlineTapGuard) {
      AppLogger.i('Go offline ignored: the offer sheet has just closed');
      return;
    }
    final notifier = ref.read(availabilityNotifierProvider.notifier);
    if (availability is AvailabilityStateBlocked ||
        availability is AvailabilityStateError) {
      notifier.acknowledge();
    }
    notifier.toggle();
  }

  /// What stops the driver going online right now, with the action that
  /// fixes it. Mirrors the checks goOnline() makes, so the button never
  /// invites a tap that is certain to be refused.
  HomeBlocker? _blocker(ProfileState profileState, LocationState location) {
    final l = sgL10n(context);
    if (profileState is ProfileStateLoaded) {
      final profile = profileState.profile;
      if (!profile.approved && !profile.dispatchEligible) {
        return HomeBlocker(
          title: l.blockerVerifyTitle,
          body: l.blockerVerifyBody,
          actionLabel: l.blockerVerifyAction,
          onAction: () => context.push('/verification-status'),
        );
      }
      final hasVehicle =
          profile.activeVehicle != null || profile.activeVehicleDetails != null;
      if (!hasVehicle) {
        return HomeBlocker(
          title: l.blockerVehicleTitle,
          body: l.blockerVehicleBody,
          actionLabel: l.blockerVehicleAction,
          onAction: () => context.push('/vehicle/add'),
        );
      }
    }
    final notifier = ref.read(locationNotifierProvider.notifier);
    return switch (location) {
      LocationStateServiceDisabled() => HomeBlocker(
        title: l.blockerLocationOffTitle,
        body: l.blockerLocationOffBody,
        actionLabel: l.blockerLocationOffAction,
        onAction: notifier.openLocationSettings,
      ),
      LocationStatePermissionDenied(:final permanent) => HomeBlocker(
        title: l.blockerLocationAccessTitle,
        body: permanent
            ? l.blockerLocationBlockedBody
            : l.blockerLocationNeededBody,
        actionLabel: permanent ? l.blockerOpenSettings : l.blockerAllowLocation,
        onAction: permanent ? notifier.openAppSettings : notifier.retry,
      ),
      _ => null,
    };
  }

  void _showMenu() {
    // Notifications are the bell on Home now, not a menu row.
    final l = sgL10n(context);
    final items = <(String, String, String?)>[
      (l.menuProfile, '/profile', null),
      (l.menuVehicle, '/vehicle', null),
      (l.menuDocuments, '/documents', null),
      (l.menuRewards, '/incentives', null),
      (l.menuReferDriver, '/refer', null),
      (l.commonSafety, '/safety', null),
      (l.menuHelp, '/support', null),
    ];
    final profile = switch (ref.read(driverProfileNotifierProvider)) {
      ProfileStateLoaded(:final profile) => profile,
      _ => null,
    };
    final name = profile?.user?.fullName?.trim();
    final vehicle = profile?.activeVehicleDetails;
    final facts = [
      if ((profile?.ratings ?? 0) > 0) profile!.ratings!.toStringAsFixed(1),
      if (vehicle != null)
        [
          '${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''}'.trim(),
          '${vehicle['vehicle_number'] ?? ''}'.trim(),
        ].where((s) => s.isNotEmpty).join(' - '),
    ].where((s) => s.isNotEmpty).join(' \u00b7 ');
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => SgSheetSurface(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: SgSpace.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name.isEmpty ? l.menuDriverFallback : name,
                      style: SgText.title,
                    ),
                    if (facts.isNotEmpty) Text(facts, style: SgText.caption),
                  ],
                ),
              ),
              for (final item in items)
                InkWell(
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.push(item.$2);
                  },
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Expanded(child: Text(item.$1, style: SgText.bodyLg)),
                        if (item.$3 != null)
                          Text(
                            item.$3!,
                            style: SgText.body.copyWith(
                              color: SgColors.goldText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps the camera on the driver and surfaces availability messages.
  void _listenForSideEffects() {
    ref.listen<LatLng?>(driverPositionProvider, (previous, next) {
      if (next == null || !_followDriver || !_mapReady) return;
      _mapController?.moveTo(next);
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
            backgroundColor: SgColors.bg200,
            action: isNoVehicle
                ? SnackBarAction(
                    label: sgL10n(context).blockerVehicleAction,
                    textColor: SgColors.goldText,
                    onPressed: () => context.push('/vehicle/add'),
                  )
                : null,
          ),
        );
    });
  }
}
