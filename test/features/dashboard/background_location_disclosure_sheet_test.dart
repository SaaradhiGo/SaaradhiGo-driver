import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/dashboard/presentation/widgets/background_location_disclosure_sheet.dart';

void main() {
  group('BackgroundLocationDisclosureSheet', () {
    testWidgets(
      'renders without overflow on compact 360x600 viewport and handles dismiss',
      (tester) async {
        tester.view.physicalSize = const Size(360, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool dismissed = false;
        bool granted = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => BackgroundLocationDisclosureSheet.show(
                      context,
                      onDismiss: () => dismissed = true,
                      onGranted: () => granted = true,
                    ),
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open the bottom sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Verify elements are present
        expect(find.text('Background Location Access'), findsOneWidget);
        expect(
          find.textContaining(
            'SaaradhiGo Driver collects and streams your location data',
          ),
          findsOneWidget,
        );
        expect(find.text('Grant "Allow All The Time"'), findsOneWidget);
        expect(find.text('Continue in Limited Mode'), findsOneWidget);

        // Tap secondary CTA: Continue in Limited Mode
        await tester.ensureVisible(find.text('Continue in Limited Mode'));
        await tester.tap(find.text('Continue in Limited Mode'));
        await tester.pumpAndSettle();

        expect(dismissed, isTrue);
        expect(granted, isFalse);
      },
    );

    testWidgets(
      'scrolls properly and does not overflow on short 360x480 screen',
      (tester) async {
        tester.view.physicalSize = const Size(360, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: BackgroundLocationDisclosureSheet()),
            ),
          ),
        );

        expect(find.text('Background Location Access'), findsOneWidget);
        // Ensure buttons can be scrolled into view without overflow
        await tester.ensureVisible(find.text('Grant "Allow All The Time"'));
        expect(find.text('Grant "Allow All The Time"'), findsOneWidget);
      },
    );
  });
}
