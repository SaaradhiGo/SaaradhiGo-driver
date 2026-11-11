import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';
import '../../ui/sg_widgets.dart';
import 'get_ready_screen.dart';
import 'requirement_forms.dart';
import 'requirements_api.dart';

/// Guided setup (10 Nov v2): the six steps the server sends, one step screen at a time. Each
/// file is a tile with its own status and Upload or Replace; fields save on leaving them.

String setupStepTitle(AppLocalizations l, String key) => switch (key) {
  'personal' => l.setupStepPersonal,
  'contact' => l.setupStepContact,
  'identity' => l.setupStepIdentity,
  'vehicle' => l.setupStepVehicle,
  'vehicle_docs' => l.setupStepVehicleDocs,
  'payouts' => l.setupStepPayouts,
  _ => key,
};

/// The step's one-line description; identity names the items this market asks for.
String setupStepDescription(AppLocalizations l, SetupStep s) => switch (s.key) {
  'personal' => l.setupStepPersonalDesc,
  'contact' => l.setupStepContactDesc,
  'identity' => [
    for (final k in s.items)
      ?switch (k) {
        'driving_licence' => l.setupItemLicence,
        'aadhaar' => l.setupItemAadhaar,
        'pan' => l.setupItemPan,
        'police_verification' => l.setupItemPolice,
        'background_check' => l.setupItemBackground,
        _ => null,
      },
  ].join(', '),
  'vehicle' => l.setupStepVehicleDesc,
  'vehicle_docs' => l.setupStepVehicleDocsDesc,
  'payouts' => l.setupStepPayoutsDesc,
  _ => '',
};

