/// The two KYC screens, as a driver meets them.
///
/// These cover the behaviour that is easy to get wrong in a form that submits
/// files: that a half-finished upload cannot be submitted, that a validation
/// failure explains itself, and that a server refusal is shown rather than
/// swallowed.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/kyc/domain/document_kind.dart';
import 'package:saaradhigo_driver/features/kyc/presentation/document_upload_screen.dart';
import 'package:saaradhigo_driver/features/kyc/presentation/kyc_controller.dart';
import 'package:saaradhigo_driver/features/kyc/presentation/vehicle_registration_screen.dart';

void main() {
  // These screens are long forms inside a ListView. On a default 800x600 test
  // surface the submit button is never built, so a tap on it finds nothing --
  // which looks exactly like a missing button. A tall surface renders the
  // whole form instead of every test having to scroll.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 4000);
    view.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Future<void> pump(WidgetTester tester, Widget screen,
      {KycState? state}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (state != null)
            kycControllerProvider.overrideWith(() => _FixedKyc(state)),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the vehicle types offered', () {
    test('are exactly the ones the platform prices', () {
      // Seeded by pricing/0002_seed_phase0_data.py. The server looks the value
      // up by name and 400s on anything else, and no endpoint lists them, so
      // these two have to agree.
      expect(
        kVehicleTypes.map((t) => t.value).toList(),
        ['auto', 'hatchback', 'sedan', 'suv'],
      );
    });
  });

  group('vehicle registration screen', () {
    testWidgets('refuses an empty registration number with a reason',
        (tester) async {
      await pump(tester, const VehicleRegistrationScreen());

      await tester.tap(find.byKey(const Key('vehicle_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Enter the number on your number plate'),
          findsOneWidget);
    });

    testWidgets('refuses an implausibly short number', (tester) async {
      await pump(tester, const VehicleRegistrationScreen());

      await tester.enterText(find.byKey(const Key('vehicle_number')), 'TS09');
      await tester.tap(find.byKey(const Key('vehicle_submit')));
      await tester.pumpAndSettle();

      expect(find.text('That looks too short'), findsOneWidget);
    });

    testWidgets('upper-cases the number as it is typed', (tester) async {
      await pump(tester, const VehicleRegistrationScreen());

      await tester.enterText(
          find.byKey(const Key('vehicle_number')), 'ts09ab1234');
      await tester.pumpAndSettle();

      // Asserted on the field's own value, not with find.text: the hint text
      // is also "TS09AB1234", so a text finder matches two widgets and the
      // failure reads as a duplicate-widget bug rather than a formatter one.
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('vehicle_number')),
      );
      expect(field.controller?.text, 'TS09AB1234');
    });

    testWidgets('asks for all five Indian vehicle documents', (tester) async {
      await pump(tester, const VehicleRegistrationScreen());

      for (final document in DriverDocument.vehicleDocuments) {
        expect(find.byKey(Key('doc_card_${document.kind}')), findsOneWidget,
            reason: '${document.label} is not offered');
      }
      // The driver's own licence belongs on the other screen.
      expect(find.byKey(const Key('doc_card_license_doc')), findsNothing);
    });

    testWidgets('cannot be submitted while a document is still uploading',
        (tester) async {
      // Submitting mid-upload would create the vehicle with only the documents
      // that happened to have finished.
      await pump(
        tester,
        const VehicleRegistrationScreen(),
        state: const KycState(slots: {
          DriverDocument.registrationCertificate:
              DocumentSlot(state: UploadState.uploading, progress: 0.4),
        }),
      );

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('vehicle_submit')),
      );
      expect(button.onPressed, isNull);
      expect(find.byKey(const Key('doc_progress_rc_doc')), findsOneWidget);
    });

    testWidgets('shows a server refusal instead of swallowing it',
        (tester) async {
      await pump(
        tester,
        const VehicleRegistrationScreen(),
        state: const KycState(
          submitError: 'A vehicle with this number already exists.',
        ),
      );

      expect(find.byKey(const Key('vehicle_submit_error')), findsOneWidget);
      expect(find.text('A vehicle with this number already exists.'),
          findsOneWidget);
    });

    testWidgets('a failed upload names the document that failed',
        (tester) async {
      // With five documents, "upload failed" without saying which is useless.
      await pump(
        tester,
        const VehicleRegistrationScreen(),
        state: const KycState(slots: {
          DriverDocument.insurance: DocumentSlot(
            state: UploadState.failed,
            error: 'Upload failed. Check your connection and try again.',
          ),
        }),
      );

      expect(find.byKey(const Key('doc_error_insurance_doc')), findsOneWidget);
      expect(find.byKey(const Key('doc_error_rc_doc')), findsNothing);
    });
  });

  group('driver document screen', () {
    testWidgets('cannot submit until both licence sides are uploaded',
        (tester) async {
      await pump(
        tester,
        const DocumentUploadScreen(),
        state: const KycState(slots: {
          DriverDocument.licenceFront:
              DocumentSlot(state: UploadState.uploaded, key: 'license_docs/a'),
        }),
      );

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('kyc_submit_documents')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('can submit once both sides are uploaded', (tester) async {
      await pump(
        tester,
        const DocumentUploadScreen(),
        state: const KycState(slots: {
          DriverDocument.licenceFront:
              DocumentSlot(state: UploadState.uploaded, key: 'license_docs/a'),
          DriverDocument.licenceBack: DocumentSlot(
              state: UploadState.uploaded, key: 'license_docs_back/b'),
        }),
      );

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('kyc_submit_documents')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('says uploaded, never verified', (tester) async {
      // A driver told "Verified" would try to go online and be refused with
      // no explanation. Approval is an operator's decision, not an upload's.
      await pump(
        tester,
        const DocumentUploadScreen(),
        state: const KycState(slots: {
          DriverDocument.licenceFront:
              DocumentSlot(state: UploadState.uploaded, key: 'license_docs/a'),
        }),
      );

      expect(find.text('Uploaded'), findsOneWidget);
      expect(find.text('Verified'), findsNothing);
      expect(find.text('Approved'), findsNothing);
    });
  });
}

/// A controller pinned to one state, so a screen can be rendered in a state
/// that would otherwise need a camera and a network.
class _FixedKyc extends KycController {
  _FixedKyc(this._state);

  final KycState _state;

  @override
  KycState build() => _state;
}
