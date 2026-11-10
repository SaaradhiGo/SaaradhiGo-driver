import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';
import '../../ui/sg_widgets.dart';
import 'requirements_api.dart';

/// `/onboarding/ready` (10 Nov): every item the driver's market asks for, its status and where
/// to fix it, and how far along they are. Going online waits for the items marked as blocking.
class GetReadyScreen extends ConsumerWidget {
  const GetReadyScreen({super.key});

  static const _fixAt = {
    'personal': '/onboarding/req/personal',
    'identity': '/onboarding/req/identity',
    'vehicle': '/onboarding/req/vehicle',
    'payouts': '/onboarding/req/payouts',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final req = ref.watch(requirementsProvider);
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
              final blocking = r.items
                  .where((i) => r.blocking.contains(i.key))
                  .map((i) => i.label)
                  .join(', ');
              final sections = [
                ('personal', l.reqSectionPersonal),
                ('identity', l.reqSectionIdentity),
                ('vehicle', l.reqSectionVehicle),
                ('payouts', l.reqSectionPayouts),
              ];
              return ListView(
                key: const Key('req_list'),
                padding: const EdgeInsets.all(SgSpace.s4),
                children: [
                  Text(
                    l.reqProgress(r.done.toString(), r.total.toString()),
                    key: const Key('req_progress'),
                    style: SgText.title,
                  ),
                  const SizedBox(height: SgSpace.s2),
                  LinearProgressIndicator(
                    value: r.total == 0 ? 0 : r.done / r.total,
                    color: SgColors.gold500,
                    backgroundColor: SgColors.bg200,
                  ),
                  const SizedBox(height: SgSpace.s3),
                  Text(
                    r.approved
                        ? l.reqApproved
                        : blocking.isNotEmpty
                        ? l.reqBlocking(blocking)
                        : l.reqAllIn,
                    style: SgText.body,
                  ),
                  for (final (section, title) in sections)
                    if (r.items.any((i) => i.section == section)) ...[
                      const SizedBox(height: SgSpace.s5),
                      Text(title, style: SgText.title),
                      for (final i in r.items.where(
                        (i) => i.section == section,
                      ))
                        ListTile(
                          key: Key('req_item_${i.key}'),
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: kSgTouch,
                          title: Text(
                            i.need == 'optional'
                                ? '${i.label} · ${l.reqOptional}'
                                : i.label,
                            style: SgText.body,
                          ),
                          subtitle: i.reason != null && !i.isDone
                              ? Text(
                                  i.reason!,
                                  style: SgText.small.copyWith(
                                    color: SgColors.danger,
                                  ),
                                )
                              : null,
                          trailing: StatusChip(item: i),
                          onTap: i.isDone || i.status == 'in_review'
                              ? null
                              : () async {
                                  await context.push(_fixAt[section]!);
                                  ref.invalidate(requirementsProvider);
                                },
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
