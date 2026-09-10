import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/domain/models/user_model.dart';
import 'package:saaradhigo_driver/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:saaradhigo_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saaradhigo_driver/shared/widgets/driver_avatar.dart';

void main() {
  group('DriverAvatar', () {
    testWidgets('renders fallback initials when URL is null or empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DriverAvatar(
              url: null,
              fallbackName: 'Vikram Singh',
              size: 48,
            ),
          ),
        ),
      );

      expect(find.text('V'), findsOneWidget);
    });

    testWidgets('renders verified badge when isVerified is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DriverAvatar(
              url: null,
              fallbackName: 'Ramesh',
              size: 48,
              isVerified: true,
            ),
          ),
        ),
      );

      expect(find.text('R'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });
  });

  group('DashboardHeader', () {
    testWidgets(
      'renders driver name, rating, and active vehicle details when loaded',
      (WidgetTester tester) async {
        const profile = DriverProfileModel(
          id: 1,
          user: UserModel(id: 2, fullName: 'Ramesh Kumar'),
          status: DriverStatus.online,
          approved: true,
          ratings: 4.9,
          activeVehicleDetails: {
            'brand': 'Maruti',
            'model': 'Swift Dzire',
            'vehicle_number': 'TS07AB1234',
          },
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DashboardHeader(
                  profileState: ProfileState.loaded(profile),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Ramesh Kumar'), findsOneWidget);
        expect(find.text('4.9'), findsOneWidget);
        expect(find.textContaining('Maruti Swift Dzire'), findsOneWidget);
        expect(find.textContaining('TS07AB1234'), findsOneWidget);
      },
    );
  });
}
