// Owner decision D4 (2026-11-02): hold 2 seconds to send, sent at once, with a
// haptic. A single tap on the driver SOS sent SOS #6 on QA during the audit.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/support/presentation/widgets/hold_to_send.dart';

void main() {
  late int sent;
  late List<String> haptics;

  Future<void> pump(WidgetTester tester) async {
    sent = 0;
    haptics = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
        return null;
      },
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: HoldToSend(
            key: const Key('h'),
            semanticLabel: 'SOS. Alert the safety team',
            circular: true,
            onConfirmed: () => sent++,
            child: const SizedBox(width: 56, height: 56, child: Icon(Icons.sos)),
          ),
        ),
      ),
    ));
  }

  Future<void> hold(WidgetTester tester, Duration d) async {
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('h'))));
    for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 100)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('a tap sends nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('h')));
    await tester.pump(const Duration(seconds: 3));
    expect(sent, 0);
  });

  testWidgets('letting go at 1.5 s sends nothing', (tester) async {
    await pump(tester);
    await hold(tester, const Duration(milliseconds: 1500));
    expect(sent, 0);
  });

  testWidgets('a full 2 s hold sends once, with a heavy haptic', (tester) async {
    await pump(tester);
    await hold(tester, const Duration(milliseconds: 2200));
    expect(sent, 1);
    expect(haptics, contains('HapticFeedbackType.heavyImpact'));
  });
}
