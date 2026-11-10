import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/sg_format.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';
import '../../ui/sg_widgets.dart';
import 'get_ready_screen.dart';
import 'requirements_api.dart';

/// The sections a driver fills in (10 Nov), the same fields as the web, from the market's
/// requirements: personal (photo, name, date of birth, address, emergency contacts), identity,
/// vehicle (catalogue dropdowns and photos) and payouts.
///
/// Each form also runs `embedded` inside a setup step (v2): no frame, no files (the step shows
/// them as tiles), no button of its own; fields save when the driver leaves them, and the
/// step's Save and continue runs the form's save through a [SetupSaveHandle].

/// The step's Save and continue calls the embedded form's save through this.
class SetupSaveHandle {
  Future<bool> Function()? _save;
  Future<bool> save() => _save?.call() ?? Future.value(true);
}

class _Frame extends ConsumerWidget {
  const _Frame({
    required this.title,
    required this.builder,
    this.embedded = false,
  });
  final String title;
  final bool embedded;
  final Widget Function(BuildContext, WidgetRef, Requirements) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final req = ref.watch(requirementsProvider);
    final l = AppLocalizations.of(context);
    final body = req.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: SgColors.gold500)),
      error: (_, _) =>
          Center(child: Text(l.reqLoadFailed, style: SgText.title)),
      data: (r) => builder(context, ref, r),
    );
    if (embedded) return body;
    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: body),
    );
  }
}

/// A form's list: its own scroll on a page, part of the step's scroll when embedded.
Widget _list(bool embedded, List<Widget> children) => ListView(
  padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(SgSpace.s4),
  shrinkWrap: embedded,
  physics: embedded ? const NeverScrollableScrollPhysics() : null,
  children: children,
);

Widget _field(
  TextEditingController c,
  String label, {
  Key? key,
  TextInputType? type,
  int? max,
  VoidCallback? onLeave,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: SgSpace.s1),
  child: Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (has) {
      if (!has) onLeave?.call();
    },
    child: TextFormField(
      key: key,
      controller: c,
      keyboardType: type,
      maxLength: max,
      decoration: InputDecoration(labelText: label, counterText: ''),
    ),
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

/// A date row in the market's format, with the matching hint while empty.
Widget _dateRow(
  String label,
  String? iso,
  String country, {
  String? extra,
  Key? key,
  required VoidCallback onTap,
}) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  final shown = d == null ? sgDateHint(country) : sgMarketDate(d, country);
  return ListTile(
    key: key,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(extra == null ? shown : '$shown · $extra'),
    trailing: const Icon(Icons.calendar_today_rounded),
    onTap: onTap,
  );
}

/// Save, then a line saying what happened. Embedded forms also save on leaving a field.
mixin _Saver<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? note;
  bool get embedded;
  SetupSaveHandle? get handle;

  /// The form's save; [auto] true for a save on leaving a field.
  Future<void> submit(Requirements r, {bool auto = false});

  Future<bool> save(Future<void> Function() fn) async {
    final l = AppLocalizations.of(context);
    setState(() {
      busy = true;
      note = null;
    });
    try {
      await fn();
      ref.invalidate(requirementsProvider);
      if (mounted) {
        setState(() => note = embedded ? l.setupSavedAuto : l.reqSaved);
      }
      return true;
    } catch (e) {
      if (mounted) setState(() => note = serverMessage(e) ?? l.reqSaveFailed);
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void auto(Requirements r) {
    if (embedded && !busy) save(() => submit(r, auto: true));
  }

  void register(Requirements r) {
    handle?._save = () => save(() => submit(r));
  }

  Widget noteLine() => note == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: SgSpace.s2),
          child: Text(note!, key: const Key('req_note'), style: SgText.small),
        );
}

// ---------------------------------------------------------------------------
// Personal
// ---------------------------------------------------------------------------

/// Which part of the personal form: all of it, the details step or the contact step.
enum PersonalPart { all, details, contacts }

class PersonalReqScreen extends ConsumerStatefulWidget {
  const PersonalReqScreen({
    super.key,
    this.embedded = false,
    this.handle,
    this.part = PersonalPart.all,
  });
  final bool embedded;
  final SetupSaveHandle? handle;
  final PersonalPart part;
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

