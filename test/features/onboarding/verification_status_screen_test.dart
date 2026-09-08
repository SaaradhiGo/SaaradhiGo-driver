import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_notifier.dart';
import 'package:saaradhigo_driver/features/auth/presentation/providers/auth_state.dart';
import 'package:saaradhigo_driver/features/onboarding/presentation/screens/verification_status_screen.dart';
import 'package:saaradhigo_driver/features/onboarding/presentation/widgets/verification_approved_sheet.dart';
import 'package:saaradhigo_driver/features/onboarding/presentation/widgets/verification_rejection_banner.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_notifier.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_providers.dart';

class FakeProfileNotifier extends ProfileNotifier {
  FakeProfileNotifier(this._initialState);
  final ProfileState _initialState;

  int fetchProfileCallCount = 0;

  @override
  ProfileState build() => _initialState;

  @override
  Future<void> fetchProfile() async {
    fetchProfileCallCount++;
  }
}

class FakeAuthNotifier extends AuthNotifier {
  bool loggedOut = false;

  @override
  AuthState build() => const AuthAuthenticated();

  @override
  Future<void> logout() async {
    loggedOut = true;
    state = const AuthUnauthenticated();
  }
}

void main() {
  const pendingProfile = DriverProfileModel(
    id: 1,
    user: UserModel(
      id: 1,
      fullName: 'Vikram Singh',
      avatar: 'https://example.com/avatar.jpg',
    ),
    approved: false,
    ratings: 5.0,
    totalTrips: 0,
    licenseDoc: 'https://example.com/dl.jpg',
    activeVehicleDetails: {
      'brand': 'Tata',
      'model': 'Tigor EV',
      'vehicle_number': 'TS09UB1234',
    },
  );

  final rejectedProfile = DriverProfileModel(
    id: 2,
    user: const UserModel(
      id: 2,
      fullName: 'Vikram Singh',
      avatar: 'https://example.com/avatar.jpg',
    ),
    approved: false,
    ratings: 5.0,
    totalTrips: 0,
    licenseDoc: 'https://example.com/dl.jpg',
    licenseExpiry: DateTime(2020, 1, 1), // Expired -> actionRequired
    activeVehicleDetails: const {
      'brand': 'Tata',
      'model': 'Tigor EV',
      'vehicle_number': 'TS09UB1234',
    },
  );

  const approvedProfile = DriverProfileModel(
    id: 3,
    user: UserModel(
      id: 3,
      fullName: 'Vikram Singh',
      avatar: 'https://example.com/avatar.jpg',
    ),
    approved: true,
    ratings: 5.0,
    totalTrips: 0,
  );

  Widget createWidgetUnderTest({
    required ProfileNotifier profileNotifier,
    required AuthNotifier authNotifier,
    GoRouter? router,
  }) {
    final defaultRouter = GoRouter(
      initialLocation: '/verification-status',
      routes: [
        GoRoute(
          path: '/verification-status',
          builder: (context, state) => const VerificationStatusScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) =>
              const Scaffold(body: Text('Support Hub Screen')),
        ),
        GoRoute(
          path: '/onboarding/licence',
          builder: (context, state) =>
              const Scaffold(body: Text('Licence Screen')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        driverProfileNotifierProvider.overrideWith(() => profileNotifier),
        authNotifierProvider.overrideWith(() => authNotifier),
      ],
      child: MaterialApp.router(routerConfig: router ?? defaultRouter),
    );
  }

  testWidgets('renders all 4 dynamic KYC items for pending profile', (
    tester,
  ) async {
    final fakeProfileNotifier = FakeProfileNotifier(
      const ProfileState.loaded(pendingProfile),
    );
    final fakeAuthNotifier = FakeAuthNotifier();

    await tester.pumpWidget(
      createWidgetUnderTest(
        profileNotifier: fakeProfileNotifier,
        authNotifier: fakeAuthNotifier,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification Status'), findsOneWidget);
    expect(find.text('Verification in Progress'), findsOneWidget);
    expect(find.text('Identity & Profile Photo'), findsOneWidget);
    expect(find.text('Driving Licence'), findsOneWidget);
    expect(find.text('Vehicle Registration & RC'), findsOneWidget);
    expect(find.text('Bank Account & Payout Details'), findsOneWidget);
    expect(find.byType(VerificationRejectionBanner), findsNothing);
  });

  testWidgets(
    'renders VerificationRejectionBanner and Fix CTA when document is flagged',
    (tester) async {
      final fakeProfileNotifier = FakeProfileNotifier(
        ProfileState.loaded(rejectedProfile),
      );
      final fakeAuthNotifier = FakeAuthNotifier();

      await tester.pumpWidget(
        createWidgetUnderTest(
          profileNotifier: fakeProfileNotifier,
          authNotifier: fakeAuthNotifier,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Action Needed on Verification'), findsOneWidget);
      expect(find.byType(VerificationRejectionBanner), findsOneWidget);
      expect(
        find.text('Licence has expired. Please re-upload a valid document.'),
        findsOneWidget,
      );
      final fixButton = find.text('Fix');
      expect(fixButton, findsOneWidget);

      // Tap Fix button to route to /onboarding/licence
      await tester.ensureVisible(fixButton);
      await tester.tap(fixButton);
      await tester.pumpAndSettle();

      expect(find.text('Licence Screen'), findsOneWidget);
    },
  );

  testWidgets('triggers Contact Support navigation', (tester) async {
    final fakeProfileNotifier = FakeProfileNotifier(
      const ProfileState.loaded(pendingProfile),
    );
    final fakeAuthNotifier = FakeAuthNotifier();

    await tester.pumpWidget(
      createWidgetUnderTest(
        profileNotifier: fakeProfileNotifier,
        authNotifier: fakeAuthNotifier,
      ),
    );
    await tester.pumpAndSettle();

    final supportButton = find.text('Contact Support');
    expect(supportButton, findsOneWidget);
    await tester.ensureVisible(supportButton);
    await tester.tap(supportButton);
    await tester.pumpAndSettle();

    expect(find.text('Support Hub Screen'), findsOneWidget);
  });

  testWidgets('popup menu Sign Out logs driver out', (tester) async {
    final fakeProfileNotifier = FakeProfileNotifier(
      const ProfileState.loaded(pendingProfile),
    );
    final fakeAuthNotifier = FakeAuthNotifier();

    await tester.pumpWidget(
      createWidgetUnderTest(
        profileNotifier: fakeProfileNotifier,
        authNotifier: fakeAuthNotifier,
      ),
    );
    await tester.pumpAndSettle();

    // Tap more vert menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Sign Out'), findsOneWidget);
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(fakeAuthNotifier.loggedOut, isTrue);
  });

  testWidgets('displays VerificationApprovedSheet when profile is approved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeProfileNotifier = FakeProfileNotifier(
      const ProfileState.loaded(approvedProfile),
    );
    final fakeAuthNotifier = FakeAuthNotifier();

    await tester.pumpWidget(
      createWidgetUnderTest(
        profileNotifier: fakeProfileNotifier,
        authNotifier: fakeAuthNotifier,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VerificationApprovedSheet), findsOneWidget);
    expect(find.text('Verification Approved!'), findsOneWidget);
    final enterButton = find.text('Enter Dashboard');
    expect(enterButton, findsOneWidget);

    await tester.ensureVisible(enterButton);
    await tester.tap(enterButton);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
