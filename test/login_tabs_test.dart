/// The driver login screen's Mobile | Email tabs.
///
/// Mobile stays the default because it is what a driver partner has, it needs
/// no password, and it is the only route that can create an account. A change
/// that quietly made Email the landing tab would strand every driver who has
/// never set one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saaradhigo_driver/app/router.dart';
import 'package:saaradhigo_driver/core/providers.dart';
import 'package:saaradhigo_driver/features/auth/presentation/login_screen.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
  });

  Future<void> pump(WidgetTester tester) async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    // A real router: a successful sign-in calls context.go(Routes.home) and
    // `GoRouter.of` throws without one, which reads as a login failure
    // rather than as a missing test harness.
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: Routes.otp,
          builder: (_, _) => const Scaffold(body: Text('OTP')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Mobile is the default and the phone field is shown',
      (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('login_mode_tabs')), findsOneWidget);
    expect(find.byKey(const Key('login_phone_field')), findsOneWidget);
    expect(find.byKey(const Key('login_email_field')), findsNothing);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('choosing Email shows the email and password fields',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_forgot_password')), findsOneWidget);
    expect(find.byKey(const Key('login_phone_field')), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('an empty email form is refused with a reason', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    // Nothing was sent.
    expect(repository.lastEmailLoginEmail, isNull);
  });

  testWidgets('a malformed address is refused before any request',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('login_email_field')), 'not-an-address');
    await tester.enterText(
        find.byKey(const Key('login_password_field')), 'Cadence-Harbour-74');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('That does not look like an email address'),
        findsOneWidget);
    expect(repository.lastEmailLoginEmail, isNull);
  });

  testWidgets('a valid form signs in with the trimmed address',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_email_field')),
        '  driver@example.test  ');
    await tester.enterText(
        find.byKey(const Key('login_password_field')), 'Cadence-Harbour-74');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(repository.lastEmailLoginEmail, 'driver@example.test');
    expect(repository.lastEmailLoginPassword, 'Cadence-Harbour-74');
    // A driver is never asked for a second factor.
    expect(repository.lastEmailLoginMfaCode, isNull);
  });

  testWidgets('the password is obscured until the eye is tapped',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    TextField field() => tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('login_password_field')),
            matching: find.byType(TextField),
          ),
        );

    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('login_password_visibility')));
    await tester.pumpAndSettle();
    expect(field().obscureText, isFalse);
  });

  testWidgets('forgot password with no address asks for one', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login_forgot_password')));
    await tester.pump();

    expect(find.textContaining('Enter your email address first'),
        findsOneWidget);
    expect(repository.lastPasswordResetEmail, isNull);
  });

  testWidgets('forgot password says the same thing whatever the server found',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('login_email_field')), 'driver@example.test');
    await tester.tap(find.byKey(const Key('login_forgot_password')));
    await tester.pump();

    expect(repository.lastPasswordResetEmail, 'driver@example.test');
    expect(find.textContaining('If that address belongs to an account'),
        findsOneWidget);
  });

  testWidgets('switching back to Mobile restores the OTP flow',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mobile'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_phone_field')), findsOneWidget);
    expect(find.byKey(const Key('login_email_field')), findsNothing);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
