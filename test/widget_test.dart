import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SaaradhiGoDriverApp(initialRoute: '/login'));
    
    // Wait for any animations to finish
    await tester.pumpAndSettle();
    
    // Verify the app renders (basic smoke test)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
