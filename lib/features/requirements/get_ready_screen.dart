import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';
import '../../ui/sg_widgets.dart';
import 'requirements_api.dart';
import 'setup_steps.dart';

/// `/onboarding/ready` (10 Nov v2): the six setup steps the server sends, each with its state,
/// how many are done, and Continue setup to the next one. Any step opens in any order.
class GetReadyScreen extends ConsumerWidget {
  const GetReadyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final req = ref.watch(requirementsProvider);
    Future<void> open(String key) async {
      await context.push('/onboarding/step/$key');
      ref.invalidate(requirementsProvider);
    }

    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: Text(l.reqTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(requirementsProvider.future),
          child: req.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: SgColors.gold500),
            ),
            error: (_, _) => ListView(
              padding: const EdgeInsets.all(SgSpace.s5),
              children: [
                Text(
                  l.reqLoadFailed,
                  textAlign: TextAlign.center,
                  style: SgText.title,
                ),
                const SizedBox(height: SgSpace.s4),
                SgPrimaryButton(
                  label: l.earnRetry,
                  height: kSgTouch,
                  onPressed: () => ref.invalidate(requirementsProvider),
                ),
              ],
            ),
            data: (r) {
              final total = r.steps.length;
              final done = r.stepsDone;
              return ListView(
                key: const Key('req_list'),
                padding: const EdgeInsets.all(SgSpace.s4),
                children: [
                  Text(
                    l.setupStepsProgress('$done', '$total'),
                    key: const Key('req_progress'),
                    style: SgText.title,
                  ),
                  const SizedBox(height: SgSpace.s2),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    color: SgColors.gold500,
                    backgroundColor: SgColors.bg200,
                  ),
                  if (r.approved) ...[
                    const SizedBox(height: SgSpace.s3),
                    Container(
                      key: const Key('setup_approved'),
                      padding: const EdgeInsets.all(SgSpace.s3),
                      decoration: BoxDecoration(
                        color: SgStatus.okBg,
                        borderRadius: BorderRadius.circular(SgRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded, color: SgStatus.okInk),
                          const SizedBox(width: SgSpace.s2),
                          Expanded(
                            child: Text(
                              l.setupApproved,
                              style: SgText.body.copyWith(
                                color: SgStatus.okInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: SgSpace.s4),
                  for (final st in r.steps)
                    _StepRow(
                      step: st,
                      current: st.key == r.nextStep,
                      onTap: () => open(st.key),
                    ),
                  if (r.nextStep != null) ...[
                    const SizedBox(height: SgSpace.s4),
                    SgPrimaryButton(
                      key: const Key('setup_continue'),
                      label: l.setupContinue,
                      onPressed: () => open(r.nextStep!),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.current,
    required this.onTap,
  });
  final SetupStep step;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (String? state, Color color) = switch (step.status) {
      'done' => (l.reqStatusDone, SgStatus.okInk),
      'in_review' => (l.reqStatusInReview, SgStatus.warnInk),
      'action' => (l.setupNeedsAction, SgColors.danger),
      _ => (null, SgColors.inkMuted),
    };
    return Material(
      color: current ? SgColors.bg100 : Colors.transparent,
      borderRadius: BorderRadius.circular(SgRadius.md),
      child: InkWell(
        key: Key('setup_row_${step.key}'),
        borderRadius: BorderRadius.circular(SgRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SgSpace.s2,
            vertical: SgSpace.s3,
          ),
          child: Row(
            children: [
              SetupStepMarker(step: step, current: current),
              const SizedBox(width: SgSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setupStepTitle(l, step.key),
                      style: SgText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      setupStepDescription(l, step),
                      style: SgText.small.copyWith(color: SgColors.inkMuted),
                    ),
                    if (state != null)
                      Text(
                        state,
                        style: SgText.small.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: SgColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.item});
  final ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (text, color) = switch (item.status) {
      'approved' => (l.reqStatusApproved, SgColors.success),
      'done' => (l.reqStatusDone, SgColors.success),
      'expiring' => (l.reqStatusExpiring(item.expires ?? ''), SgColors.gold500),
      'in_review' => (l.reqStatusInReview, SgColors.gold500),
      'rejected' => (l.reqStatusRejected, SgColors.danger),
      _ => (l.reqStatusMissing, SgColors.inkMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SgSpace.s2,
        vertical: SgSpace.s1,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        key: Key('req_status_${item.key}_${item.status}'),
        style: SgText.small.copyWith(color: color),
      ),
    );
  }
}

/// Pick or take a file and send it; Upload or Replace with the item's state beside it.
class FileSlot extends ConsumerStatefulWidget {
  const FileSlot({
    super.key,
    required this.label,
    required this.target,
    required this.field,
    this.present = false,
    this.camera = false,
    this.guide,
    this.onDone,
  });
  final String label, target, field;
  final bool present, camera;
  final String? guide;
  final VoidCallback? onDone;

  @override
  ConsumerState<FileSlot> createState() => _FileSlotState();
}

class _FileSlotState extends ConsumerState<FileSlot> {
  bool _busy = false;
  String? _note;

  Future<void> _pick() async {
    final l = AppLocalizations.of(context);
    if (widget.guide != null) {
      final go = await showModalBottomSheet<bool>(
        context: context,
        builder: (c) => GuideSheet(
          text: widget.guide!,
          oval: widget.field == 'photo',
          onGo: () => Navigator.pop(c, true),
        ),
      );
      if (go != true) return;
    }
    final file = await ImagePicker().pickImage(
      source: widget.camera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: widget.field == 'photo'
          ? CameraDevice.front
          : CameraDevice.rear,
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
          .upload(widget.target, widget.field, file.path);
      setState(() => _note = l.reqUploaded);
      widget.onDone?.call();
    } catch (e) {
      setState(() => _note = serverMessage(e) ?? l.reqSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SgSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label, style: SgText.body)),
              OutlinedButton(
                key: Key('upload_${widget.field}'),
                onPressed: _busy ? null : _pick,
                child: Text(
                  _busy
                      ? '…'
                      : widget.camera
                      ? l.reqTakePhoto
                      : (widget.present ? l.reqReplace : l.reqUpload),
                ),
              ),
            ],
          ),
          if (_note != null) Text(_note!, style: SgText.small),
        ],
      ),
    );
  }
}

/// Before the camera opens: how to take the shot. For the profile photo, the face-in-oval guide.
class GuideSheet extends StatelessWidget {
  const GuideSheet({
    super.key,
    required this.text,
    required this.oval,
    required this.onGo,
  });
  final String text;
  final bool oval;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SgSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (oval)
              Container(
                key: const Key('face_oval_guide'),
                width: 160,
                height: 210,
                decoration: BoxDecoration(
                  border: Border.all(color: SgColors.gold500, width: 3),
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(80, 105),
                  ),
                ),
                child: Icon(
                  Icons.face_rounded,
                  size: 96,
                  color: SgColors.inkMuted,
                ),
              ),
            const SizedBox(height: SgSpace.s4),
            Text(text, style: SgText.body, textAlign: TextAlign.center),
            const SizedBox(height: SgSpace.s4),
            SgPrimaryButton(
              label: l.reqTakePhoto,
              height: kSgTouch,
              onPressed: onGo,
            ),
          ],
        ),
      ),
    );
  }
}
