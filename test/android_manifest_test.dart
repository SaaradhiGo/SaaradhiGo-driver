// The manifest must parse. It did not, and nothing noticed.
//
// android/app/src/main/AndroidManifest.xml contained a comment spelling out an
// example `flutter build apk --dart-define=...` command. A double hyphen is
// illegal inside an XML comment, so the manifest was unparseable and EVERY APK
// build failed with:
//
//   ManifestMerger2$MergeFailureException: Error parsing AndroidManifest.xml
//
// 83 tests passed and `flutter analyze` reported no issues throughout, because
// neither reads this file. The driver app had never been buildable, which means
// no driver could ever have installed it.
//
// This test is deliberately crude -- it reads the file as text and checks the
// things that make a manifest unparseable or unshippable. A real build is the
// only complete check and now runs in CI; this one fails in under a second and
// says why.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  test('the Android manifest exists', () {
    expect(manifest.existsSync(), isTrue,
        reason: 'android/app/src/main/AndroidManifest.xml is missing');
  });

  test('the Android manifest is well-formed XML', () {
    // The actual regression. XmlDocument.parse throws on the malformed comment.
    expect(
      () => XmlDocument.parse(manifest.readAsStringSync()),
      returnsNormally,
      reason: 'the manifest does not parse, so no APK can be built',
    );
  });

  test('no comment contains a double hyphen', () {
    // The specific trap, checked directly so the failure message names it.
    // XML forbids `--` inside a comment, and it is easy to reintroduce by
    // pasting a command line into an explanation.
    final text = manifest.readAsStringSync();
    final comments = RegExp(r'<!--(.*?)-->', dotAll: true).allMatches(text);
    for (final c in comments) {
      final body = c.group(1)!;
      expect(
        body.contains('--'),
        isFalse,
        reason: 'a double hyphen inside an XML comment makes the whole manifest '
            'unparseable and every APK build fail. Offending comment starts: '
            '${body.trim().split('\n').first}',
      );
    }
  });

  test('the app declares the permissions a driver app needs', () {
    final doc = XmlDocument.parse(manifest.readAsStringSync());
    final declared = doc
        .findAllElements('uses-permission')
        .map((e) => e.getAttribute('android:name'))
        .whereType<String>()
        .toSet();

    // Location is the whole job. Without these a driver cannot be dispatched to
    // and no trip can be tracked.
    expect(declared, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(declared, contains('android.permission.INTERNET'));
  });

  test('a manifest placeholder is supplied by Gradle', () {
    // The manifest references ${MAPS_API_KEY}. An unsupplied placeholder is a
    // build failure, so the two files have to agree.
    final text = manifest.readAsStringSync();
    final placeholders = RegExp(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .where((n) => n != 'applicationName')  // supplied by the Flutter plugin
        .toSet();

    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    for (final name in placeholders) {
      expect(
        gradle.contains('manifestPlaceholders["$name"]'),
        isTrue,
        reason: 'the manifest uses \${$name} and build.gradle.kts does not '
            'define it; an unsupplied placeholder fails the build',
      );
    }
  });
}
