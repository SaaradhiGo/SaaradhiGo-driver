import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
