// Telugu runs about 30% longer: the Tier 3 screens must lay out at 390px
// without an overflow in te (and hi).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/l10n/app_localizations.dart';
import 'package:saaradhigo_driver/ui/driver_documents_view.dart';
import 'package:saaradhigo_driver/ui/driver_f_logic.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';
import 'package:saaradhigo_driver/ui/incoming_offer_card.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';

import '../support/driver_ui_fixtures.dart';

Widget _localized(String code, Widget child) => MaterialApp(
      locale: Locale(code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: sgDarkTheme(),
      home: Scaffold(backgroundColor: SgColors.bg000, body: child),
    );

void main() {
  setUpAll(loadSgFonts);

  for (final code in ['te', 'hi']) {
    group(code, () {
      setUp(() => SgText.useLanguage(code));
      tearDown(() => SgText.useLanguage('en'));

      Future<void> pump(WidgetTester t, Widget w) async {
        setPhoneSurface(t);
        addTearDown(t.view.reset);
        await t.pumpWidget(_localized(code, w));
        await t.pump();
        expect(t.takeException(), isNull);
      }

      testWidgets('home', (t) => pump(t, homeFrame(online: true, commission: '₹173')));
      testWidgets('offer', (t) => pump(
          t,
          IncomingOfferCard(
            payload: sampleOfferWithEarning,
            alert: false,
            mapProvider: kPlaceholderMaps,
            onAccept: () {},
            onDecline: () {},
            onExpired: () {},
          )));
      testWidgets('PIN', (t) async {
        final c = TextEditingController(text: '12');
        addTearDown(c.dispose);
        await pump(
            t,
            PinCheckView(
              controller: c,
              riderName: 'Raja Kumar',
              riderRating: 4.8,
              error: 'x',
              onMessage: () {},
              topActions: sosStandIn(),
              onStart: () {},
              onCancel: () {},
            ));
      });
      testWidgets('on trip', (t) => pump(t, inTripFrame(night: true)));
      testWidgets('documents', (t) => pump(
          t,
          DriverDocumentsView(
            overview: parseDocsOverview(sampleDocsBody)!,
            payoutMissing: true,
            onOpenCamera: (_) {},
            onAddPayout: () {},
            onCallSupport: () {},
          )));
    });
  }
}
