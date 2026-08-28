import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_providers.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/map_controls.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_status_banner.dart';
import 'widgets/driver_map.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Start GPS on entry so the map has a fix before the driver taps the
      // toggle. Permission prompts are driven from here, not from goOnline().
      ref.read(locationNotifierProvider.notifier).start();
    });
  }

  @override
  void dispose() {
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
    }
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
          _buildBanners(locationState, availability, hasNetwork),
          _buildMapControls(position),
          _buildToggle(locationState, availability, profileState, hasNetwork),
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
      LocationStateServiceDisabled() => 'Location services are off.',
      LocationStatePermissionDenied() => 'Location permission required.',
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
              if (locationState is LocationStateError) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () =>
                      ref.read(locationNotifierProvider.notifier).retry(),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Offline / Refreshing / weak-GPS indicators.
  Widget _buildBanners(
    LocationState locationState,
    AvailabilityState availability,
    bool hasNetwork,
  ) {
    final banners = <Widget>[];

    if (!hasNetwork) {
      banners.add(
        const DashboardStatusBanner(
          message: 'NO INTERNET CONNECTION',
          icon: Icons.wifi_off,
          tone: DashboardBannerTone.error,
        ),
      );
    }

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

    if (banners.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 76,
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
      top: MediaQuery.paddingOf(context).top + 140,
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
    final profileReady = profileState is ProfileStateLoaded;
    final canStart =
        hasNetwork &&
        profileReady &&
        availability is! AvailabilityStateGoingOffline &&
        locationState is! LocationStateServiceDisabled &&
        locationState is! LocationStatePermissionDenied;
    // A driver must always be able to cancel an in-flight connection or go
    // offline, even after connectivity/GPS has degraded.
    final enabled = availability.isEngaged || canStart;

    return Align(
      alignment: const Alignment(0, -0.35),
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
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: next is AvailabilityStateError
                ? AppColors.errorContainer
                : AppColors.surfaceContainerHigh,
          ),
        );
    });
  }
}
