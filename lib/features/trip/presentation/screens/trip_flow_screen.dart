import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/trip_model.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../../../../ui/sg_widgets.dart';
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

  void _showCancelledModal(String? reason, String? cancelledBy) {
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
          actor: CancelActor.fromServer(cancelledBy),
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
      if (next.status == TripStatus.cancelled && !next.releasedBySupport) {
        _showCancelledModal(next.cancellationReason, next.trip?.cancelledBy);
      }
    });

    final session = ref.watch(tripSessionNotifierProvider);

    if (session.status == TripStatus.cancelled &&
        !session.releasedBySupport &&
        !_showingCancelledModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCancelledModal(
          session.cancellationReason,
          session.trip?.cancelledBy,
        );
      });
    }

    return PopScope(
      canPop: !session.isActive,
      child: _buildBody(context, session),
    );
  }

  Widget _buildBody(BuildContext context, TripSessionState session) {
    final l = sgL10n(context);
    if (session.takenByOther) {
      return _TripEndedView(
        icon: SgIcons.pin,
        title: l.tripTakenTitle,
        message: l.tripTakenBody,
      );
    }

    // The accept was never confirmed -- the offer had already been cancelled,
    // or the backend did not answer in time. Say so and get the driver off
    // this screen; staying on it is what made them invisible to dispatch.
    if (session.offerLost) {
      // When the backend refused because of something about the DRIVER, the
      // old title contradicted the message underneath it: "Ride no longer
      // available" above "you have reached the 12-hour daily limit". The
      // ride was available; the driver was locked out.
      return _TripEndedView(
        icon: SgIcons.clock,
        title: session.refusedByBackend ? l.tripRefusedTitle : l.tripGoneTitle,
        message: session.errorMessage ?? l.tripGoneBody,
      );
    }

    final trip = session.trip;
    if (trip == null) {
      return _TripEndedView(
        icon: SgIcons.check,
        title: l.tripNoneTitle,
        message: l.tripNoneBody,
      );
    }

    switch (session.status) {
      case TripStatus.completed:
        return TripSummaryScreen(trip: trip);
      case TripStatus.cancelled:
        if (session.releasedBySupport) {
          return _TripEndedView(
            icon: SgIcons.help,
            title: l.tripSupportReleasedTitle,
            message: l.tripSupportReleasedBody,
          );
        }
        return _TripEndedView(
          icon: SgIcons.close,
          title: cancelledTitle(l, CancelActor.fromServer(trip.cancelledBy)),
          message: l.tripCancelledNext,
          reason: cancelReasonText(
            l,
            session.cancellationReason,
            CancelActor.fromServer(trip.cancelledBy),
          ),
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
          message: session.connecting ? l.tripConnecting : l.tripPreparing,
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
      backgroundColor: SgColors.bg000,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: SgColors.gold500,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: SgSpace.s4),
            Text(
              message,
              style: SgText.body.copyWith(color: SgColors.inkMuted),
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

  final String icon;
  final String title;
  final String message;
  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveMsg = (reason != null && reason!.trim().isNotEmpty)
        ? '$message\n\n${sgL10n(context).tripCancelReason(reason!.trim())}'
        : message;

    return Scaffold(
      backgroundColor: SgColors.bg000,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SgSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: SgColors.bg100,
                    shape: BoxShape.circle,
                    border: Border.all(color: SgColors.line),
                  ),
                  child: Center(
                    child: SgIcon(icon, size: 30, color: SgColors.ink),
                  ),
                ),
              ),
              const SizedBox(height: SgSpace.s5),
              Text(title, textAlign: TextAlign.center, style: SgText.heading),
              const SizedBox(height: SgSpace.s2),
              Text(
                effectiveMsg,
                textAlign: TextAlign.center,
                style: SgText.body.copyWith(color: SgColors.inkMuted),
              ),
              const Spacer(),
              SgPrimaryButton(
                label: sgL10n(context).tripBackHome,
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
