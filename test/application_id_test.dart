/// The application ID has to agree with itself in four places.
///
/// WHY THIS IS WORTH A TEST
/// -----------------------
/// `applicationId` is the one value in an Android project that can never be
/// changed after the first Play upload. It was settled late -- the app shipped
/// for months as the Flutter-generated `com.saaradhigo.saaradhigo_driver` --
/// and changing it touched four files that have no compiler relationship with
/// each other:
///
///   * `applicationId` in build.gradle.kts, which is the Play identity;
///   * `namespace` in build.gradle.kts, which is the R/BuildConfig package;
///   * the `package` declaration in MainActivity.kt, which has to match the
///     namespace because the manifest names the activity as `.MainActivity`;
///   * the directory MainActivity.kt sits in, which Kotlin requires to match
///     its package.
///
/// Get the last two wrong and the build fails, loudly. Get `applicationId`
/// alone wrong and everything builds, installs and runs -- and the Play
/// listing is created under a name nobody intended, permanently. That is the
/// case worth a test.
///
/// It also pins the launcher label, which was `saaradhigo_driver` until the
/// identity was settled: the Flutter default, lowercase with an underscore,
/// shown under the icon on a driver's home screen.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// The decision. Changing this constant is changing the product's identity.
const expectedApplicationId = 'com.saaradhigo.driver';

void main() {
  final gradle = File('android/app/build.gradle.kts');
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  String gradleValue(String key) {
    final match = RegExp(
      '^\\s*$key\\s*=\\s*"([^"]+)"',
      multiLine: true,
    ).firstMatch(gradle.readAsStringSync());
    if (match == null) fail('build.gradle.kts has no `$key = "..."`');
    return match.group(1)!;
  }

  test('applicationId is the agreed one', () {
    expect(gradleValue('applicationId'), expectedApplicationId);
  });

  test('namespace matches the applicationId', () {
    // They are allowed to differ, and nothing would fail if they did. Keeping
    // them equal is what makes the Kotlin package below predictable.
    expect(gradleValue('namespace'), expectedApplicationId);
  });

  test(
    'MainActivity declares the matching package, in the matching directory',
    () {
      final expectedDir = Directory(
        'android/app/src/main/kotlin/${expectedApplicationId.replaceAll('.', '/')}',
      );
      final activity = File('${expectedDir.path}/MainActivity.kt');

      expect(
        activity.existsSync(),
        isTrue,
        reason:
            'MainActivity.kt is not at ${activity.path}. Kotlin requires '
            'the directory to match the package, and the manifest resolves '
            '".MainActivity" against the namespace.',
      );
      expect(
        activity.readAsStringSync(),
        contains('package $expectedApplicationId'),
        reason: 'MainActivity.kt declares a different package',
      );
    },
  );

  test('no stray copy of MainActivity is left behind', () {
    // The rename was a `git mv`; a copy left at the old path would still
    // compile and would be dead, confusing code.
    final strays = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('MainActivity.kt'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();

    expect(
      strays.length,
      1,
      reason: 'expected exactly one MainActivity.kt, found: $strays',
    );
  });

  test('the old generated id appears nowhere that matters', () {
    // Allowed in a comment explaining the change; not in a value.
    for (final file in [gradle, manifest]) {
      final code = file
          .readAsStringSync()
          .split('\n')
          .where((line) {
            final t = line.trim();
            return !t.startsWith('//') &&
                !t.startsWith('<!--') &&
                !t.startsWith('*');
          })
          .join('\n');

      expect(
        code,
        isNot(contains('com.saaradhigo.saaradhigo_driver')),
        reason: '${file.path} still uses the old application id',
      );
    }
  });

  test('the launcher label is the brand, not the project directory name', () {
    final doc = XmlDocument.parse(manifest.readAsStringSync());
    final application = doc.findAllElements('application').single;
    final label = application.getAttribute('android:label');

    expect(
      label,
      'SaaradhiGo Driver',
      reason: 'this string is what a driver reads under the app icon',
    );
    expect(
      label,
      isNot(contains('_')),
      reason: 'an underscore here is the Flutter default showing through',
    );
  });
}
