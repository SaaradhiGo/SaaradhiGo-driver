/// Pure logic behind Tier 3 screens 5 and 6: the 7-day earnings series and
/// the documents checklist. No widgets, so it is unit-tested directly.
library;

/// One day from `GET /driver/earnings/daily/?days=7`.
class DailyEarning {
  const DailyEarning({
    required this.date,
    required this.trips,
    required this.net,
  });

  final DateTime date;
  final int trips;

  /// The backend's own net for the day (never worked out here).
  final double net;
}

Map<String, dynamic>? _unwrap(dynamic body) {
  if (body is! Map) return null;
  final m = Map<String, dynamic>.from(body);
  final data = m['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return m;
}

double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

/// The days in date order, or null when the body is not the expected shape
/// (the chart is then hidden; it is never drawn from made-up rows).
List<DailyEarning>? parseDailyEarnings(dynamic body) {
  final m = _unwrap(body);
  final days = m?['days'];
  if (days is! List || days.isEmpty) return null;
  final out = <DailyEarning>[];
  for (final d in days) {
    if (d is! Map) return null;
    final date = DateTime.tryParse('${d['date']}');
    final net = _num(d['net']);
    if (date == null || net == null) return null;
    out.add(
      DailyEarning(
        date: date,
        trips: (_num(d['trips']) ?? 0).round(),
        net: net,
      ),
    );
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

/// A document's state as the driver reads it.
enum DocState { approved, inReview, uploaded, rejected, missing }

class DocItem {
  const DocItem({
    required this.key,
    required this.label,
    required this.present,
    required this.state,
    this.reason,
    this.vehicle = false,
  });

  final String key;
  final String label;
  final bool present;
  final DocState state;
  final String? reason;

  /// From `vehicle_documents` rather than `driver_documents`.
  final bool vehicle;
}

class DocsOverview {
  const DocsOverview({
    required this.items,
    this.docStatus,
    this.rejectionReason,
    this.vehicleId,
  });

  final List<DocItem> items;
  final String? docStatus;

  /// The one driver-level rejection reason (`doc_rejection_reason`).
  final String? rejectionReason;
  final int? vehicleId;

  int get total => items.length;

  /// Approved items, or (with no per-item status) present items once the
  /// driver's documents are approved.
  int get done => items.where((i) => i.state == DocState.approved).length;

  /// Rejected first, then missing, then the rest in the API's order.
  List<DocItem> get ordered {
    int rank(DocItem i) => switch (i.state) {
      DocState.rejected => 0,
      DocState.missing => 1,
      _ => 2,
    };
    final indexed = items.indexed.toList()
      ..sort((a, b) {
        final r = rank(a.$2).compareTo(rank(b.$2));
        return r != 0 ? r : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }
}

/// The item's state from the API's own words. With a per-item `status` it is
/// used as given. Without one, approval is never inferred per document: a
/// present item reads "Approved" only when the driver's `doc_status` is
/// approved, "Uploaded" otherwise; a rejected driver-level status with a
/// reason marks nothing per document (the reason is shown on its own).
DocState docStateOf(Map<String, dynamic> item, String? docStatus) {
  final present = item['present'] == true;
  switch ('${item['status'] ?? ''}'.toLowerCase()) {
    case 'approved':
      return DocState.approved;
    case 'rejected':
      return DocState.rejected;
    case 'in_review':
      return DocState.inReview;
    case 'missing':
      return DocState.missing;
  }
  if (!present) return DocState.missing;
  return (docStatus ?? '').toLowerCase() == 'approved'
      ? DocState.approved
      : DocState.uploaded;
}

/// Parses `GET /driver/driver/onboarding/`. Null when the body has no lists.
DocsOverview? parseDocsOverview(dynamic body) {
  final m = _unwrap(body);
  if (m == null) return null;
  final driverDocs = m['driver_documents'];
  final vehicleDocs = m['vehicle_documents'];
  if (driverDocs is! List && vehicleDocs is! List) return null;
  final docStatus = m['doc_status']?.toString();
  final items = <DocItem>[];
  void add(dynamic list, bool vehicle) {
    if (list is! List) return;
    for (final raw in list) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      if (item['required'] == false && item['present'] != true) continue;
      final reason = item['reason']?.toString().trim();
      items.add(
        DocItem(
          key: '${item['key']}',
          label: '${item['label'] ?? item['key']}',
          present: item['present'] == true,
          state: docStateOf(item, docStatus),
          reason: reason == null || reason.isEmpty ? null : reason,
          vehicle: vehicle,
        ),
      );
    }
  }

  add(driverDocs, false);
  add(vehicleDocs, true);
  final reason = m['doc_rejection_reason']?.toString().trim();
  final vehicle = m['vehicle'];
  return DocsOverview(
    items: items,
    docStatus: docStatus,
    rejectionReason: reason == null || reason.isEmpty ? null : reason,
    vehicleId: vehicle is Map ? _num(vehicle['id'])?.toInt() : null,
  );
}

/// The existing re-upload knows these documents only; the backend key maps
/// onto its document key. Null for a document the app cannot re-upload yet.
String? uploadKeyFor(String key) => switch (key) {
  'license_front' => 'license_doc',
  'license_back' => 'license_doc_back',
  'rc' || 'registration' => 'rc_doc',
  _ => null,
};
