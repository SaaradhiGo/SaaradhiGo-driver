/// App catch-up phase 5 (data), driver: D7 name required at sign-up, and the
/// unbacked "Elite Partner" banner hidden.
///
/// The name travels in PATCH /auth/update/ as full_name (User.full_name); the
/// backend's own notion of "a real name" is has_real_name in
/// servers/driver/serializers.py (not blank, no "@", not just digits).
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saaradhigo_driver/core/theme/app_theme.dart';
import 'package:saaradhigo_driver/core/validation/full_name.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/elite_status_model.dart';
import 'package:saaradhigo_driver/domain/models/incentive_quest_model.dart';
import 'package:saaradhigo_driver/domain/models/promo_incentive_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/incentives/domain/repositories/incentives_repository.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/providers/incentives_providers.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/providers/promo_incentives_provider.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/screens/incentives_rewards_screen.dart';
import 'package:saaradhigo_driver/features/onboarding/presentation/models/kyc_checklist_item.dart';
import 'package:saaradhigo_driver/features/onboarding/presentation/screens/onboarding_personal_screen.dart';

import 'growth_phase_test.dart' show incentiveRow, incentivesEnvelope;

class _Repo implements IncentivesRepository {
  @override
  Future<List<IncentiveQuestModel>> getIncentives() async => [];

  @override
  Future<EliteStatusModel> getEliteStatus() async =>
      const EliteStatusModel(tier: 'Gold');
}

class _Promo implements PromoIncentivesService {
  _Promo(this.rows);
  final List<PromoIncentive> rows;

  @override
  Dio get dio => throw UnimplementedError();

  @override
  Future<List<PromoIncentive>> fetch() async => rows;
}

KycChecklistItem _identity(DriverProfileModel p) =>
    KycChecklistItem.fromProfile(p).firstWhere((i) => i.id == 'identity');

void main() {
  group('D7 name rule', () {
    test('blank, spaces only and one character are refused', () {
      expect(validateFullName(null), isNotNull);
      expect(validateFullName(''), 'Enter your full name');
      expect(validateFullName('    '), 'Enter your full name');
      expect(validateFullName(' A '), 'Name must be at least 2 characters');
    });

    test('digits, symbols and punctuation-only are refused', () {
      expect(validateFullName('Ravi 2'), isNotNull);
      expect(validateFullName('Ravi@Kumar'), isNotNull);
      expect(validateFullName('+919876543210'), isNotNull);
      expect(validateFullName('..'), isNotNull);
      expect(validateFullName('--'), isNotNull);
    });

    test('valid names, including Unicode and . \' - , pass', () {
      expect(validateFullName('Ravi Kumar'), isNull);
      expect(validateFullName('  Ravi Kumar  '), isNull);
      expect(validateFullName('రవి కుమార్'), isNull);
      expect(validateFullName('रवि कुमार'), isNull);
      expect(validateFullName('José Álvarez-Núñez'), isNull);
      expect(validateFullName("Sinead O'Connor"), isNull);
      expect(validateFullName('Dr. A. P. J.'), isNull);
      expect(validateFullName('Li'), isNull);
    });

    test('a name the backend would refuse is not usable', () {
      expect(hasUsableName(null), isFalse);
      expect(hasUsableName('  '), isFalse);
      expect(hasUsableName('9876543210'), isFalse);
      expect(hasUsableName('+91 98765-43210'), isFalse);
      expect(hasUsableName('a@b.com'), isFalse);
      expect(hasUsableName('Ravi Kumar'), isTrue);
    });
  });

  group('D7 existing drivers are not re-prompted', () {
    test('a named driver sees the identity step as before', () {
      final p = DriverProfileModel(
        id: 1,
        approved: false,
        user: const UserModel(
          id: 1,
          fullName: 'Ravi Kumar',
          isUpdated: true,
          avatar: 'https://cdn.example/a.jpg',
        ),
      );
      expect(_identity(p).status, KycItemStatus.verified);
      expect(_identity(p).rejectionReason, isNull);
    });

    test('an approved driver is never prompted, named or not', () {
      final p = DriverProfileModel(
        id: 1,
        approved: true,
        user: const UserModel(id: 1, isUpdated: true),
      );
      expect(_identity(p).status, KycItemStatus.verified);
    });

    test('a profile without a user object is not prompted', () {
      const p = DriverProfileModel(id: 1, approved: false);
      expect(_identity(p).rejectionReason, isNull);
    });

    test('a driver with no name is asked for it on the identity step', () {
      final p = DriverProfileModel(
        id: 1,
        approved: false,
        user: const UserModel(
          id: 1,
          fullName: '  ',
          isUpdated: true,
          avatar: 'https://cdn.example/a.jpg',
        ),
      );
      final item = _identity(p);
      expect(item.status, KycItemStatus.actionRequired);
      expect(item.isActionRequired, isTrue);
      expect(item.rejectionReason, 'Please add your full name.');
      expect(item.targetRoute, '/onboarding/personal');
    });
  });

  group('D7 personal details screen', () {
    Future<void> pump(WidgetTester t) async {
      t.view.physicalSize = const Size(412, 1400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const OnboardingPersonalScreen(),
          ),
        ),
      );
      await t.pump();
    }

    Future<void> submit(WidgetTester t, String name) async {
      final fields = find.byType(TextFormField);
      await t.enterText(fields.at(0), name);
      await t.enterText(fields.at(1), 'driver@example.test');
      await t.tap(find.text('Next'));
      await t.pump();
    }

    testWidgets('blank name shows an inline error', (t) async {
      await pump(t);
      await submit(t, '   ');
      expect(find.text('Enter your full name'), findsOneWidget);
    });

    testWidgets('one character shows an inline error', (t) async {
      await pump(t);
      await submit(t, 'R');
      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('digits show an inline error', (t) async {
      await pump(t);
      await submit(t, 'R4vi');
      expect(find.text("Use letters, spaces and . ' - only"), findsOneWidget);
    });

    testWidgets('a valid Unicode name passes the name check', (t) async {
      await pump(t);
      await submit(t, 'రవి కుమార్');
      expect(find.text('Enter your full name'), findsNothing);
      expect(find.text('Name must be at least 2 characters'), findsNothing);
      expect(find.text("Use letters, spaces and . ' - only"), findsNothing);
    });
  });

  group('Elite banner', () {
    Future<void> pump(
      WidgetTester t, {
      required List<Map<String, dynamic>> rows,
    }) async {
      t.view.physicalSize = const Size(412, 1400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      final router = GoRouter(
        initialLocation: '/incentives',
        routes: [
          GoRoute(
            path: '/incentives',
            builder: (_, _) => const IncentivesRewardsScreen(),
          ),
        ],
      );
      final overrides = <Override>[
        incentivesRepositoryProvider.overrideWithValue(_Repo()),
        promoIncentivesServiceProvider.overrideWithValue(
          _Promo(PromoIncentive.listFromData(incentivesEnvelope(rows)['data'])),
        ),
      ];
      await t.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await t.pump();
      await t.pump();
      await t.pump();
    }

    testWidgets('hidden when there are incentives', (t) async {
      await pump(t, rows: [incentiveRow()]);
      expect(find.text('Weekend 3'), findsWidgets);
      expect(find.text('SaaradhiGo Elite Partner'), findsNothing);
      expect(find.text('View Tier Progression & Privileges'), findsNothing);
    });

    testWidgets('hidden on the empty state too', (t) async {
      await pump(t, rows: const []);
      expect(find.text('SaaradhiGo Elite Partner'), findsNothing);
      expect(find.text('View Tier Progression & Privileges'), findsNothing);
    });
  });
}
