import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/trip_providers.dart';
import '../widgets/ride_cancelled_bottom_sheet.dart';
import 'accepted_ride_screen.dart';
import 'active_trip_navigation_screen.dart';
import 'arrived_at_pickup_screen.dart';
import 'trip_summary_screen.dart';

/// Single `/ride` entry point. Renders the correct lifecycle screen from the
/// authoritative [TripSessionState.status] so every WebSocket-driven transition
/// is reflected without imperative screen-to-screen navigation.
class TripFlowScreen extends ConsumerStatefulWidget {
  const TripFlowScreen({super.key});

  @override
  ConsumerState<TripFlowScreen> createState() => _TripFlowScreenState();
}

class _TripFlowScreenState extends ConsumerState<TripFlowScreen>
    with WidgetsBindingObserver {
  bool _showingCancelledModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(tripSessionNotifierProvider.notifier).checkActiveTripOnResume();
    }
  }

  void _showCancelledModal(String? reason) {
    if (_showingCancelledModal || !mounted) return;
    _showingCancelledModal = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return RideCancelledBottomSheet(
          reason: reason,
          onDismiss: () {
            Navigator.of(modalCtx, rootNavigator: true).pop();
            _showingCancelledModal = false;
            ref.read(tripSessionNotifierProvider.notifier).clear();
            ref.read(availabilityNotifierProvider.notifier).goOnline();
            if (mounted) {
              context.go('/');
            }
          },
        );
      },
    ).then((_) {
      _showingCancelledModal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TripSessionState>(tripSessionNotifierProvider, (previous, next) {
      if (next.status == TripStatus.cancelled) {
        _showCancelledModal(next.cancellationReason);
      }
    });

    final session = ref.watch(tripSessionNotifierProvider);

    if (session.status == TripStatus.cancelled && !_showingCancelledModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCancelledModal(session.cancellationReason);
      });
    }

    return PopScope(
      canPop: !session.isActive,
      child: _buildBody(context, session),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TripSessionState session,
  ) {
    if (session.takenByOther) {
      return const _TripEndedView(
        icon: Icons.directions_car_filled_rounded,
        title: 'Ride taken',
        message: 'This ride was accepted by another driver.',
      );
    }

    // The accept was never confirmed -- the offer had already been cancelled,
    // or the backend did not answer in time. Say so and get the driver off
    // this screen; staying on it is what made them invisible to dispatch.
    if (session.offerLost) {
      return _TripEndedView(
        icon: Icons.timer_off_rounded,
        title: 'Ride no longer available',
        message: session.errorMessage
            ?? 'That ride is no longer available. You are back online.',
      );
    }

    final trip = session.trip;
    if (trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.margin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Active Trip',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'There is no active trip currently assigned.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  text: 'BACK TO DASHBOARD',
                  onPressed: () {
                    ref.read(availabilityNotifierProvider.notifier).goOnline();
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    switch (session.status) {
      case TripStatus.completed:
        return TripSummaryScreen(trip: trip);
      case TripStatus.cancelled:
        return _TripEndedView(
          icon: Icons.cancel_rounded,
          title: 'Ride cancelled',
          message: 'This ride has been cancelled by the passenger.',
          reason: session.cancellationReason,
        );
      case TripStatus.reached:
        return ArrivedAtPickupScreen(trip: trip);
      case TripStatus.inProgress:
        return ActiveTripNavigationScreen(trip: trip);
      case TripStatus.accepted:
        return AcceptedRideScreen(trip: trip);
      case TripStatus.requested:
      case null:
        if (trip.driverId != null) {
          return AcceptedRideScreen(trip: trip);
        }
        return _TripLoadingView(
          message: session.connecting
              ? 'Connecting to the trip…'
              : 'Preparing ride…',
        );
    }
  }
}

class _TripLoadingView extends StatelessWidget {
  const _TripLoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripEndedView extends ConsumerWidget {
  const _TripEndedView({
    required this.icon,
    required this.title,
    required this.message,
    this.reason,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveMsg = (reason != null && reason!.trim().isNotEmpty)
        ? '$message\n\nReason: $reason'
        : message;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.onSurfaceVariant, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                effectiveMsg,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'BACK TO DASHBOARD',
                onPressed: () {
                  ref.read(tripSessionNotifierProvider.notifier).clear();
                  ref.read(availabilityNotifierProvider.notifier).goOnline();
                  context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
