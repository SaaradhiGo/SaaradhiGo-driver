// Goldens at 390x844 logical. Regenerate with:
//   flutter test --update-goldens test/ui/driver_ui_d_golden_test.dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/incoming_offer_card.dart';

import '../support/driver_ui_fixtures.dart';

/// Goldens are made on Windows and checked on Linux CI, where text rasterises a
/// little differently. Up to 1% of pixels passes; a layout change does not.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
        imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= 0.01) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}

void main() {
  setUpAll(() async {
    goldenFileComparator = _TolerantComparator(
        (goldenFileComparator as LocalFileComparator)
            .basedir
            .resolve('driver_ui_d_golden_test.dart'));
    await loadSgFonts();
  });

  testWidgets('home offline', (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sgApp(homeFrame()));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/home_offline.png'));
  });

  testWidgets('home online', (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sgApp(homeFrame(online: true)));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/home_online.png'));
  });

  testWidgets('incoming offer', (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sgApp(IncomingOfferCard(
      payload: sampleOfferWithEarning,
      alert: false,
      mapProvider: kPlaceholderMaps,
      onAccept: () {},
      onDecline: () {},
      onExpired: () {},
    )));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 900));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/incoming_offer.png'));
  });
}
