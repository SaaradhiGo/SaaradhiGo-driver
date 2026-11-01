/// App catch-up phase 2, driver side: D1 (promo paid by SaaradhiGo, cash to
/// collect), D2 (reward lines), D4 (trips support ended or released) and the US
/// pass-through lines. Fixtures are the backend's own payloads
/// (test/support/money_fixtures.dart).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saaradhigo_driver/core/market/market_config.dart';
import 'package:saaradhigo_driver/core/market/market_config_store.dart';
import 'package:saaradhigo_driver/core/network/websocket_service.dart';
import 'package:saaradhigo_driver/core/storage/local_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/earning_model.dart';
import 'package:saaradhigo_driver/domain/models/earnings_summary_model.dart';
import 'package:saaradhigo_driver/domain/models/notification_model.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/earnings/domain/repositories/earnings_repository.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/earnings_display.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/providers/earnings_providers.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/earning_trip_tile.dart';
import 'package:saaradhigo_driver/features/earnings/presentation/widgets/earnings_breakdown_card.dart';
import 'package:saaradhigo_driver/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:saaradhigo_driver/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:saaradhigo_driver/features/trip/data/data_sources/trip_status_consumer.dart';
import 'package:saaradhigo_driver/features/trip/domain/repositories/trip_repository.dart';
import 'package:saaradhigo_driver/features/trip/domain/support_end.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_providers.dart';
import 'package:saaradhigo_driver/features/trip/presentation/providers/trip_session_notifier.dart';
import 'package:saaradhigo_driver/features/trip/presentation/screens/trip_flow_screen.dart';
import 'package:saaradhigo_driver/features/trip/presentation/screens/trip_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_config_fixtures.dart';
import '../support/money_fixtures.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _Consumer implements TripStatusConsumer {
  _Consumer(this.tripId);

  @override
  final int tripId;
  final events$ = StreamController<TripStatusEvent>.broadcast();
  final conn$ = StreamController<WebSocketState>.broadcast();

  @override
  Stream<TripStatusEvent> get events => events$.stream;
  @override
  Stream<WebSocketState> get connectionState => conn$.stream;
  @override
  void connect() {}
  @override
  void disconnect() {}
  @override
  Future<void> dispose() async {
    await events$.close();
    await conn$.close();
  }

  @override
  void sendAction(String action, {String? otp, String? reason}) {}
  @override
  void updateNetworkStatus(bool isOnline) {}
}

class _Trips implements TripRepository {
  _Trips({this.detail, this.throws = false});

  final TripModel? detail;
  final bool throws;
  int reads = 0;

  @override
  Future<TripModel?> getActiveTrip() async => null;

  @override
  Future<TripModel?> getTrip(int tripId) async {
    reads++;
    if (throws) throw Exception('offline');
    return detail;
  }

  @override
  Future<void> driverCancel(
    int tripId, {
    required String reason,
    String? note,
  }) async {}
}

class _Earnings implements EarningsRepository {
  _Earnings(this.rows);
  final List<EarningModel> rows;

  @override
  Future<List<EarningModel>> getEarningsList({
    int page = 1,
    int pageSize = 20,
  }) async => rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notices implements NotificationsRepository {
  _Notices(this.notices);
  final List<NotificationModel> notices;

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
    NotificationCategory? category,
  }) async => notices;

  @override
  Future<void> markNotificationAsRead(int notificationId) async {}

  @override
  Future<void> markAllNotificationsAsRead() async {}
}

class _SeededSession extends TripSessionNotifier {
  _SeededSession(this.seed);
  final TripSessionState seed;
  @override
  TripSessionState build() {
    super.build();
    return seed;
  }
}

EarningModel _row(Map<String, dynamic> json) => EarningModel.fromJson(json);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void _useUs() => MarketConfigStore.instance.debugSet(
  MarketConfig.fromData((usBody()['data'] as Map).cast<String, dynamic>()),
);