  @override
  bool get embedded => widget.embedded;
  @override
  SetupSaveHandle? get handle => widget.handle;

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
  Future<void> submit(Requirements r, {bool auto = false}) async {
    final details = widget.part != PersonalPart.contacts;
    final contacts = widget.part != PersonalPart.details;
    // A half-typed address is not sent from a field the driver just left.
    final address = !widget.embedded || _l1.text.trim().isNotEmpty;
    await ref.read(requirementsApiProvider).savePersonal({
      if (details) ...{
        'full_name': _name.text.trim(),
        'dob': ?_dob,
        if (address)
          'address': {
            'line1': _l1.text.trim(),
            'line2': _l2.text.trim(),
            'city': _city.text.trim(),
            'state_code': _state,
            'postal_code': _pin.text.trim(),
          },
        if (r.asks('permanent_address') && _same) 'permanent_same': true,
      },
      if (contacts && r.asks('emergency_contact'))
        'emergency_contacts': [
          for (var i = 0; i < 2; i++)
            if (_cName[i].text.trim().isNotEmpty)
              {
                'name': _cName[i].text.trim(),
                'relationship': _cRel[i],
                'phone_number': _cPhone[i].text.trim(),
              },
        ],
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqPersonalTitle,
      embedded: widget.embedded,
      builder: (context, ref, r) {
        _fill(r);
        register(r);
        void leave() => auto(r);
        final details = widget.part != PersonalPart.contacts;
        final contacts = widget.part != PersonalPart.details;
        return _list(widget.embedded, [
          if (details) ...[
            if (r.asks('profile_photo') && !widget.embedded) ...[
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
            _field(
              _name,
              l.reqFullName,
              key: const Key('req_name'),
              onLeave: leave,
            ),
            if (r.personal['name_pending'] != null)
              Text(l.reqNameInReview, style: SgText.small),
            _dateRow(
              l.reqDob,
              _dob,
              r.country,
              key: const Key('req_dob'),
              extra: _dob == null && r.minAge != null
                  ? l.reqMinAge('${r.minAge}')
                  : null,
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
                  leave();
                }
              },
            ),
            const SizedBox(height: SgSpace.s3),
            Text(l.reqAddress, style: SgText.title),
            _field(
              _l1,
              l.reqLine1,
              key: const Key('req_line1'),
              onLeave: leave,
            ),
            _field(_l2, l.reqLine2, onLeave: leave),
            _field(
              _city,
              l.reqCity,
              key: const Key('req_city'),
              onLeave: leave,
            ),
            _dropdown(
              l.reqState,
              _state,
              [
                for (final s in r.states)
                  (s['code'] as String, s['name'] as String),
              ],
              (v) {
                setState(() => _state = v);
                leave();
              },
              key: const Key('req_state'),
            ),
            _field(
              _pin,
              r.country == 'US' ? l.reqZip : l.reqPin,
              key: const Key('req_pin'),
              type: TextInputType.number,
              max: r.country == 'US' ? 5 : 6,
              onLeave: leave,
            ),
            if (r.asks('permanent_address'))
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _same,
                title: Text(l.reqPermanentSame),
                onChanged: (v) {
                  setState(() => _same = v ?? true);
                  leave();
                },
              ),
          ],
          if (contacts && r.asks('emergency_contact')) ...[
            const SizedBox(height: SgSpace.s3),
            Text(l.reqContactsTitle, style: SgText.title),
            Text(l.reqContactsHint, style: SgText.small),
            for (var i = 0; i < 2; i++) ...[
              const SizedBox(height: SgSpace.s2),
              Text(l.reqContact('${i + 1}'), style: SgText.body),
              _field(
                _cName[i],
                l.reqName,
                key: Key('req_contact_name_$i'),
                onLeave: leave,
              ),
              _dropdown(
                l.reqRelationship,
                _cRel[i],
                [
                  for (final x in r.relationships)
                    (x['code'] as String, x['label'] as String),
                ],
                (v) {
                  setState(() => _cRel[i] = v);
                  leave();
                },
                key: Key('req_contact_rel_$i'),
              ),
              _field(
                _cPhone[i],
                l.reqMobile,
                key: Key('req_contact_phone_$i'),
                type: TextInputType.phone,
                onLeave: leave,
              ),
            ],
          ],
          noteLine(),
          if (!widget.embedded) ...[
            const SizedBox(height: SgSpace.s3),
            SgPrimaryButton(
              key: const Key('req_save_personal'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy ? null : () => save(() => submit(r)),
            ),
          ],
        ]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

class IdentityReqScreen extends ConsumerStatefulWidget {
  const IdentityReqScreen({super.key, this.embedded = false, this.handle});
  final bool embedded;
  final SetupSaveHandle? handle;
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
  bool get embedded => widget.embedded;
  @override
  SetupSaveHandle? get handle => widget.handle;

  @override
  Future<void> submit(Requirements r, {bool auto = false}) async {
    await ref.read(requirementsApiProvider).saveIdentity({
      'license_number': _number.text.trim(),
      'license_expiry': ?_expiry,
      if (r.country == 'US') 'license_state': ?_state,
      if (_aadhaar.text.trim().isNotEmpty)
        'aadhaar_last4': _aadhaar.text.trim(),
      if (_pan.text.trim().isNotEmpty)
        'pan_number': _pan.text.trim().toUpperCase(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqIdentityTitle,
      embedded: widget.embedded,
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
        register(r);
        void leave() => auto(r);
        void reload() => ref.invalidate(requirementsProvider);
        return _list(widget.embedded, [
          _field(
            _number,
            l.reqLicenceNumber,
            key: const Key('req_licence_number'),
            onLeave: leave,
          ),
          if (r.country == 'US')
            _dropdown(
              l.reqLicenceState,
              _state,
              [
                for (final s in r.states)
                  (s['code'] as String, s['name'] as String),
              ],
              (v) {
                setState(() => _state = v);
                leave();
              },
              key: const Key('req_licence_state'),
            ),
          _dateRow(
            l.reqLicenceExpiry,
            _expiry,
            r.country,
            key: const Key('req_licence_expiry'),
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
                leave();
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
              onLeave: leave,
            ),
            Text(
              id['aadhaar_masked'] != null
                  ? l.reqOnFile(id['aadhaar_masked'] as String)
                  : l.reqAadhaarNever,
              style: SgText.small,
            ),
          ],
          if (r.asks('pan')) ...[
            _field(
              _pan,
              l.reqPan,
              key: const Key('req_pan'),
              max: 10,
              onLeave: leave,
            ),
            if (id['pan_masked'] != null)
              Text(
                l.reqOnFile(id['pan_masked'] as String),
                style: SgText.small,
              ),
          ],
          noteLine(),
          if (!widget.embedded) ...[
            SgPrimaryButton(
              key: const Key('req_save_identity'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy ? null : () => save(() => submit(r)),
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
          ],
          if (r.asks('background_check'))
            Text(
              l.reqBackground(id['background_check_status'] as String),
              style: SgText.body,
            ),
        ]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle
// ---------------------------------------------------------------------------

class VehicleReqScreen extends ConsumerStatefulWidget {
  const VehicleReqScreen({super.key, this.embedded = false, this.handle});
  final bool embedded;
  final SetupSaveHandle? handle;
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

  @override
  bool get embedded => widget.embedded;
  @override
  SetupSaveHandle? get handle => widget.handle;

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
  Future<void> submit(Requirements r, {bool auto = false}) async {
    // On leaving a field, a vehicle with no plate or year yet is not sent for review.
    if (auto && (_plate.text.trim().isEmpty || _year == null)) return;
    final custom = _make == other || _model == other;
    final saved = await ref.read(requirementsApiProvider).saveVehicle(
      _vehicleId,
      {
        'vehicle_type': _type,
        'year': _year,
        'color': _colour,
        'vehicle_number': _plate.text.trim().toUpperCase(),
        if (custom) ...{
          'custom': true,
          'brand': _make == other ? _otherMake.text.trim() : _make,
          'model': _otherModel.text.trim(),
        } else
          'catalogue_entry': int.tryParse(_model ?? ''),
      },
    );
    if (mounted) {
      setState(() => _vehicleId = saved['id'] as int? ?? _vehicleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqVehicleTitle,
      embedded: widget.embedded,
      builder: (context, ref, r) {
        _load(r);
        register(r);
        void leave() => auto(r);
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
        return _list(widget.embedded, [
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
              for (final m in makes) (m['make'] as String, m['make'] as String),
              (other, l.reqOther),
            ],
            (v) => setState(() {
              _make = v;
              _model = null;
            }),
            key: const Key('req_make'),
          ),
          if (_make == other) ...[
            _field(
              _otherMake,
              l.reqMake,
              key: const Key('req_other_make'),
              onLeave: leave,
            ),
            _field(
              _otherModel,
              l.reqModel,
              key: const Key('req_other_model'),
              onLeave: leave,
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
              (v) {
                setState(() => _model = v);
                leave();
              },
              key: const Key('req_model'),
            ),
          if (_make != other && _model == other)
            _field(
              _otherModel,
              l.reqModel,
              key: const Key('req_other_model'),
              onLeave: leave,
            ),
          _dropdown(
            l.reqYear,
            _year?.toString(),
            [for (final y in r.vehicleYears) (y.toString(), y.toString())],
            (v) {
              setState(() => _year = int.tryParse(v ?? ''));
              leave();
            },
            key: const Key('req_year'),
          ),
          _dropdown(l.reqColour, _colour, [for (final c in colours) (c, c)], (
            v,
          ) {
            setState(() => _colour = v);
            leave();
          }, key: const Key('req_colour')),
          _field(
            _plate,
            l.reqPlate,
            key: const Key('req_plate'),
            onLeave: leave,
          ),
          Text(l.reqVehicleReview, style: SgText.small),
          noteLine(),
          if (!widget.embedded) ...[
            SgPrimaryButton(
              key: const Key('req_save_vehicle'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy ? null : () => save(() => submit(r)),
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
        ]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Payouts
// ---------------------------------------------------------------------------

class PayoutsReqScreen extends ConsumerStatefulWidget {
  const PayoutsReqScreen({super.key, this.embedded = false, this.handle});
  final bool embedded;
  final SetupSaveHandle? handle;
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

  @override
  bool get embedded => widget.embedded;
  @override
  SetupSaveHandle? get handle => widget.handle;

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

  bool get _filledIn => _method == 'upi'
      ? _upi.text.trim().isNotEmpty
      : [
          _holder,
          _number,
          _again,
          _ifsc,
        ].every((c) => c.text.trim().isNotEmpty);

  @override
  Future<void> submit(Requirements r, {bool auto = false}) async {
    if (r.country == 'US') return;
    // In a step: half typed on leaving a field, or nothing typed over details on file, sends nothing.
    if (widget.embedded &&
        !_filledIn &&
        (auto || r.payoutMethod['kind'] != null)) {
      return;
    }
    await ref
        .read(requirementsApiProvider)
        .savePayoutMethod(
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
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      title: l.reqPayoutsTitle,
      embedded: widget.embedded,
      builder: (context, ref, r) {
        final api = ref.read(requirementsApiProvider);
        final pm = r.payoutMethod;
        register(r);
        void leave() => auto(r);
        if (r.country == 'US') {
          Future<void> stripe() => save(() async {
            final url = await api.stripeLink();
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          });
          return _list(widget.embedded, [
            Text(l.reqStripeHint, style: SgText.body),
            const SizedBox(height: SgSpace.s3),
            if (pm['stripe_status'] != 'ready')
              widget.embedded
                  ? OutlinedButton(
                      key: const Key('req_stripe'),
                      onPressed: busy ? null : stripe,
                      child: Text(l.reqStripeSetup),
                    )
                  : SgPrimaryButton(
                      key: const Key('req_stripe'),
                      label: l.reqStripeSetup,
                      height: kSgTouch,
                      onPressed: busy ? null : stripe,
                    ),
            noteLine(),
          ]);
        }
        final bank = pm['bank'] as Json?;
        return _list(widget.embedded, [
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
            _field(
              _holder,
              l.reqHolder,
              key: const Key('req_holder'),
              onLeave: leave,
            ),
            _field(
              _number,
              l.reqAccount,
              key: const Key('req_account'),
              type: TextInputType.number,
              onLeave: leave,
            ),
            _field(
              _again,
              l.reqAccountAgain,
              key: const Key('req_account_again'),
              type: TextInputType.number,
              onLeave: leave,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SgSpace.s1),
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: (has) {
                  if (!has) leave();
                },
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
            ),
          ] else
            _field(_upi, l.reqUpi, key: const Key('req_upi'), onLeave: leave),
          Text(l.reqHoldNote, style: SgText.small),
          noteLine(),
          if (!widget.embedded)
            SgPrimaryButton(
              key: const Key('req_save_payout'),
              label: l.reqSave,
              height: kSgTouch,
              onPressed: busy ? null : () => save(() => submit(r)),
            ),
        ]);
      },
    );
  }
}
