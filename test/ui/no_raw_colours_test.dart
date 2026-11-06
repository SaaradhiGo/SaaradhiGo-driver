// Tier 1 rule: no colour literal outside the token file, no Material palette
// colours (Colors.transparent is fine), no runtime font fetching, and none of
// the retired families or the old emblem.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const tokenFile = 'lib/ui/sg_tokens.dart';

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('app_localizations'))
      .toList();

  String rel(File f) => f.path.replaceAll(r'\', '/');

  List<String> scan(RegExp pattern, {bool skipTokenFile = true}) {
    final hits = <String>[];
    for (final f in files) {
      final path = rel(f);
      if (skipTokenFile && path.endsWith(tokenFile)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (pattern.hasMatch(line)) hits.add('$path:${i + 1}: ${line.trim()}');
      }
    }
    return hits;
  }

  test('lib/ is scanned', () {
    expect(files.length, greaterThan(50));
  });

  test('no Color(0x...) literal outside $tokenFile', () {
    expect(scan(RegExp(r'Color\(\s*0x')), isEmpty);
  });

  test(
    'no Colors.<colour> outside $tokenFile (Colors.transparent is fine)',
    () {
      final hits = scan(
        RegExp(r'(?<![A-Za-z0-9_])Colors\.(?!transparent\b)[a-z]'),
      );
      expect(hits, isEmpty);
    },
  );

  test('no google_fonts, retired families or old emblem', () {
    expect(
      scan(RegExp(r'google_fonts|GoogleFonts'), skipTokenFile: false),
      isEmpty,
    );
    expect(
      scan(
        RegExp(r'Manrope|Cormorant|JetBrains|Plus Jakarta|\bInter\b'),
        skipTokenFile: false,
      ),
      isEmpty,
    );
    expect(scan(RegExp(r'saaradhigo-emblem'), skipTokenFile: false), isEmpty);
  });

  test('the legacy gold and slate greys are gone from lib/', () {
    final legacy = RegExp(
      r'EEBD2B|F1F5F9|94A3B8|8090A6|64748B|475569|E2E8F0|F8FAFC',
      caseSensitive: false,
    );
    expect(scan(legacy, skipTokenFile: false), isEmpty);
  });
}
