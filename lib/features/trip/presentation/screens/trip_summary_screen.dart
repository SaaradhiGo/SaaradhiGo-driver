import '../../../../core/market/market_format.dart';
import '../../../../core/market/market_config_store.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/trip_model.dart';
import '../../../../ui/driver_trip_views.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../earnings/presentation/earnings_display.dart';
import '../providers/support_end_provider.dart';
import '../providers/trip_providers.dart';
import '../widgets/rate_passenger_sheet.dart';

/// State `completed` — post-drop-off confirmation and earnings. For a cash trip
/// the driver must confirm collection (`{"action":"confirm_cash"}`) before
/// returning to the dashboard; the socket is held open for that.
class TripSummaryScreen extends ConsumerStatefulWidget {
  const TripSummaryScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  bool _rated = false;

  Future<void> _ratePassenger() async {
    final rated = await showRatePassengerSheet(
      context,
      tripId: trip.id,
      riderName: trip.riderName,
    );
    if (!mounted) return;
    if (rated) {
      setState(() => _rated = true);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(sgL10n(context).summaryRatingSaved)),
      );
    }
  }

  TripModel get trip => widget.trip;

  /// Full client fare the rider pays in cash (driver collects the gross, not the
  /// net — the platform commission is settled from the driver wallet separately).
  double get _cashAmount {
    // `rider_payable` is what the rider pays when a promo held on the trip (the
    // fare less the discount SaaradhiGo pays); otherwise the fare, as before.
    final raw = MarketConfigStore.instance.current.stripSymbol(
      trip.riderPayable ?? trip.finalFare ?? trip.estimatedFare ?? '0',
    );
    return double.tryParse(raw) ?? 0;
  }

  String get _fare {
    final raw = trip.finalFare ?? trip.estimatedFare ?? '0';
    return MarketConfigStore.instance.current.withSymbol(raw);
  }

  void _confirmCash() =>
      ref.read(tripSessionNotifierProvider.notifier).confirmCash();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tripSessionNotifierProvider);
    final needsCash = session.needsCashCollection;
    final endedBySupport = session.endedBySupport;
    final platformPaid = trip.paymentStatus == 'waived';
    final cash = (trip.paymentMethod ?? '').toLowerCase() == 'cash';
    final l = sgL10n(context);
    final payment = paymentLabel(trip.paymentMethod, l);

    return TripCompleteView(
      title: endedBySupport ? l.tripSupportEndedTitle : l.summaryTripComplete,
      riderName: trip.riderName,
      // A platform-paid end: the rider's fare is zero and means nothing to
      // the driver, whose earning is in the panel below. Never show ₹0.
      amount: endedBySupport && platformPaid ? null : exactMoney(_fare),
      amountCaption: endedBySupport
          ? (platformPaid ? null : l.summaryFareDistance)
          : l.summaryFare,
      cashToCollect: needsCash ? exactMoney('$_cashAmount') : null,
      paidLine: needsCash || platformPaid
          ? null
          : cash
          ? l.summaryCashCollected
          : l.summaryPaidBy(payment),
      facts: [
        if (trip.distanceKm != null)
          (l.summaryDistance, '${trip.distanceKm!.toStringAsFixed(1)} km'),
        if (trip.durationMin != null)
          (l.summaryTime, l.commonMinutes(trip.durationMin!.round())),
        (l.summaryPayment, payment),
      ],
      notes: [
        if (endedBySupport && platformPaid)
          TripNote(
            key: const Key('summary_platform_paid'),
            text: l.tripSupportEndedPlatformPaid,
          ),
        if (isPositiveAmount(trip.promoDiscount))
          TripNote(
            key: const Key('summary_promo_paid'),
            text: l.summaryPromoPaid,
            trailing: exactMoney(trip.promoDiscount),
          ),
        if (endedBySupport) _supportEarnings(),
      ],
      busy: session.actionInProgress,
      onConfirmCash: _confirmCash,
      // Rating the passenger: the only record that a rider was abusive or
      // kept the driver waiting. An action, not a modal, so a driver with
      // the next ride waiting is not held here.
      onRate: _rated ? null : _ratePassenger,
      onDone: () {
        ref.read(tripSessionNotifierProvider.notifier).clear();
        context.go('/');
      },
    );
  }

  /// What the driver earned on a trip support ended, as the API says it.
  Widget _supportEarnings() {
    final info = ref.watch(supportEndInfoProvider(trip.id));
    final data = info.asData?.value;
    final earning = data?.earning;
    final notice = data?.notice;
    final l = sgL10n(context);
    String body;
    if (earning?.netEarning != null) {
      body = l.summarySupportEarned('${marketSymbol()}${earning!.netEarning}');
    } else if (notice != null) {
      body = notice;
    } else if (info.isLoading) {
      body = l.summaryWorkingOut;
    } else {
      body = l.summaryEarningsLater;
    }
    return TripNote(key: const Key('summary_support_earnings'), text: body);
  }
}
