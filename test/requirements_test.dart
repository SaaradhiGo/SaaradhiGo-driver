import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/requirements/get_ready_screen.dart';
import 'package:saaradhigo_driver/features/requirements/requirement_forms.dart';
import 'package:saaradhigo_driver/features/requirements/requirements_api.dart';
import 'package:saaradhigo_driver/features/requirements/setup_steps.dart';
import 'package:saaradhigo_driver/ui/sg_widgets.dart';
import 'package:saaradhigo_driver/l10n/app_localizations.dart';

/// Driver requirements in the app (10 Nov): the same market config as the web decides the
/// fields; the checklist shows progress and what blocks going online; make and model come from
/// the catalogue, and "Other" is sent for review.

Json _market(String country) {
  final india = country == 'IN';
  final keys = india
      ? [
          'profile_photo',
          'legal_name',
          'address',
          'emergency_contact',
          'driving_licence',
          'aadhaar',
          'pan',
          'police_verification',
          'vehicle',
          'vehicle_photos',
          'rc',
          'payout_method',
        ]
      : [
          'profile_photo',
          'legal_name',
          'address',
          'emergency_contact',
          'driving_licence',
          'background_check',
          'vehicle',
          'vehicle_photos',
          'registration',
          'payout_method',
        ];
  String section(String k) =>
      k.startsWith('vehicle') || k == 'rc' || k == 'registration'
      ? 'vehicle'
      : [
          'driving_licence',
          'aadhaar',
          'pan',
          'police_verification',
          'background_check',
        ].contains(k)
      ? 'identity'
      : k == 'payout_method'
      ? 'payouts'
      : 'personal';
  const stepOf = {
    'profile_photo': 'personal',
    'legal_name': 'personal',
    'address': 'personal',
    'emergency_contact': 'contact',
    'driving_licence': 'identity',
    'aadhaar': 'identity',
    'pan': 'identity',
    'police_verification': 'identity',
    'background_check': 'identity',
    'vehicle': 'vehicle',
    'vehicle_photos': 'vehicle_docs',
    'rc': 'vehicle_docs',
    'registration': 'vehicle_docs',
    'payout_method': 'payouts',
  };
  Json file(String key, {String status = 'missing', bool vehicle = false}) => {
    'key': key,
    'label': key,
    'status': status,
    'reason': status == 'rejected' ? 'Copy is blurred' : null,
    'uploaded_at': null,
    'vehicle': vehicle,
  };
  List<Json> files(String k) => switch (k) {
    'profile_photo' => [file('profile_photo')],
    // Uploaded and not yet reviewed, though the status says missing.
    'driving_licence' => [
      {...file('license_front'), 'uploaded_at': '2026-11-10T09:00:00Z'},
      file('license_back'),
    ],
    'aadhaar' => [file('aadhaar', status: 'rejected')],
    'pan' => [file('pan')],
    'police_verification' => [file('police_verification')],
    'vehicle_photos' => [
      for (final side in ['front', 'back', 'left', 'right', 'interior'])
        file('vehicle_photo_$side', vehicle: true),
    ],
    'rc' || 'registration' => [file(k, vehicle: true)],
    _ => [],
  };
  final stepKeys = [
    'personal',
    'contact',
    'identity',
    'vehicle',
    'vehicle_docs',
    'payouts',
  ];
  return {
    'upload_kinds': {
      'license_front': 'license_doc',
      'license_back': 'license_doc_back',
      'aadhaar': 'aadhaar_doc',
      'pan': 'pan_doc',
    },
    'config': {
      'country': country,
      'languages': india ? ['en', 'te', 'hi'] : ['en', 'es'],
      'min_driver_age': india ? 18 : 21,
    },
    'checklist': {
      'items': [
        for (final k in keys)
          {
            'key': k,
            'section': section(k),
            'label': k,
            'help': '',
            'need': 'required',
            'blocks_online': true,
            'status': k == 'legal_name'
                ? 'done'
                : k == 'aadhaar'
                ? 'rejected'
                : 'missing',
            'reason': k == 'aadhaar' ? 'Copy is blurred' : null,
            'expires': null,
            'step': stepOf[k],
            'files': files(k),
          },
      ],
      'steps': [
        for (final (i, st) in stepKeys.indexed)
          {
            'key': st,
            'number': i + 1,
            'items': [
              for (final k in keys)
                if (stepOf[k] == st) k,
            ],
            'status': st == 'identity' && india ? 'action' : 'todo',
          },
      ],
      'steps_done': 0,
      'next_step': 'personal',
      'minutes_left': 9,
      'done': 1,
      'total': keys.length,
      'blocking': ['profile_photo', 'address'],
      'approved': false,
    },
    'personal': {
      'full_name': 'Srinu',
      'name_pending': null,
      'dob': null,
      'address': null,
      'emergency_contacts': [],
    },
    'identity': {
      'license_number': '',
      'license_state': '',
      'license_expiry': null,
      'aadhaar_masked': null,
      'pan_masked': null,
      'background_check_status': 'not_started',
    },
    'payout_method': india
        ? {'kind': null, 'bank': null}
        : {'kind': 'stripe', 'stripe_status': 'not_started'},
    'states': [
      india
          ? {'code': 'TG', 'name': 'Telangana'}
          : {'code': 'TX', 'name': 'Texas'},
    ],
    'relationships': [
      {'code': 'spouse', 'label': 'Spouse or partner'},
    ],
    'vehicle_types': ['sedan'],
    'vehicle_years': [2026, 2025, 2012],
  };
}

