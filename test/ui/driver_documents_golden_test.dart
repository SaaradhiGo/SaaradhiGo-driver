// The documents screen golden at 390x844 logical. Regenerate with:
//   flutter test --update-goldens test/ui/driver_documents_golden_test.dart
//
// Mostly text, so Windows-made goldens differ from Linux CI by just over 1%
// in anti-aliasing alone; this file allows 2%.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/ui/driver_documents_view.dart';
import 'package:saaradhigo_driver/ui/driver_f_logic.dart';

import '../support/driver_ui_fixtures.dart';

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
        imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= 0.02) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}

void main() {
  setUpAll(() async {
    goldenFileComparator = _TolerantComparator(
        (goldenFileComparator as LocalFileComparator)
            .basedir
            .resolve('driver_documents_golden_test.dart'));
    await loadSgFonts();
  });

  testWidgets('documents', (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sgApp(DriverDocumentsView(
      overview: parseDocsOverview(sampleDocsBody)!,
      payoutMissing: true,
      onOpenCamera: (_) {},
      onAddPayout: () {},
      onCallSupport: () {},
    )));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/documents_t3.png'));
  });
}
