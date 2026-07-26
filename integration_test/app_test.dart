import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saaradhigo_driver/app/app.dart';
import 'package:saaradhigo_driver/core/providers.dart';
import 'package:saaradhigo_driver/core/storage/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/fakes.dart';

/// On-device integration tests.
///
/// Run against a connected device or emulator:
///   flutter test integration_test/app_test.dart
///
/// These boot the real app widget tree (router, theme, providers) with the
/// network and secure storage faked, so they exercise navigation and startup
/// wiring that a widget test cannot: the splash handshake, the redirect
/// rules, and the signed-out → signed-in transition.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> buildApp({bool signedIn = false}) async {
    SharedPreferences.setMockInitialValues({});
    final localStore = await LocalStore.create();

    return ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        tokenStoreProvider.overrideWithValue(
          FakeTokenStore(access: signedIn ? 'tok' : null),
        ),
        authRepositoryProvider
            .overrideWithValue(FakeAuthRepository(signedIn: signedIn)),
        profileRepositoryProvider
            .overrideWithValue(FakeProfileRepository(buildProfile())),
        earningsRepositoryProvider
            .overrideWithValue(FakeEarningsRepository()),
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
        wsConnectorProvider.overrideWithValue((uri) => FakeWsChannel()),
      ],
      child: const SaaradhiGoDriverApp(),
    );
  }

  testWidgets('a signed-out driver lands on the login screen', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Drive with SaaradhiGo'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('OTP flow reaches the home screen', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the code'), findsOneWidget);

    // Six digits auto-submits.
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Test Driver'), findsOneWidget);
    expect(find.textContaining('offline'), findsWidgets);
  });

  testWidgets('a signed-in driver goes straight to home', (tester) async {
    await tester.pumpWidget(await buildApp(signedIn: true));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text("Today's earnings"), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });

  testWidgets('home exposes the duty toggle and quick actions',
      (tester) async {
    await tester.pumpWidget(await buildApp(signedIn: true));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
    expect(find.text('Ride history'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
