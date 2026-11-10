import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';
import '../../ui/sg_widgets.dart';
import 'get_ready_screen.dart';
import 'requirements_api.dart';

/// The four sections a driver fills in (10 Nov), the same fields as the web, from the market's
/// requirements: personal (photo, name, date of birth, address, emergency contacts), identity,
/// vehicle (catalogue dropdowns and photos) and payouts.

class _Frame extends ConsumerWidget {
  const _Frame({required this.title, required this.builder});
  final String title;
  final Widget Function(BuildContext, WidgetRef, Requirements) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final req = ref.watch(requirementsProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: req.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: SgColors.gold500)),
          error: (_, _) =>
              Center(child: Text(l.reqLoadFailed, style: SgText.title)),
          data: (r) => builder(context, ref, r),
        ),
      ),
    );
  }
}

Widget _field(
  TextEditingController c,
  String label, {
  Key? key,
  TextInputType? type,
  int? max,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: SgSpace.s1),
  child: TextFormField(
    key: key,
    controller: c,
    keyboardType: type,
    maxLength: max,
    decoration: InputDecoration(labelText: label, counterText: ''),
  ),
);

Widget _dropdown(
  String label,
  String? value,
  List<(String, String)> options,
  ValueChanged<String?> onChanged, {
  Key? key,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: SgSpace.s1),
  child: DropdownButtonFormField<String>(
    key: key,
    initialValue: options.any((o) => o.$1 == value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final (v, t) in options) DropdownMenuItem(value: v, child: Text(t)),
    ],
    onChanged: onChanged,
  ),
);

