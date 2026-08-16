import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SaaradhiGoDriverApp(initialRoute: '/login'));
    // Verify that the title text 'SaaradhiGo' exists in the splash screen
    expect(find.text('SaaradhiGo'), findsOneWidget);

    // Advance time to pass the 2-second splash timer
    await tester.pump(const Duration(seconds: 3));
  });
}