/// A status pill that never wraps: Missing, In review, Approved, Rejected, Expiring.
class SetupPill extends StatelessWidget {
  const SetupPill({super.key, required this.status, this.expires});
  final String status;
  final String? expires;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (text, ink, bg) = switch (status) {
      'approved' ||
      'done' => (l.reqStatusApproved, SgStatus.okInk, SgStatus.okBg),
      'in_review' => (l.reqStatusInReview, SgStatus.warnInk, SgStatus.warnBg),
      'expiring' => (
        l.reqStatusExpiring(expires ?? ''),
        SgStatus.warnInk,
        SgStatus.warnBg,
      ),
      'rejected' => (
        l.reqStatusRejected,
        SgColors.danger,
        SgColors.tint(SgColors.danger),
      ),
      _ => (l.reqStatusMissing, SgColors.inkMuted, SgStatus.rowFill),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SgSpace.s2,
        vertical: SgSpace.s1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SgRadius.pill),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: SgText.small.copyWith(color: ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Done, in review, current, to do, needs action: the marker beside a step.
class SetupStepMarker extends StatelessWidget {
  const SetupStepMarker({super.key, required this.step, this.current = false});
  final SetupStep step;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color ink, Widget child) = switch (step.status) {
      'done' => (
        SgStatus.okBg,
        SgStatus.okInk,
        Icon(Icons.check_rounded, size: 18, color: SgStatus.okInk),
      ),
      'in_review' => (
        SgStatus.warnBg,
        SgStatus.warnInk,
        Icon(Icons.schedule_rounded, size: 18, color: SgStatus.warnInk),
      ),
      'action' => (
        SgColors.tint(SgColors.danger),
        SgColors.danger,
        Icon(Icons.priority_high_rounded, size: 18, color: SgColors.danger),
      ),
      _ => (
        current ? SgColors.ink : SgStatus.rowFill,
        current ? SgColors.bg100 : SgColors.ink,
        Text(
          '${step.number}',
          style: SgText.small.copyWith(
            fontWeight: FontWeight.w600,
            color: current ? SgColors.bg100 : SgColors.ink,
          ),
        ),
      ),
    };
    return Container(
      key: Key('setup_marker_${step.key}_${step.status}'),
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: ink.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

/// The driver's vehicle id, for files that upload to the vehicle.
final setupVehicleIdProvider = FutureProvider.autoDispose<int?>((ref) async {
  final cars = await ref.watch(requirementsApiProvider).vehicles();
  return cars.isEmpty ? null : cars.first['id'] as int?;
});

/// One file: its label, status pill, the reviewer's reason, when it was uploaded, and its own
/// Upload or Replace.
class SetupFileTile extends ConsumerStatefulWidget {
  const SetupFileTile({
    super.key,
    required this.file,
    required this.requirements,
    this.vehicleId,
  });
  final ReqFile file;
  final Requirements requirements;
  final int? vehicleId;

  @override
  ConsumerState<SetupFileTile> createState() => _SetupFileTileState();
}

class _SetupFileTileState extends ConsumerState<SetupFileTile> {
  bool _busy = false;
  String? _note;

  /// Where the file goes: the photo to `personal/`, vehicle files to the vehicle, the rest to
  /// `identity/`; the field comes from the server's `upload_kinds`.
  (String, String)? get _target {
    final f = widget.file;
    if (f.key == 'profile_photo') return ('personal', 'photo');
    final field = widget.requirements.uploadKinds[f.key];
    if (field == null) return null;
    if (f.vehicle) {
      final id = widget.vehicleId;
      return id == null ? null : ('vehicle:$id', field);
    }
    return ('identity', field);
  }

  Future<void> _pick() async {
    final l = AppLocalizations.of(context);
    final target = _target!;
    final photo = widget.file.key == 'profile_photo';
    final side = widget.file.key.startsWith('vehicle_photo_');
    if (photo || side) {
      final go = await showModalBottomSheet<bool>(
        context: context,
        builder: (c) => GuideSheet(
          text: photo ? l.reqPhotoGuide : l.reqSideGuide(widget.file.label),
          oval: photo,
          onGo: () => Navigator.pop(c, true),
        ),
      );
      if (go != true) return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: photo ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      await ref
          .read(requirementsApiProvider)
          .upload(target.$1, target.$2, file.path);
      ref.invalidate(requirementsProvider);
    } catch (e) {
      if (mounted) setState(() => _note = serverMessage(e) ?? l.reqSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = widget.file;
    final status = f.status;
    final present = status != 'missing';
    final target = _target;
    final uploaded = f.uploadedAt == null
        ? null
        : l.setupUploadedOn(
            DateFormat('d MMM', l.localeName).format(f.uploadedAt!.toLocal()),
          );
    return Container(
      key: Key('setup_file_${f.key}'),
      margin: const EdgeInsets.only(bottom: SgSpace.s2),
      padding: const EdgeInsets.all(SgSpace.s3),
      decoration: BoxDecoration(
        color: SgColors.bg100,
        borderRadius: BorderRadius.circular(SgRadius.md),
        border: Border.all(
          color: status == 'rejected' ? SgColors.danger : SgColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.label,
                  style: SgText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SgSpace.s1),
                SetupPill(
                  key: Key('setup_pill_${f.key}_$status'),
                  status: status,
                ),
                if (status == 'rejected' && f.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: SgSpace.s1),
                    child: Text(
                      f.reason!,
                      style: SgText.small.copyWith(color: SgColors.danger),
                    ),
                  ),
                if (uploaded != null)
                  Text(
                    uploaded,
                    style: SgText.small.copyWith(color: SgColors.inkMuted),
                  ),
                if (target == null && f.vehicle)
                  Text(l.reqAddVehicleFirst, style: SgText.small),
                if (_note != null) Text(_note!, style: SgText.small),
              ],
            ),
          ),
          const SizedBox(width: SgSpace.s2),
          if (target != null)
            FilledButton(
              key: Key('setup_upload_${f.key}'),
              style: FilledButton.styleFrom(
                backgroundColor: SgColors.ink,
                foregroundColor: SgColors.bg100,
                minimumSize: const Size(96, 44),
              ),
              onPressed: _busy ? null : _pick,
              child: Text(
                _busy ? '…' : (present ? l.reqReplace : l.reqUpload),
                maxLines: 1,
                softWrap: false,
              ),
            ),
        ],
      ),
    );
  }
}

/// `/onboarding/step/:key`: one step at a time. Back and Save and continue move between steps
/// on this screen; the list on Get ready opens any step in any order.
class SetupStepScreen extends ConsumerStatefulWidget {
  const SetupStepScreen({super.key, required this.stepKey});
  final String stepKey;

  @override
  ConsumerState<SetupStepScreen> createState() => _SetupStepScreenState();
}

class _SetupStepScreenState extends ConsumerState<SetupStepScreen> {
  late String _key = widget.stepKey;
  final _handles = <String, SetupSaveHandle>{};
  bool _busy = false;

