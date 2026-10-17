/// The login screen offers both ways in, and neither leaks the other's state.
///
/// The driver app had one way to sign in: phone + OTP. That is fine until an
/// operator has to put a QA driver on a test phone without an SMS reaching a
/// real number, or a driver's SIM stops working mid-pilot. The mobile tab
/// here is the original screen unchanged; these tests exist to prove that,
/// and that the email tab is wired to the server contract rather than to a
/// hopeful guess.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/errors/failures.dart';
import 'package:saaradhigo_driver/core/storage/secure_storage_service.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/auth/domain/auth_repository.dart';
import 'package:saaradhigo_driver/features/auth/presentation/login_mobile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAuthRepository implements AuthRepository {
  final List<String> otpRequests = [];
  final List<List<String>> emailLogins = [];
  final List<String> resetRequests = [];

  /// Thrown by emailLogin when set, to stand in for the server's refusal.
  Failure? emailFailure;

  String resetMessage =
      'If that address belongs to an account, we have sent a link to it.';

  @override
  Future<void> requestOtp(String phoneNumber) async {
    otpRequests.add(phoneNumber);
  }

  @override
  Future<UserModel?> verifyOtp(String phoneNumber, String otp) async => null;

  @override
  Future<UserModel?> emailLogin({
    required String email,
    required String password,
  }) async {
    emailLogins.add([email, password]);
    final failure = emailFailure;
    if (failure != null) throw failure;
    return null;
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    resetRequests.add(email);
    return resetMessage;
  }

  @override
  Future<void> logout() async {}
}

void main() {
  late _RecordingAuthRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.resetSessionRevocationCacheForTests();
    repository = _RecordingAuthRepository();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginMobileScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> openEmailTab(WidgetTester tester) async {
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
  }

  testWidgets('both ways in are offered', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('the mobile tab is the original screen', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(repository.otpRequests, [
      '+919876543210',
    ], reason: 'the +91 prefix and the trim must be unchanged');
  });

  testWidgets('a short number is rejected before any request', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, '98765');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(find.text('Please enter a valid 10-digit number'), findsOneWidget);
    expect(repository.otpRequests, isEmpty);
  });

  testWidgets('the email tab signs in with what was typed', (tester) async {
    await pumpLogin(tester);
    await openEmailTab(tester);

    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      '  driver@example.test ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Cadence-Harbour-74',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(repository.emailLogins, [
      ['driver@example.test', 'Cadence-Harbour-74'],
    ], reason: 'the address is trimmed; the password is sent exactly as typed');
  });

  testWidgets('empty email fields are rejected before any request', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openEmailTab(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(repository.emailLogins, isEmpty);
  });

  testWidgets('the password is hidden until the driver asks', (tester) async {
    await pumpLogin(tester);
    await openEmailTab(tester);

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();

    expect(passwordField().obscureText, isFalse);
  });

  testWidgets("a refusal shows the server's words", (tester) async {
    // Not "Authentication failed": the driver needs to know it was the
    // password, and the server is the only thing entitled to say so.
    repository.emailFailure = const AuthFailure('Invalid email or password.');

    await pumpLogin(tester);
    await openEmailTab(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'driver@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Invalid email or password.'), findsOneWidget);

    // Let the notifier's 3-second revert run, so no timer outlives the test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('forgot password asks for an address first', (tester) async {
    await pumpLogin(tester);
    await openEmailTab(tester);

    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Enter your email address first, then tap Forgot password.'),
      findsOneWidget,
    );
    expect(repository.resetRequests, isEmpty);
  });

  testWidgets('forgot password repeats the server message verbatim', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openEmailTab(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'driver@example.test',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await tester.pump();

    expect(repository.resetRequests, ['driver@example.test']);
    expect(find.text(repository.resetMessage), findsOneWidget);
  });

  testWidgets(
    'no password is left anywhere in the widget tree after signing in',
    (tester) async {
      await pumpLogin(tester);
      await openEmailTab(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Cadence-Harbour-74',
      );
      await tester.pump();

      // The field itself holds it, of course. Nothing else may render it: no
      // debug label, no error message echoing the input, no Text widget.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((s) => s.contains('Cadence-Harbour-74'));

      expect(texts, isEmpty);
    },
  );
}