/// Save, then a line saying what happened.
mixin _Saver<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? note;
  Future<void> save(Future<void> Function() fn) async {
    final l = AppLocalizations.of(context);
    setState(() {
      busy = true;
      note = null;
    });
    try {
      await fn();
      ref.invalidate(requirementsProvider);
      setState(() => note = l.reqSaved);
    } catch (e) {
      setState(() => note = serverMessage(e) ?? l.reqSaveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Personal
// ---------------------------------------------------------------------------

class PersonalReqScreen extends ConsumerStatefulWidget {
  const PersonalReqScreen({super.key});
  @override
  ConsumerState<PersonalReqScreen> createState() => _PersonalState();
}

class _PersonalState extends ConsumerState<PersonalReqScreen> with _Saver {
  final _name = TextEditingController(),
      _l1 = TextEditingController(),
      _l2 = TextEditingController();
  final _city = TextEditingController(), _pin = TextEditingController();
  final _cName = [TextEditingController(), TextEditingController()];
  final _cPhone = [TextEditingController(), TextEditingController()];
  final _cRel = <String?>[null, null];
  String? _state, _dob;
  bool _same = true, _filled = false;

  void _fill(Requirements r) {
    if (_filled) return;
    _filled = true;
    final p = r.personal;
    _name.text = (p['name_pending'] ?? p['full_name'] ?? '') as String;
    _dob = p['dob'] as String?;
    final a = p['address'] as Json?;
    if (a != null) {
      _l1.text = a['line1'] as String;
      _l2.text = (a['line2'] ?? '') as String;
      _city.text = a['city'] as String;
      _pin.text = a['postal_code'] as String;
      _state = a['state_code'] as String;
    }
    final contacts = List<Json>.from(p['emergency_contacts'] as List);
    for (var i = 0; i < contacts.length && i < 2; i++) {
      _cName[i].text = contacts[i]['name'] as String;
      _cPhone[i].text = contacts[i]['phone_number'] as String;
      _cRel[i] = contacts[i]['relationship'] as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqPersonalTitle,
      builder: (context, ref, r) {
        _fill(r);
        final api = ref.read(requirementsApiProvider);
        return ListView(
          padding: const EdgeInsets.all(SgSpace.s4),
          children: [
            if (r.asks('profile_photo')) ...[
              Row(
                children: [
                  Expanded(child: Text(l.reqPhoto, style: SgText.title)),
                  StatusChip(item: r.item('profile_photo')!),
                ],
              ),
              FileSlot(
                label: l.reqPhoto,
                target: 'personal',
                field: 'photo',
                camera: true,
                guide: l.reqPhotoGuide,
                onDone: () => ref.invalidate(requirementsProvider),
              ),
            ],
            _field(_name, l.reqFullName, key: const Key('req_name')),
            if (r.personal['name_pending'] != null)
              Text(l.reqNameInReview, style: SgText.small),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.reqDob),
              subtitle: Text(
                _dob ?? (r.minAge != null ? l.reqMinAge('${r.minAge}') : ''),
              ),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(now.year - 25),
                  firstDate: DateTime(now.year - 80),
                  lastDate: now,
                );
                if (picked != null) {
                  setState(
                    () => _dob = picked.toIso8601String().substring(0, 10),
                  );
                }
              },
            ),
            const SizedBox(height: SgSpace.s3),
            Text(l.reqAddress, style: SgText.title),
            _field(_l1, l.reqLine1, key: const Key('req_line1')),
            _field(_l2, l.reqLine2),
            _field(_city, l.reqCity, key: const Key('req_city')),
            _dropdown(
              l.reqState,
              _state,
              [
                for (final s in r.states)
                  (s['code'] as String, s['name'] as String),
              ],
              (v) => setState(() => _state = v),
              key: const Key('req_state'),
            ),
            _field(
              _pin,
              r.country == 'US' ? l.reqZip : l.reqPin,
              key: const Key('req_pin'),
              type: TextInputType.number,
              max: r.country == 'US' ? 5 : 6,
            ),
            if (r.asks('permanent_address'))
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _same,
                title: Text(l.reqPermanentSame),
                onChanged: (v) => setState(() => _same = v ?? true),
              ),
            if (r.asks('emergency_contact')) ...[
              const SizedBox(height: SgSpace.s3),
              Text(l.reqContactsTitle, style: SgText.title),
              Text(l.reqContactsHint, style: SgText.small),
              for (var i = 0; i < 2; i++) ...[
                const SizedBox(height: SgSpace.s2),
                Text(l.reqContact('${i + 1}'), style: SgText.body),
                _field(_cName[i], l.reqName, key: Key('req_contact_name_$i')),
                _dropdown(
                  l.reqRelationship,
                  _cRel[i],
                  [
                    for (final x in r.relationships)
                      (x['code'] as String, x['label'] as String),
                  ],
                  (v) => setState(() => _cRel[i] = v),
                  key: Key('req_contact_rel_$i'),
                ),
                _field(
                  _cPhone[i],
                  l.reqMobile,
                  key: Key('req_contact_phone_$i'),
                  type: TextInputType.phone,
                ),
              ],
            ],
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(top: SgSpace.s2),
                child: Text(note!, key: const Key('req_note')),
              ),
            const SizedBox(height: SgSpace.s3),
            SgPrimaryButton(
              key: const Key('req_save_personal'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy
                  ? null
                  : () => save(() async {
                      final contacts = [
                        for (var i = 0; i < 2; i++)
                          if (_cName[i].text.trim().isNotEmpty)
                            {
                              'name': _cName[i].text.trim(),
                              'relationship': _cRel[i],
                              'phone_number': _cPhone[i].text.trim(),
                            },
                      ];
                      await api.savePersonal({
                        'full_name': _name.text.trim(),
                        'dob': ?_dob,
                        'address': {
                          'line1': _l1.text.trim(),
                          'line2': _l2.text.trim(),
                          'city': _city.text.trim(),
                          'state_code': _state,
                          'postal_code': _pin.text.trim(),
                        },
                        if (r.asks('permanent_address') && _same)
                          'permanent_same': true,
                        if (r.asks('emergency_contact'))
                          'emergency_contacts': contacts,
                      });
                    }),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

class IdentityReqScreen extends ConsumerStatefulWidget {
  const IdentityReqScreen({super.key});
  @override
  ConsumerState<IdentityReqScreen> createState() => _IdentityState();
}

class _IdentityState extends ConsumerState<IdentityReqScreen> with _Saver {
  final _number = TextEditingController(),
      _aadhaar = TextEditingController(),
      _pan = TextEditingController();
  String? _state, _expiry;
  bool _filled = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqIdentityTitle,
      builder: (context, ref, r) {
        final id = r.identity;
        if (!_filled) {
          _filled = true;
          _number.text = id['license_number'] as String;
          _state = (id['license_state'] as String).isEmpty
              ? null
              : id['license_state'] as String;
          _expiry = id['license_expiry'] as String?;
        }
        void reload() => ref.invalidate(requirementsProvider);
        final api = ref.read(requirementsApiProvider);
        return ListView(
          padding: const EdgeInsets.all(SgSpace.s4),
          children: [
            _field(
              _number,
              l.reqLicenceNumber,
              key: const Key('req_licence_number'),
            ),
            if (r.country == 'US')
              _dropdown(
                l.reqLicenceState,
                _state,
                [
                  for (final s in r.states)
                    (s['code'] as String, s['name'] as String),
                ],
                (v) => setState(() => _state = v),
                key: const Key('req_licence_state'),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.reqLicenceExpiry),
              subtitle: Text(_expiry ?? ''),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: now,
                  lastDate: DateTime(now.year + 25),
                );
                if (picked != null) {
                  setState(
                    () => _expiry = picked.toIso8601String().substring(0, 10),
                  );
                }
              },
            ),
            if (r.asks('aadhaar')) ...[
              _field(
                _aadhaar,
                l.reqAadhaarLast4,
                key: const Key('req_aadhaar'),
                type: TextInputType.number,
                max: 4,
              ),
              Text(
                id['aadhaar_masked'] != null
                    ? l.reqOnFile(id['aadhaar_masked'] as String)
                    : l.reqAadhaarNever,
                style: SgText.small,
              ),
            ],
            if (r.asks('pan')) ...[
              _field(_pan, l.reqPan, key: const Key('req_pan'), max: 10),
              if (id['pan_masked'] != null)
                Text(
                  l.reqOnFile(id['pan_masked'] as String),
                  style: SgText.small,
                ),
            ],
            if (note != null) Text(note!, key: const Key('req_note')),
            SgPrimaryButton(
              key: const Key('req_save_identity'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy
                  ? null
                  : () => save(() async {
                      await api.saveIdentity({
                        'license_number': _number.text.trim(),
                        'license_expiry': ?_expiry,
                        if (r.country == 'US') 'license_state': ?_state,
                        if (_aadhaar.text.trim().isNotEmpty)
                          'aadhaar_last4': _aadhaar.text.trim(),
                        if (_pan.text.trim().isNotEmpty)
                          'pan_number': _pan.text.trim().toUpperCase(),
                      });
                    }),
            ),
            const SizedBox(height: SgSpace.s4),
            FileSlot(
              label: l.reqLicenceFront,
              target: 'identity',
              field: 'license_doc',
              camera: true,
              onDone: reload,
            ),
            FileSlot(
              label: l.reqLicenceBack,
              target: 'identity',
              field: 'license_doc_back',
              camera: true,
              onDone: reload,
            ),
            for (final (key, field, label) in [
              ('aadhaar', 'aadhaar_doc', l.reqAadhaarCopy),
              ('pan', 'pan_doc', l.reqPanCard),
              ('police_verification', 'police_verification_doc', l.reqPolice),
              ('address_proof', 'address_proof_doc', l.reqAddressProof),
            ])
              if (r.asks(key)) ...[
                Row(
                  children: [
                    Expanded(child: Text(label, style: SgText.small)),
                    StatusChip(item: r.item(key)!),
                  ],
                ),
                if (r.item(key)!.reason != null)
                  Text(
                    r.item(key)!.reason!,
                    style: SgText.small.copyWith(color: SgColors.danger),
                  ),
                FileSlot(
                  label: label,
                  target: 'identity',
                  field: field,
                  camera: true,
                  present: r.item(key)!.status != 'missing',
                  onDone: reload,
                ),
              ],
            if (r.asks('background_check'))
              Text(
                l.reqBackground(id['background_check_status'] as String),
                style: SgText.body,
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle
// ---------------------------------------------------------------------------

class VehicleReqScreen extends ConsumerStatefulWidget {
  const VehicleReqScreen({super.key});
  @override
  ConsumerState<VehicleReqScreen> createState() => _VehicleState();
}

class _VehicleState extends ConsumerState<VehicleReqScreen> with _Saver {
  static const other = 'other';
  final _plate = TextEditingController(),
      _otherMake = TextEditingController(),
      _otherModel = TextEditingController();
  String? _type, _make, _model, _colour;
  int? _year, _vehicleId;
  Json? _catalogue;
  bool _loaded = false;

  Future<void> _load(Requirements r) async {
    if (_loaded) return;
    _loaded = true;
    final api = ref.read(requirementsApiProvider);
    final cars = await api.vehicles();
    if (cars.isNotEmpty) {
      final c = cars.first;
      _vehicleId = c['id'] as int;
      _plate.text = (c['vehicle_number'] ?? '') as String;
      _year = c['year'] as int?;
      _colour = c['color'] as String?;
      _type =
          (c['vehicle_type'] is Map ? (c['vehicle_type'] as Map)['type'] : null)
              as String?;
      if (c['custom_make_model'] == true) {
        _make = other;
        _otherMake.text = (c['brand'] ?? '') as String;
        _otherModel.text = (c['model'] ?? '') as String;
      } else {
        _make = c['brand'] as String?;
        _model = c['catalogue_entry']?.toString();
      }
    }
    _type ??= r.vehicleTypes.first;
    await _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    final got = await ref.read(requirementsApiProvider).catalogue(_type!);
    if (mounted) setState(() => _catalogue = got);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqVehicleTitle,
      builder: (context, ref, r) {
        _load(r);
        final makes = [
          for (final m in (_catalogue?['makes'] as List? ?? [])) m as Json,
        ];
        final models = [
          for (final m in makes.where((m) => m['make'] == _make))
            for (final x in m['models'] as List) x as Json,
        ];
        final colours = List<String>.from(
          _catalogue?['colours'] as List? ?? const [],
        );
        final api = ref.read(requirementsApiProvider);
        return ListView(
          padding: const EdgeInsets.all(SgSpace.s4),
          children: [
            _dropdown(
              l.reqVehicleType,
              _type,
              [for (final t in r.vehicleTypes) (t, t)],
              (v) {
                setState(() {
                  _type = v;
                  _make = null;
                  _model = null;
                });
                _loadCatalogue();
              },
              key: const Key('req_type'),
            ),
            _dropdown(
              l.reqMake,
              _make,
              [
                for (final m in makes)
                  (m['make'] as String, m['make'] as String),
                (other, l.reqOther),
              ],
              (v) => setState(() {
                _make = v;
                _model = null;
              }),
              key: const Key('req_make'),
            ),
            if (_make == other) ...[
              _field(_otherMake, l.reqMake, key: const Key('req_other_make')),
              _field(
                _otherModel,
                l.reqModel,
                key: const Key('req_other_model'),
              ),
            ] else
              _dropdown(
                l.reqModel,
                _model,
                [
                  for (final m in models)
                    (m['id'].toString(), m['model'] as String),
                  (other, l.reqOther),
                ],
                (v) => setState(() => _model = v),
                key: const Key('req_model'),
              ),
            if (_make != other && _model == other)
              _field(
                _otherModel,
                l.reqModel,
                key: const Key('req_other_model'),
              ),
            _dropdown(
              l.reqYear,
              _year?.toString(),
              [for (final y in r.vehicleYears) (y.toString(), y.toString())],
              (v) => setState(() => _year = int.tryParse(v ?? '')),
              key: const Key('req_year'),
            ),
            _dropdown(
              l.reqColour,
              _colour,
              [for (final c in colours) (c, c)],
              (v) => setState(() => _colour = v),
              key: const Key('req_colour'),
            ),
            _field(_plate, l.reqPlate, key: const Key('req_plate')),
            Text(l.reqVehicleReview, style: SgText.small),
            if (note != null) Text(note!, key: const Key('req_note')),
            SgPrimaryButton(
              key: const Key('req_save_vehicle'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy
                  ? null
                  : () => save(() async {
                      final custom = _make == other || _model == other;
                      final saved = await api.saveVehicle(_vehicleId, {
                        'vehicle_type': _type,
                        'year': _year,
                        'color': _colour,
                        'vehicle_number': _plate.text.trim().toUpperCase(),
                        if (custom) ...{
                          'custom': true,
                          'brand': _make == other
                              ? _otherMake.text.trim()
                              : _make,
                          'model': _otherModel.text.trim(),
                        } else
                          'catalogue_entry': int.tryParse(_model ?? ''),
                      });
                      setState(
                        () => _vehicleId = saved['id'] as int? ?? _vehicleId,
                      );
                    }),
            ),
            const SizedBox(height: SgSpace.s4),
            Row(
              children: [
                Expanded(child: Text(l.reqPhotosTitle, style: SgText.title)),
                if (r.item('vehicle_photos') != null)
                  StatusChip(item: r.item('vehicle_photos')!),
              ],
            ),
            if (_vehicleId == null)
              Text(l.reqAddVehicleFirst, style: SgText.small)
            else
              for (final (field, side) in [
                ('vehicle_pic', l.reqSideFront),
                ('photo_back', l.reqSideBack),
                ('photo_left', l.reqSideLeft),
                ('photo_right', l.reqSideRight),
                ('photo_interior', l.reqSideInside),
              ])
                FileSlot(
                  label: side,
                  target: 'vehicle:$_vehicleId',
                  field: field,
                  camera: true,
                  guide: l.reqSideGuide(side),
                  onDone: () => ref.invalidate(requirementsProvider),
                ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Payouts
// ---------------------------------------------------------------------------

class PayoutsReqScreen extends ConsumerStatefulWidget {
  const PayoutsReqScreen({super.key});
  @override
  ConsumerState<PayoutsReqScreen> createState() => _PayoutsState();
}

class _PayoutsState extends ConsumerState<PayoutsReqScreen> with _Saver {
  final _holder = TextEditingController(),
      _number = TextEditingController(),
      _again = TextEditingController();
  final _ifsc = TextEditingController(), _upi = TextEditingController();
  String _method = 'bank';
  String? _bank;

  Future<void> _lookup(String code) async {
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(code)) {
      setState(() => _bank = null);
      return;
    }
    try {
      final b = await ref.read(requirementsApiProvider).ifsc(code);
      setState(() => _bank = '${b['bank']}, ${b['branch']}');
    } catch (_) {
      setState(() => _bank = AppLocalizations.of(context).reqIfscUnknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqPayoutsTitle,
      builder: (context, ref, r) {
        final api = ref.read(requirementsApiProvider);
        final pm = r.payoutMethod;
        if (r.country == 'US') {
          return ListView(
            padding: const EdgeInsets.all(SgSpace.s4),
            children: [
              Text(l.reqStripeHint, style: SgText.body),
              const SizedBox(height: SgSpace.s3),
              if (pm['stripe_status'] != 'ready')
                SgPrimaryButton(
                  key: const Key('req_stripe'),
                  label: l.reqStripeSetup,
                  height: kSgTouch,
                  onPressed: busy
                      ? null
                      : () => save(() async {
                          final url = await api.stripeLink();
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        }),
                ),
              if (note != null) Text(note!),
            ],
          );
        }
        final bank = pm['bank'] as Json?;
        return ListView(
          padding: const EdgeInsets.all(SgSpace.s4),
          children: [
            if (bank != null)
              Text(
                l.reqOnFile('${bank['bank_name']} ${bank['account_masked']}'),
                style: SgText.body,
              ),
            if (pm['upi_masked'] != null)
              Text(l.reqOnFile('UPI ${pm['upi_masked']}'), style: SgText.body),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'bank', label: Text(l.reqBank)),
                ButtonSegment(value: 'upi', label: Text(l.reqUpi)),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            if (_method == 'bank') ...[
              _field(_holder, l.reqHolder, key: const Key('req_holder')),
              _field(
                _number,
                l.reqAccount,
                key: const Key('req_account'),
                type: TextInputType.number,
              ),
              _field(
                _again,
                l.reqAccountAgain,
                key: const Key('req_account_again'),
                type: TextInputType.number,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: SgSpace.s1),
                child: TextFormField(
                  key: const Key('req_ifsc'),
                  controller: _ifsc,
                  maxLength: 11,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l.reqIfsc,
                    helperText: _bank,
                    counterText: '',
                  ),
                  onChanged: (v) => _lookup(v.toUpperCase()),
                ),
              ),
            ] else
              _field(_upi, l.reqUpi, key: const Key('req_upi')),
            Text(l.reqHoldNote, style: SgText.small),
            if (note != null) Text(note!, key: const Key('req_note')),
            SgPrimaryButton(
              key: const Key('req_save_payout'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy
                  ? null
                  : () => save(() async {
                      await api.savePayoutMethod(
                        _method == 'upi'
                            ? {'method': 'upi', 'upi_id': _upi.text.trim()}
                            : {
                                'method': 'bank',
                                'holder_name': _holder.text.trim(),
                                'account_number': _number.text.trim(),
                                'account_number_confirm': _again.text.trim(),
                                'ifsc': _ifsc.text.trim().toUpperCase(),
                              },
                      );
                    }),
            ),
          ],
        );
      },
    );
  }
}