class _FakeApi extends RequirementsApi {
  _FakeApi() : super(Dio());
  final saved = <Json>[];
  @override
  Future<List<Json>> vehicles() async => [];
  @override
  Future<Json> catalogue(String type) async => {
    'colours': ['White'],
    'makes': [
      {
        'make': 'Maruti Suzuki',
        'models': [
          {'id': 11, 'model': 'Dzire'},
        ],
      },
    ],
  };
  @override
  Future<Json> saveVehicle(int? id, Json body) async {
    saved.add(body);
    return {'id': 5};
  }
}

Widget _app(Widget child, String country, {RequirementsApi? api}) =>
    ProviderScope(
      key: ValueKey(country),
      overrides: [
        requirementsProvider.overrideWith(
          (ref) async => Requirements.fromJson(_market(country)),
        ),
        if (api != null) requirementsApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('the setup lists six steps with their states and one primary', (
    t,
  ) async {
    await t.pumpWidget(_app(const GetReadyScreen(), 'IN'));
    await t.pumpAndSettle();
    expect(find.text('0 of 6 steps'), findsOneWidget);
    expect(
      find.byKey(const Key('setup_marker_identity_action')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('setup_marker_personal_todo')), findsOneWidget);
    expect(find.text('Licence, Aadhaar, PAN, police check'), findsOneWidget);
    expect(find.text("You're approved to drive"), findsNothing);
    expect(find.byType(SgPrimaryButton), findsOneWidget);
  });

  testWidgets('an uploaded, unreviewed file shows In review, never Missing', (
    t,
  ) async {
    await t.pumpWidget(_app(const SetupStepScreen(stepKey: 'identity'), 'IN'));
    await t.pumpAndSettle();
    expect(find.text('Step 3 of 6 · about 9 minutes left'), findsOneWidget);
    expect(
      find.byKey(const Key('setup_pill_license_front_in_review')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('setup_pill_license_front_missing')),
      findsNothing,
    );
    expect(find.text('Uploaded 10 Nov'), findsOneWidget);
    expect(
      find.byKey(const Key('setup_pill_aadhaar_rejected')),
      findsOneWidget,
    );
    expect(find.text('Copy is blurred'), findsOneWidget);
    expect(find.byType(SgPrimaryButton), findsOneWidget);
    expect(find.text('Save and continue'), findsOneWidget);
  });

  testWidgets('a US identity step has no Aadhaar or PAN', (t) async {
    await t.pumpWidget(_app(const SetupStepScreen(stepKey: 'identity'), 'US'));
    await t.pumpAndSettle();
    expect(find.text('Licence, background check'), findsOneWidget);
    expect(find.byKey(const Key('setup_file_aadhaar')), findsNothing);
    expect(find.byKey(const Key('req_aadhaar')), findsNothing);
    expect(find.byKey(const Key('req_pan')), findsNothing);
    expect(find.byKey(const Key('req_licence_state')), findsOneWidget);
    expect(find.text('mm/dd/yyyy'), findsOneWidget);
  });

  test('a file uploaded but marked missing reads as in review', () {
    final f = ReqFile.fromJson({
      'key': 'pan',
      'label': 'PAN card',
      'status': 'missing',
      'uploaded_at': '2026-11-10T09:00:00Z',
    });
    expect(f.status, 'in_review');
  });

  testWidgets('India asks for Aadhaar and PAN; the USA never does', (t) async {
    await t.pumpWidget(_app(const IdentityReqScreen(), 'IN'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('req_aadhaar')), findsOneWidget);
    expect(find.byKey(const Key('req_pan')), findsOneWidget);
    expect(find.byKey(const Key('req_licence_state')), findsNothing);

    await t.pumpWidget(_app(const IdentityReqScreen(), 'US'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('req_aadhaar')), findsNothing);
    expect(find.byKey(const Key('req_pan')), findsNothing);
    expect(find.byKey(const Key('req_licence_state')), findsOneWidget);
  });

  testWidgets(
    'India pays to a bank or UPI with IFSC; the USA goes through Stripe',
    (t) async {
      await t.pumpWidget(_app(const PayoutsReqScreen(), 'IN'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('req_ifsc')), findsOneWidget);
      expect(find.byKey(const Key('req_stripe')), findsNothing);
      await t.pumpWidget(_app(const PayoutsReqScreen(), 'US'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('req_ifsc')), findsNothing);
      expect(find.byKey(const Key('req_stripe')), findsOneWidget);
    },
  );

  testWidgets('make and model come from the catalogue; Other sends free text', (
    t,
  ) async {
    final api = _FakeApi();
    await t.pumpWidget(_app(const VehicleReqScreen(), 'IN', api: api));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('req_make')));
    await t.pumpAndSettle();
    expect(find.text('Maruti Suzuki').last, findsOneWidget);
    await t.tap(find.text('Other').last);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('req_other_make')), 'Hindustan');
    await t.enterText(find.byKey(const Key('req_other_model')), 'Ambassador');
    await t.enterText(find.byKey(const Key('req_plate')), 'ts10cd5678');
    await t.ensureVisible(find.byKey(const Key('req_save_vehicle')));
    await t.tap(find.byKey(const Key('req_save_vehicle')));
    await t.pumpAndSettle();
    expect(api.saved.single, containsPair('custom', true));
    expect(api.saved.single, containsPair('brand', 'Hindustan'));
    expect(api.saved.single, containsPair('vehicle_number', 'TS10CD5678'));
  });
}
