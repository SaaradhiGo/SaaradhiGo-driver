import '../../ui/driver_f_logic.dart';
import '../requirements/requirements_api.dart';

/// The Documents rows, from the shared requirements checklist
/// (`GET /driver/requirements/`, field `checklist`): the same items, statuses
/// and expiry dates the web, the console and the approval gate read.

/// An optional item with nothing provided is [DocState.optionalNotAdded],
/// never "missing".
DocState docStateOfChecklist(String status, {String need = 'required'}) =>
    switch (status) {
      'approved' => DocState.approved,
      'done' => DocState.done,
      'expiring' => DocState.expiring,
      'expired' => DocState.expired,
      'in_review' => DocState.inReview,
      'rejected' => DocState.rejected,
      _ => need == 'optional' ? DocState.optionalNotAdded : DocState.missing,
    };

/// The file a re-upload targets: the rejected one, else the first the app can send.
String? _uploadFileOf(ChecklistItem i) {
  final files = i.files;
  for (final f in files) {
    if (f.status == 'rejected') return f.key;
  }
  return files.isEmpty ? null : files.first.key;
}

DocsOverview docsFromRequirements(Requirements r) {
  final items = <DocItem>[];
  for (final i in r.items) {
    final fileKey = _uploadFileOf(i);
    String? reason = i.reason?.trim();
    if (reason == null || reason.isEmpty) {
      for (final f in i.files) {
        final fr = f.reason?.trim();
        if (f.status == 'rejected' && fr != null && fr.isNotEmpty) {
          reason = fr;
          break;
        }
      }
    }
    items.add(
      DocItem(
        key: i.key,
        label: i.label,
        present: i.files.isNotEmpty || i.isDone,
        state: docStateOfChecklist(i.status, need: i.need),
        reason: reason == null || reason.isEmpty ? null : reason,
        vehicle: i.files.any((f) => f.vehicle),
        fileKey: fileKey,
        expires: i.expires,
      ),
    );
  }
  return DocsOverview(
    items: items,
    checklistDone: r.done,
    checklistTotal: r.total,
  );
}