  Widget? _form(SetupSaveHandle h) => switch (_key) {
    'personal' => PersonalReqScreen(
      key: const ValueKey('form_personal'),
      embedded: true,
      handle: h,
      part: PersonalPart.details,
    ),
    'contact' => PersonalReqScreen(
      key: const ValueKey('form_contact'),
      embedded: true,
      handle: h,
      part: PersonalPart.contacts,
    ),
    'identity' => IdentityReqScreen(
      key: const ValueKey('form_identity'),
      embedded: true,
      handle: h,
    ),
    'vehicle' => VehicleReqScreen(
      key: const ValueKey('form_vehicle'),
      embedded: true,
      handle: h,
    ),
    'payouts' => PayoutsReqScreen(
      key: const ValueKey('form_payouts'),
      embedded: true,
      handle: h,
    ),
    _ => null,
  };

  Future<void> _saveAndContinue(Requirements r, SetupSaveHandle h) async {
    setState(() => _busy = true);
    final ok = await h.save();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    final i = r.steps.indexWhere((s) => s.key == _key);
    if (i >= 0 && i + 1 < r.steps.length) {
      setState(() => _key = r.steps[i + 1].key);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _back(Requirements r) {
    final i = r.steps.indexWhere((s) => s.key == _key);
    if (i > 0) {
      setState(() => _key = r.steps[i - 1].key);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final req = ref.watch(requirementsProvider);
    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: Text(l.reqTitle)),
      body: SafeArea(
        child: req.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: SgColors.gold500)),
          error: (_, _) =>
              Center(child: Text(l.reqLoadFailed, style: SgText.title)),
          data: (r) {
            final step = r.step(_key);
            if (step == null) {
              return Center(child: Text(l.reqLoadFailed, style: SgText.title));
            }
            final h = _handles.putIfAbsent(_key, SetupSaveHandle.new);
            final items = r.itemsOf(step);
            final files = [for (final i in items) ...i.files];
            final vehicleId = files.any((f) => f.vehicle)
                ? ref.watch(setupVehicleIdProvider).asData?.value
                : null;
            final header = r.minutesLeft > 0
                ? l.setupStepHeader(
                    '${step.number}',
                    '${r.steps.length}',
                    '${r.minutesLeft}',
                  )
                : l.setupStepHeaderNoTime(
                    '${step.number}',
                    '${r.steps.length}',
                  );
            final form = _form(h);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    key: Key('setup_step_$_key'),
                    padding: const EdgeInsets.all(SgSpace.s4),
                    children: [
                      Text(
                        header,
                        key: const Key('setup_step_header'),
                        style: SgText.small.copyWith(color: SgColors.inkMuted),
                      ),
                      const SizedBox(height: SgSpace.s1),
                      Text(setupStepTitle(l, _key), style: SgText.heading),
                      Text(
                        setupStepDescription(l, step),
                        style: SgText.body.copyWith(color: SgColors.inkMuted),
                      ),
                      const SizedBox(height: SgSpace.s4),
                      for (final i in items)
                        if (i.files.isEmpty &&
                            i.status == 'rejected' &&
                            i.reason != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: SgSpace.s2),
                            child: Text(
                              '${i.label}: ${i.reason}',
                              style: SgText.small.copyWith(
                                color: SgColors.danger,
                              ),
                            ),
                          ),
                      for (final f in files)
                        SetupFileTile(
                          file: f,
                          requirements: r,
                          vehicleId: vehicleId,
                        ),
                      if (files.isNotEmpty && form != null)
                        const SizedBox(height: SgSpace.s3),
                      ?form,
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SgSpace.s4,
                    SgSpace.s2,
                    SgSpace.s4,
                    SgSpace.s4,
                  ),
                  child: Row(
                    children: [
                      OutlinedButton(
                        key: const Key('setup_back'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(96, kSgTouch),
                        ),
                        onPressed: _busy ? null : () => _back(r),
                        child: Text(l.setupBack),
                      ),
                      const SizedBox(width: SgSpace.s3),
                      Expanded(
                        child: SgPrimaryButton(
                          key: const Key('setup_save_continue'),
                          label: l.setupSaveContinue,
                          onPressed: _busy
                              ? null
                              : () => _saveAndContinue(r, h),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
