// Both apps use the same Appearance words: the loanwords Indian phone settings
// use (Telugu డార్క్ / లైట్ / ఆటోమేటిక్, Hindi डार्क / लाइट / ऑटोमैटिक), still
// marked "needs native review".
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  const expected = {
    'te': {
      'appearanceDark': 'డార్క్',
      'appearanceLight': 'లైట్',
      'appearanceAutomatic': 'ఆటోమేటిక్',
    },
    'hi': {
      'appearanceDark': 'डार्क',
      'appearanceLight': 'लाइट',
      'appearanceAutomatic': 'ऑटोमैटिक',
    },
  };

  for (final entry in expected.entries) {
    test('${entry.key} Appearance options are the shared loanwords', () {
      final arb = _arb(entry.key);
      for (final word in entry.value.entries) {
        expect(arb[word.key], word.value, reason: word.key);
        expect(
          (arb['@${word.key}'] as Map)['description'],
          'needs native review',
        );
      }
    });
  }
}
