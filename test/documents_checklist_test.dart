import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/documents/checklist_docs.dart';
import 'package:saaradhigo_driver/features/requirements/requirements_api.dart';
import 'package:saaradhigo_driver/l10n/app_localizations_en.dart';
import 'package:saaradhigo_driver/ui/driver_documents_view.dart';
import 'package:saaradhigo_driver/ui/sg_format.dart';

/// Parity with the web: QA driver 59's real checklist (approved, 18 of 18)
/// must show the same status word and expiry text per item.
void main() {
  Map<String, dynamic> load() {
    final raw =
        jsonDecode(
              File(
                'test/fixtures/driver59_requirements.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    // The fixture is the endpoint body without the app-only sections the
    // forms read; the checklist is all the Documents screen needs.
    return raw;
  }

  test('driver 59 checklist: status words and expiry text per item', () {
    final raw = load();
    final checklist = raw['checklist'] as Map<String, dynamic>;
    final country = (checklist['market'] as Map)['country'] as String;
    final items = [
      for (final i in checklist['items'] as List)
        ChecklistItem.fromJson(i as Map<String, dynamic>),
    ];
    final l = AppLocalizationsEn();
    final got = <String, Map<String, String>>{};
    for (final i in items) {
      got[i.key] = {
        'status': docStateWord(l, docStateOfChecklist(i.status)),
        'expiry': sgMarketDateText(i.expires, country),
      };
    }

    expect(got, hasLength(19));
    expect(got['profile_photo'], {'status': 'Approved', 'expiry': ''});
    expect(got['legal_name'], {'status': 'Done', 'expiry': ''});
    expect(got['permanent_address'], {'status': 'Missing', 'expiry': ''});
    expect(got['driving_licence'], {
      'status': 'Approved',
      'expiry': '31/10/2028',
    });
    expect(got['insurance'], {'status': 'Approved', 'expiry': '30/06/2027'});
    expect(got['permit'], {'status': 'Approved', 'expiry': '31/03/2028'});
    expect(got['fitness'], {'status': 'Approved', 'expiry': '30/09/2027'});
    expect(got['puc'], {'status': 'Approved', 'expiry': '15/05/2027'});
    expect(got['payout_method'], {'status': 'Done', 'expiry': ''});

    // US market: month first.
    expect(sgMarketDateText('2028-10-31', 'US'), '10/31/2028');

    // The expected file the web test must reproduce.
    File('test/fixtures/driver59_expected.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
        for (final e in got.entries) e.key: {'status_label': e.value['status'], 'expiry_text': e.value['expiry']},
      })}\n',
    );
  });

  test('docsFromRequirements keeps the checklist counts and states', () {
    final r = _requirementsOf(load());
    final o = docsFromRequirements(r);
    expect(o.items, hasLength(19));
    expect(o.done, 18);
    expect(o.total, 18);
    expect(
      o.items.firstWhere((i) => i.key == 'driving_licence').expires,
      '2028-10-31',
    );
  });

  test('expiring and expired are their own states', () {
    expect(docStateOfChecklist('expiring').name, 'expiring');
    expect(docStateOfChecklist('expired').name, 'expired');
    final l = AppLocalizationsEn();
    expect(docStateWord(l, docStateOfChecklist('expiring')), 'Expiring');
    expect(docStateWord(l, docStateOfChecklist('expired')), 'Expired');
  });
}

Requirements _requirementsOf(Map<String, dynamic> raw) {
  // Requirements.fromJson also reads config and the form sections; give it
  // empty ones, the checklist is the fixture's own.
  return Requirements.fromJson({
    'config': {
      'country': 'IN',
      'languages': ['en'],
    },
    ...raw,
  });
}