void _useIndia() => MarketConfigStore.instance.debugSet(MarketConfig.builtIn);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
    _useIndia();
  });

  tearDown(() async {
    _useIndia();
    await LocalStorageService.clearAll();
  });

  // ------------------------------------------------------------ the models
  group('the models read the money-phase keys', () {
    test('a cash promo row: collect, promo paid, credited, label', () {
      final e = _row(indiaCashPromoRow());
      expect(e.tripId, 9002);
      expect(e.amountCollected, '200.00');
      expect(e.platformFee, '30.00');
      expect(e.netEarning, '170.00');
      expect(e.cashToCollect, '150.00');
      expect(e.promoPaidByPlatform, '50.00');
      expect(e.promoPaidLabel, 'Promo paid by SaaradhiGo');
      expect(e.promoCreditedToWallet, isTrue);
      expect(e.deductions, isEmpty);
    });

    test('a US cash row: the two deductions with the API labels', () {
      final e = _row(usCashRow());
      expect(e.cashToCollect, '22.15');
      expect(e.taxCollected, '1.65');
      expect(e.regulatoryFeeCollected, '0.50');
      expect(e.deductions.map((d) => d.kind), [
        'tax_collected',
        'regulatory_fee_collected',
      ]);
      expect(
        e.deductions.first.label,
        'Sales tax collected (remitted by SaaradhiGo)',
      );
      expect(e.deductions.last.amount, '0.50');
      // Never recomputed: gross, commission and net are the API's.
      expect(
        (e.amountCollected, e.platformFee, e.netEarning),
        ('20.00', '5.00', '15.00'),
      );
    });

    test(
      'an India row and a pre-module-12 row carry none of the new fields',
      () {
        for (final json in [indiaOnlineRow(), legacyRow()]) {
          final e = _row(json);
          expect(e.cashToCollect, isNull);
          expect(e.promoPaidByPlatform, isNull);
          expect(e.taxCollected, isNull);
          expect(e.regulatoryFeeCollected, isNull);
          expect(e.deductions, isEmpty);
        }
      },
    );

    test('the summary reads promo, rewards, pass-through and the API net', () {
      final s = EarningsSummaryModel.fromJson(summaryWithPromoAndRewards());
      expect(s.totalNet, '1062.50');
      expect(s.promoPaidByPlatform, '100.00');
      expect(s.todayPromoPaidByPlatform, '50.00');
      expect(s.incentiveRewards, '500.00');
      expect(s.referralRewards, '100.00');
      expect(s.incentiveCommission, 'none');
      expect(s.incentiveTax, 'not configured');
      final us = EarningsSummaryModel.fromJson(summaryUs());
      expect(us.taxCollected, '3.30');
      expect(us.regulatoryFeesCollected, '1.00');
    });

    test(
      'a summary without the keys decodes to nulls, never invented zeros',
      () {
        final s = EarningsSummaryModel.fromJson({
          'total_earned': '100.00',
          'total_trips': 1,
        });
        expect(s.totalNet, isNull);
        expect(s.promoPaidByPlatform, isNull);
        expect(s.incentiveRewards, isNull);
        expect(s.taxCollected, isNull);
      },
    );

    test(
      'the trip detail carries the promo discount and what the rider pays',
      () {
        final t = TripModel.fromJson(tripDetailCashPromo());
        expect(t.promoDiscount, '50.00');
        expect(t.riderPayable, '150.00');
        expect(t.paymentMethod, 'cash');
        final plain = TripModel.fromJson({'id': 1, 'status': 'completed'});
        expect(plain.promoDiscount, isNull);
        expect(plain.riderPayable, isNull);
      },
    );
  });

  // ------------------------------------------------------------- D1 tile
  group('D1 the earnings row', () {
    testWidgets(
      'a cash promo trip: Collect, Promo paid by SaaradhiGo, net unchanged',
      (t) async {
        await t.pumpWidget(
          _host(EarningTripTile(earning: _row(indiaCashPromoRow()))),
        );
        expect(find.text('+₹170.00'), findsOneWidget);
        expect(find.text('Collect'), findsOneWidget);
        expect(find.text('₹150.00'), findsOneWidget);
        expect(find.text('Promo paid by SaaradhiGo'), findsOneWidget);
        expect(find.text('₹50.00'), findsOneWidget);
        expect(find.text('Credited to your wallet'), findsOneWidget);
      },
    );

    testWidgets('an India online trip looks exactly as it did', (t) async {
      await t.pumpWidget(
        _host(EarningTripTile(earning: _row(indiaOnlineRow()))),
      );
      expect(find.text('Trip #9002'), findsNothing);
      expect(find.text('Trip #9001'), findsOneWidget);
      expect(find.text('+₹170.00'), findsOneWidget);
      expect(find.text('Collect'), findsNothing);
      expect(find.textContaining('Promo paid'), findsNothing);
      expect(find.textContaining('remitted'), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('a pre-module-12 row looks exactly as it did', (t) async {
      await t.pumpWidget(_host(EarningTripTile(earning: _row(legacyRow()))));
      expect(find.text('+₹170.00'), findsOneWidget);
      expect(find.text('Collect'), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('a cash trip with no promo shows Collect and no promo line', (
      t,
    ) async {
      await t.pumpWidget(_host(EarningTripTile(earning: _row(indiaCashRow()))));
      expect(find.text('Collect'), findsOneWidget);
      expect(find.text('₹200.00'), findsOneWidget);
      expect(find.textContaining('Promo paid'), findsNothing);
    });

    testWidgets('a zero promo is not a line', (t) async {
      final json = {...indiaCashRow(), 'promo_paid_by_platform': '0.00'};
      await t.pumpWidget(_host(EarningTripTile(earning: _row(json))));
      expect(find.textContaining('Promo paid'), findsNothing);
    });
  });

  group('US pass-through on the trip row', () {
    testWidgets('a cash trip: Collect 22.15 and both deductions, net 15.00', (
      t,
    ) async {
      _useUs();
      await t.pumpWidget(_host(EarningTripTile(earning: _row(usCashRow()))));
      expect(find.text('+\$15.00'), findsOneWidget);
      expect(find.text('\$22.15'), findsOneWidget);
      expect(
        find.text('Sales tax collected (remitted by SaaradhiGo)'),
        findsOneWidget,
      );
      expect(find.text('\$1.65'), findsOneWidget);
      expect(
        find.text('Regulatory fee collected (remitted by SaaradhiGo)'),
        findsOneWidget,
      );
      expect(find.text('\$0.50'), findsOneWidget);
    });

    testWidgets("a zone's own fee name comes through from the API label", (
      t,
    ) async {
      _useUs();
      final json = usCashRow();
      (json['deductions'] as List)[1] = {
        'kind': 'regulatory_fee_collected',
        'label': 'Airport fee collected (remitted by SaaradhiGo)',
        'amount': '0.50',
      };
      await t.pumpWidget(_host(EarningTripTile(earning: _row(json))));
      expect(
        find.text('Airport fee collected (remitted by SaaradhiGo)'),
        findsOneWidget,
      );
    });

    testWidgets('an online trip: tax and fee are on the row, not earnings', (
      t,
    ) async {
      _useUs();
      await t.pumpWidget(_host(EarningTripTile(earning: _row(usOnlineRow()))));
      expect(find.text('+\$15.00'), findsOneWidget);
      expect(find.text('Collect'), findsNothing);
      expect(
        find.text('Sales tax collected (remitted by SaaradhiGo)'),
        findsOneWidget,
      );
      expect(
        find.text('Regulatory fee collected (remitted by SaaradhiGo)'),
        findsOneWidget,
      );
    });
  });

  // ------------------------------------------------------ D1/D2 totals
  group('the totals card', () {
    EarningsBreakdownCard card(Map<String, dynamic> summaryJson) {
      final s = EarningsSummaryModel.fromJson(summaryJson);
      return EarningsBreakdownCard(
        grossFares: s.totalEarned,
        commission: s.totalCommission,
        commissionRate: commissionRateLabel(s.commissionPercent),
        netEarnings: s.totalNet,
        promoPaid: s.promoPaidByPlatform,
        promoPaidToday: s.todayPromoPaidByPlatform,
        promoPaidLabel: s.promoPaidLabel,
        incentiveRewards: s.incentiveRewards,
        referralRewards: s.referralRewards,
        incentiveCommission: s.incentiveCommission,
        incentiveTax: s.incentiveTax,
        taxCollected: s.taxCollected,
        taxCollectedLabel: s.taxCollectedLabel,
        regulatoryFees: s.regulatoryFeesCollected,
      );
    }

    testWidgets('with every new key empty, nothing new appears', (t) async {
      await t.pumpWidget(_host(card(summaryNothingNew())));
      expect(find.text('Trip Fares (Gross)'), findsOneWidget);
      expect(find.text('-₹187.50'), findsOneWidget);
      expect(find.text('₹1062.50'), findsOneWidget);
      expect(find.textContaining('Promo paid'), findsNothing);
      expect(find.textContaining('rewards'), findsNothing);
      expect(find.textContaining('remitted'), findsNothing);
      expect(find.textContaining('Tax:'), findsNothing);
    });

    testWidgets('D1: promo paid by SaaradhiGo is its own line, with today', (
      t,
    ) async {
      await t.pumpWidget(_host(card(summaryWithPromoAndRewards())));
      expect(find.byKey(const Key('breakdown_promo_paid')), findsOneWidget);
      expect(find.text('Promo paid by SaaradhiGo'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('breakdown_promo_paid')),
          matching: find.text('₹100.00'),
        ),
        findsOneWidget,
      );
      expect(find.text('Today ₹50.00'), findsOneWidget);
      // Gross, commission and net are exactly the API's.
      expect(find.text('-₹187.50'), findsOneWidget);
      expect(find.text('₹1062.50'), findsOneWidget);
    });

    testWidgets(
      'D2: incentive and referral rewards, no commission, tax not configured',
      (t) async {
        await t.pumpWidget(_host(card(summaryWithPromoAndRewards())));
        expect(find.text('Incentive rewards'), findsOneWidget);
        expect(find.text('₹500.00'), findsOneWidget);
        expect(find.text('Referral rewards'), findsOneWidget);
        expect(
          find.text(
            'No commission · Tax: not configured · Paid in your weekly payout',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('D2: only the reward the API returned is shown', (t) async {
      final json = {...summaryNothingNew(), 'referral_rewards': '100.00'};
      await t.pumpWidget(_host(card(json)));
      expect(find.text('Referral rewards'), findsOneWidget);
      expect(find.text('Incentive rewards'), findsNothing);
    });

    testWidgets('US: tax and fees collected sit apart from earned and net', (
      t,
    ) async {
      _useUs();
      await t.pumpWidget(_host(card(summaryUs())));
      expect(
        find.text('Sales tax collected (remitted by SaaradhiGo)'),
        findsOneWidget,
      );
      expect(find.text('\$3.30'), findsOneWidget);
      expect(
        find.text('Regulatory fees collected (remitted by SaaradhiGo)'),
        findsOneWidget,
      );
      expect(find.text('\$1.00'), findsOneWidget);
      expect(find.text('\$30.00'), findsOneWidget);
    });
  });

  test('the earnings net is the API net when it sends one', () {
    final s = EarningsSummaryModel.fromJson(summaryNothingNew());
    final net =
        s.totalNet ??
        netFromGrossAndCommission(s.totalEarned, s.totalCommission);
    expect(net, '1062.50');
    final old = EarningsSummaryModel.fromJson({
      'total_earned': '1000.00',
      'total_commission': '150.00',
    });
    expect(
      old.totalNet ??
          netFromGrossAndCommission(old.totalEarned, old.totalCommission),
      '850.00',
    );
  });

  // -------------------------------------------------- D4: session state
  group('D4 the session knows a trip support ended or released', () {
    ProviderContainer container({
      required _Trips trips,
      void Function(_Consumer)? capture,
    }) {
      final c = ProviderContainer(
        overrides: [
          tripRepositoryProvider.overrideWithValue(trips),
          tripStatusConsumerFactoryProvider.overrideWithValue((id) {
            final consumer = _Consumer(id);
            capture?.call(consumer);
            return consumer;
          }),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    TripStatusChanged frame(Map<String, dynamic> raw) => TripStatusChanged(
      status: tripStatusFromWsAction(raw['status']?.toString())!,
      raw: raw,
      message: raw['message']?.toString(),
    );

    test('the wording is recognised, and only the support wording', () {
      expect(
        isSupportEndMessage('Your ride was ended by SaaradhiGo support.'),
        isTrue,
      );
      expect(
        isSupportCancelMessage('Your ride was cancelled by support.'),
        isTrue,
      );
      expect(isSupportEndMessage('Trip completed'), isFalse);
      expect(isSupportEndMessage(null), isFalse);
      expect(isSupportCancelMessage('Rider cancelled the trip.'), isFalse);
    });

    test(
      'an ended trip is flagged, and its money is read back from the server',
      () async {
        late _Consumer consumer;
        final trips = _Trips(
          detail: TripModel.fromJson(tripDetailPlatformFunded()),
        );
        final c = container(trips: trips, capture: (x) => consumer = x);
        c
            .read(tripSessionNotifierProvider.notifier)
            .resumeActiveTrip(
              const TripModel(
                id: 9003,
                status: TripStatus.inProgress,
                paymentMethod: 'cash',
                estimatedFare: '200.00',
              ),
            );
        consumer.events$.add(frame(supportEndedFrame()));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final s = c.read(tripSessionNotifierProvider);
        expect(s.status, TripStatus.completed);
        expect(s.endedBySupport, isTrue);
        expect(s.releasedBySupport, isFalse);
        expect(trips.reads, 1);
        expect(s.trip?.finalFare, '0.00');
        expect(s.trip?.paymentStatus, 'waived');
        // Nothing was charged, so there is no cash to collect or confirm.
        expect(s.needsCashCollection, isFalse);
      },
    );

    test('an ordinary cash completion still needs collection', () async {
      late _Consumer consumer;
      final trips = _Trips(detail: TripModel.fromJson(tripDetailCashPromo()));
      final c = container(trips: trips, capture: (x) => consumer = x);
      c
          .read(tripSessionNotifierProvider.notifier)
          .resumeActiveTrip(
            const TripModel(
              id: 9002,
              status: TripStatus.inProgress,
              paymentMethod: 'cash',
              estimatedFare: '200.00',
            ),
          );
      consumer.events$.add(
        const TripStatusChanged(
          status: TripStatus.completed,
          raw: {'status': 'complete'},
          message: 'Trip completed',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final s = c.read(tripSessionNotifierProvider);
      expect(s.endedBySupport, isFalse);
      expect(s.needsCashCollection, isTrue);
      expect(s.trip?.riderPayable, '150.00');
      expect(s.trip?.promoDiscount, '50.00');
    });

    test('a failed read-back leaves the trip as it was', () async {
      late _Consumer consumer;
      final trips = _Trips(throws: true);
      final c = container(trips: trips, capture: (x) => consumer = x);
      c
          .read(tripSessionNotifierProvider.notifier)
          .resumeActiveTrip(
            const TripModel(
              id: 9002,
              status: TripStatus.inProgress,
              paymentMethod: 'cash',
              estimatedFare: '200.00',
            ),
          );
      consumer.events$.add(frame({...supportEndedFrame(), 'trip_id': 9002}));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final s = c.read(tripSessionNotifierProvider);
      expect(s.status, TripStatus.completed);
      expect(s.trip?.estimatedFare, '200.00');
      expect(s.trip?.riderPayable, isNull);
    });

    test(
      'a release by support is flagged; a rider cancellation is not',
      () async {
        late _Consumer consumer;
        final c = container(trips: _Trips(), capture: (x) => consumer = x);
        final notifier = c.read(tripSessionNotifierProvider.notifier);
        notifier.resumeActiveTrip(
          const TripModel(id: 9004, status: TripStatus.accepted, driverId: 5),
        );
        consumer.events$.add(frame(supportReleasedFrame()));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        var s = c.read(tripSessionNotifierProvider);
        expect(s.status, TripStatus.cancelled);
        expect(s.releasedBySupport, isTrue);

        notifier.clear();
        notifier.resumeActiveTrip(
          const TripModel(id: 9005, status: TripStatus.accepted, driverId: 5),
        );
        consumer.events$.add(frame(riderCancelledFrame()));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        s = c.read(tripSessionNotifierProvider);
        expect(s.status, TripStatus.cancelled);
        expect(s.releasedBySupport, isFalse);
      },
    );
  });

  // ----------------------------------------------------- D1/D4: screens
  group('the trip screens', () {
    Future<void> pumpSummary(
      WidgetTester t, {
      required TripSessionState session,
      List<EarningModel> earnings = const [],
      List<NotificationModel> notices = const [],
    }) async {
      t.view.devicePixelRatio = 1.0;
      await t.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.view.resetDevicePixelRatio();
      });
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            tripSessionNotifierProvider.overrideWith(
              () => _SeededSession(session),
            ),
            earningsRepositoryProvider.overrideWithValue(_Earnings(earnings)),
            notificationsRepositoryProvider.overrideWithValue(
              _Notices(notices),
            ),
          ],
          child: MaterialApp(home: TripSummaryScreen(trip: session.trip!)),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'a completed cash promo trip: collect what the rider pays, promo paid on its own line',
      (t) async {
        final trip = TripModel.fromJson(tripDetailCashPromo());
        await pumpSummary(
          t,
          session: TripSessionState(trip: trip, status: TripStatus.completed),
        );
        expect(find.text('Trip Completed'), findsOneWidget);
        expect(find.byKey(const Key('summary_promo_paid')), findsOneWidget);
        expect(find.text('Promo paid by SaaradhiGo'), findsOneWidget);
        expect(find.text('₹50.00'), findsOneWidget);
        // The cash prompt is for what the rider pays, not the full fare.
        expect(find.textContaining('Collect ₹150.00 cash'), findsOneWidget);
        expect(find.byKey(const Key('summary_support_earnings')), findsNothing);
      },
    );

    testWidgets('a completed cash trip with no promo is what it always was', (
      t,
    ) async {
      const trip = TripModel(
        id: 9010,
        status: TripStatus.completed,
        paymentMethod: 'cash',
        estimatedFare: '200.00',
        finalFare: '200.00',
      );
      await pumpSummary(
        t,
        session: const TripSessionState(
          trip: trip,
          status: TripStatus.completed,
        ),
      );
      expect(find.text('Trip Completed'), findsOneWidget);
      expect(find.byKey(const Key('summary_promo_paid')), findsNothing);
      expect(find.textContaining('Collect ₹200.00 cash'), findsOneWidget);
    });

    testWidgets(
      'D4 platform-funded end: the title, the platform-paid line, no cash to confirm',
      (t) async {
        final trip = TripModel.fromJson(tripDetailPlatformFunded());
        await pumpSummary(
          t,
          session: TripSessionState(
            trip: trip,
            status: TripStatus.completed,
            endedBySupport: true,
          ),
          notices: [
            const NotificationModel(
              id: 1,
              title: 'Your trip was ended',
              message: platformFundedNoticeText,
            ),
          ],
        );
        expect(find.text(kSupportEndedTitle), findsOneWidget);
        expect(
          find.text('Trip ended by SaaradhiGo: earnings paid by SaaradhiGo'),
          findsOneWidget,
        );
        expect(find.text(platformFundedNoticeText), findsOneWidget);
        // The rider's zero fare is not shown as if it were the driver's earning.
        expect(find.byKey(const Key('summary_fare')), findsNothing);
        expect(find.text('CONFIRM CASH COLLECTED'), findsNothing);
        expect(find.text('BACK TO DASHBOARD'), findsOneWidget);
      },
    );

    testWidgets('D4 standard end: the settled row says what was earned', (
      t,
    ) async {
      final trip = TripModel.fromJson({
        ...tripDetailPlatformFunded(),
        'id': 9006,
        'final_fare': '108.50',
        'payment_status': 'completed',
        'payment_method': 'online',
      });
      await pumpSummary(
        t,
        session: TripSessionState(
          trip: trip,
          status: TripStatus.completed,
          endedBySupport: true,
        ),
        earnings: [
          _row({
            ...indiaOnlineRow(),
            'trip_id_val': 9006,
            'net_amount': '92.40',
          }),
        ],
      );
      expect(find.text(kSupportEndedTitle), findsOneWidget);
      expect(find.text('Fare for the distance driven'), findsOneWidget);
      expect(
        find.text('You earned ₹92.40 for the distance driven.'),
        findsOneWidget,
      );
      expect(find.text(kSupportEndedPlatformPaid), findsNothing);
      expect(find.byKey(const Key('summary_fare')), findsOneWidget);
    });

    testWidgets(
      'D4 with nothing readable the driver is pointed to the earnings list',
      (t) async {
        final trip = TripModel.fromJson({
          ...tripDetailPlatformFunded(),
          'payment_status': 'completed',
        });
        await pumpSummary(
          t,
          session: TripSessionState(
            trip: trip,
            status: TripStatus.completed,
            endedBySupport: true,
          ),
        );
        expect(
          find.text(
            'Your earnings for this trip will show in your earnings list.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'D4 a trip released before pickup leaves the trip screen with its reason',
      (t) async {
        t.view.devicePixelRatio = 1.0;
        await t.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() {
          t.binding.setSurfaceSize(null);
          t.view.resetDevicePixelRatio();
        });
        const trip = TripModel(
          id: 9004,
          status: TripStatus.cancelled,
          driverId: 5,
        );
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const TripFlowScreen()),
          ],
        );
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              tripSessionNotifierProvider.overrideWith(
                () => _SeededSession(
                  const TripSessionState(
                    trip: trip,
                    status: TripStatus.cancelled,
                    releasedBySupport: true,
                    cancellationReason: 'Your ride was cancelled by support.',
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text(kSupportReleasedTitle), findsOneWidget);
        expect(
          find.textContaining('SaaradhiGo support cancelled this trip'),
          findsOneWidget,
        );
        // Not the rider-cancellation wording or sheet.
        expect(find.text('Ride cancelled'), findsNothing);
        expect(find.textContaining('by the passenger'), findsNothing);
        expect(find.text('BACK TO DASHBOARD'), findsOneWidget);
      },
    );
  });
}
