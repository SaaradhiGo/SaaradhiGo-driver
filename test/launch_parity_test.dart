/// Launch parity with the web: the operator in About, the policy links, dates
/// in the market's order, expiry on documents, and the payout fee on its own line.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/about/about_screen.dart';
import 'package:saaradhigo_driver/features/about/legal_entity.dart';
import 'package:saaradhigo_driver/ui/driver_documents_view.dart';
import 'package:saaradhigo_driver/ui/driver_f_logic.dart';
import 'package:saaradhigo_driver/ui/sg_format.dart';
import 'package:saaradhigo_driver/l10n/app_localizations.dart';

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  group('market dates', () {
    test('dd/mm/yyyy in India, mm/dd/yyyy in the USA', () {
      expect(sgMarketDateText('2027-03-09', 'IN'), '09/03/2027');
      expect(sgMarketDateText('2027-03-09', 'US'), '03/09/2027');
      expect(sgMarketDateText('2027-03-09T10:00:00Z', null), '09/03/2027');
    });

    test('not a date: unchanged; nothing: empty', () {
      expect(sgMarketDateText('soon', 'IN'), 'soon');
      expect(sgMarketDateText(null, 'IN'), '');
      expect(sgMarketDateText('  ', 'IN'), '');
    });
  });

  group('legal entity', () {
    test('falls back to the name for the market only', () {
      expect(
        LegalEntity.fallback('IN').legalName,
        'DeepTrics Software Solutions Pvt Ltd',
      );
      expect(LegalEntity.fallback('US').legalName, 'DeepTrics LLC');
      expect(LegalEntity.fallback('IN').cin, isEmpty);
    });

    test('parses what the server sent', () {
      final m = parseLegal({
        'IN': {
          'legal_name': 'DeepTrics Software Solutions Pvt Ltd',
          'cin': 'U1',
        },
        'US': {'legal_name': 'DeepTrics LLC'},
        'ZZ': 5,
      });
      expect(m['IN']!.cin, 'U1');
      expect(m.length, 2);
      expect(parseLegal(null), isEmpty);
    });
  });

  group('policy links', () {
    test('driver terms, and grievance for India only', () {
      expect(
        policyLinksFor('IN').map((l) => l.path),
        containsAll(['/driver-terms', '/grievance', '/privacy', '/safety']),
      );
      expect(policyLinksFor('US').any((l) => l.path == '/grievance'), isFalse);
      expect(policyLinksFor('IN').any((l) => l.path == '/terms'), isFalse);
      expect(
        kDriverPolicyLinks.first.uri(kQaSite).toString(),
        'https://www.qa.saaradhigo.com/about',
      );
    });
  });

  group('About', () {
    testWidgets('shows the operator and only what the server sent', (t) async {
      await t.pumpWidget(
        _host(
          AboutScreen(year: 2026, versionLoader: () async => '1.0 (1)'),
          overrides: [
            legalEntityProvider.overrideWith(
              (ref) async => const LegalEntity(
                legalName: 'DeepTrics Software Solutions Pvt Ltd',
                registeredAddress: '1 Test Road',
                supportEmail: 'help@example.test',
              ),
            ),
          ],
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text(
          '© 2026 SaaradhiGo. Operated by DeepTrics Software Solutions Pvt Ltd.',
        ),
        findsOneWidget,
      );
      expect(find.text('1 Test Road'), findsOneWidget);
      expect(find.text('help@example.test'), findsOneWidget);
      expect(find.textContaining('CIN'), findsNothing);
      expect(
        find.byKey(const Key('about_link_driver-terms'), skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('documents', () {
    testWidgets('an expiry shows in the market format under the name', (
      t,
    ) async {
      await t.pumpWidget(
        _host(
          Scaffold(
            body: DriverDocumentsView(
              overview: const DocsOverview(
                items: [
                  DocItem(
                    key: 'insurance',
                    label: 'Vehicle insurance',
                    present: true,
                    state: DocState.approved,
                  ),
                  DocItem(
                    key: 'rc',
                    label: 'RC',
                    present: true,
                    state: DocState.approved,
                  ),
                ],
              ),
              expiries: const {'insurance': '09/03/2027'},
            ),
          ),
        ),
      );
      expect(find.text('Expires 09/03/2027'), findsOneWidget);
      expect(find.byKey(const Key('docs_expires_rc')), findsNothing);
    });
  });
}
