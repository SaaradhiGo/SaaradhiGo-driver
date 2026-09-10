import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../providers/trip_providers.dart';
import 'accepted_ride_screen.dart';
import 'active_trip_navigation_screen.dart';
import 'arrived_at_pickup_screen.dart';
import 'trip_summary_screen.dart';

/// Single `/ride` entry point. Renders the correct lifecycle screen from the
/// authoritative [TripSessionState.status] so every WebSocket-driven transition
/// is reflected without imperative screen-to-screen navigation.
class TripFlowScreen extends ConsumerWidget {
  const TripFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tripSessionNotifierProvider);

    return PopScope(
      canPop: !session.isActive,
      child: _buildBody(context, ref, session),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TripSessionState session,
  ) {
    if (session.takenByOther) {
      return const _TripEndedView(
        icon: Icons.directions_car_filled_rounded,
        title: 'Ride taken',
        message: 'This ride was accepted by another driver.',
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
                  onPressed: () => context.go('/'),
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
        return const _TripEndedView(
          icon: Icons.cancel_rounded,
          title: 'Ride cancelled',
          message: 'This ride has been cancelled.',
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
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                message,
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
