import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/app/theme.dart';
import 'package:saaradhigo_driver/core/providers.dart';
import 'package:saaradhigo_driver/core/widgets/common.dart';
import 'package:saaradhigo_driver/core/network/api_exception.dart';
import 'package:saaradhigo_driver/features/dispatch/domain/ride_offer.dart';
import 'package:saaradhigo_driver/features/home/presentation/widgets/duty_toggle.dart';
import 'package:saaradhigo_driver/features/profile/domain/driver_profile.dart';
import 'package:saaradhigo_driver/features/profile/presentation/profile_screen.dart';
import 'package:saaradhigo_driver/features/trip/domain/trip.dart';
import 'package:saaradhigo_driver/features/trip/presentation/widgets/cancel_sheet.dart';

import 'helpers/fakes.dart';

/// Wraps a widget in the minimum app scaffolding: a ProviderScope with the
/// overrides a test supplies, plus a MaterialApp for theme and directionality.
///
/// `overrides` is typed loosely and cast at the call site: Riverpod 3 keeps
/// the `Override` type in `package:riverpod`, which this package does not
/// depend on directly, and adding it just to name a parameter type would put
/// two copies of the Riverpod API on the import graph.
Widget harness(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  group('DutyToggle', () {
    testWidgets('shows offline copy and flips on tap', (tester) async {
      var toggledValue = false;
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: DutyToggle(
              isOnline: false,
              onChanged: (value) => toggledValue = value,
            ),
          ),
        ),
      );

      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Go online to start receiving rides'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggledValue, isTrue);
    });

    testWidgets('shows online copy when on duty', (tester) async {
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: DutyToggle(isOnline: true, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.text("You're online"), findsOneWidget);
      expect(find.text('Waiting for ride requests'), findsOneWidget);
    });

    testWidgets('reconnecting is its own state, not "online"', (tester) async {
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: DutyToggle(
              isOnline: true,
              isReconnecting: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // A driver whose socket dropped must not be told they are online.
      expect(find.text('Reconnecting…'), findsOneWidget);
      expect(find.text("You're online"), findsNothing);
    });

    testWidgets('is not tappable while the driver is blocked', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: DutyToggle(
              isOnline: false,
              enabled: false,
              onChanged: (_) => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
      expect(
        find.text('Complete the steps below to start driving'),
        findsOneWidget,
      );
    });
  });

  group('Shared widgets', () {
    testWidgets('ErrorView distinguishes offline from a server error',
        (tester) async {
      await tester.pumpWidget(
        harness(
          const Scaffold(
            body: ErrorView(
              error: ApiException(
                message: 'No connection. Check your mobile data and try again.',
                isNetwork: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.textContaining('No connection'), findsOneWidget);
    });

    testWidgets('ErrorView retry button fires', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: ErrorView(
              error: const ApiException(message: 'Boom'),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('StatTile renders label and value', (tester) async {
      await tester.pumpWidget(
        harness(
          const Scaffold(
            body: StatTile(label: "Today's earnings", value: '₹1,240.00'),
          ),
        ),
      );

      expect(find.text("Today's earnings"), findsOneWidget);
      expect(find.text('₹1,240.00'), findsOneWidget);
    });
  });

  group('ProfileScreen', () {
    testWidgets('shows KYC state and vehicle credentials', (tester) async {
      await tester.pumpWidget(
        harness(
          const ProfileScreen(),
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(buildProfile()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('TS09AB1234'), findsOneWidget);
      expect(find.text('Maruti Dzire'), findsOneWidget);
    });

    testWidgets('warns when the driver has no active vehicle', (tester) async {
      await tester.pumpWidget(
        harness(
          const ProfileScreen(),
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(
                buildProfile(approved: false, withVehicle: false),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Documents needed'), findsOneWidget);
      expect(find.textContaining('No active vehicle'), findsOneWidget);
    });

    testWidgets('surfaces a load failure with a retry', (tester) async {
      await tester.pumpWidget(
        harness(
          const ProfileScreen(),
          overrides: [
            profileRepositoryProvider
                .overrideWithValue(_FailingProfileRepository()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('Cancel sheet', () {
    testWidgets('requires a reason before it will submit', (tester) async {
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCancelSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The destructive action starts disabled — the server rejects an
      // unknown reason, so the UI must not let one through.
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Cancel trip'),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.text('Rider did not show up'));
      await tester.pumpAndSettle();

      final enabled = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Cancel trip'),
      );
      expect(enabled.onPressed, isNotNull);
    });
  });

  group('Ride offer', () {
    test('an expired offer is not presentable', () {
      final offer = RideOffer(
        tripId: 1,
        receivedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(offer.isExpired, isTrue);
    });
  });

  group('Trip status labels', () {
    test('each active state tells the driver what to do next', () {
      expect(TripStatus.accepted.driverLabel, 'Head to pickup');
      expect(TripStatus.reached.driverLabel, 'Waiting for rider');
      expect(TripStatus.inProgress.driverLabel, 'Trip in progress');
    });
  });
}

class _FailingProfileRepository extends FakeProfileRepository {
  _FailingProfileRepository() : super(buildProfile());

  @override
  Future<DriverProfile> fetchProfile() async =>
      throw const ApiException(message: 'Server unavailable');
}
