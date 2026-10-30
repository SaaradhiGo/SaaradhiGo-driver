import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // A benefit or fee shown to a driver must be backed by something the backend
  // charges or does. These five perks never were; they must not come back
  // without a backend value to read them from.
  test('no unwired perk or commission claim is in the app source', () {
    final claims = [
      'Reduced Platform Commission',
      'Instant Fee-Free',
      'Priority Airport',
      'VIP Support Line',
      'monthly cashback',
      'Priority 24/7 Support',
    ];
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      for (final c in claims) {
        if (text.contains(c)) offenders.add('${f.path}: $c');
      }
    }
    expect(offenders, isEmpty);
  });
}
