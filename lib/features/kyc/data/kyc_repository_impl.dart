/// Submitting KYC: the driver's own documents, and a vehicle with its papers.
///
/// Two endpoints, both pre-existing:
///   * `PATCH /driver/driver/update/` — the driver's licence keys
///   * `POST  /driver/vehicles/add/`  — a vehicle plus its document keys
///
/// Neither is new. The driver app simply never called them: its profile screen
/// read `hasLicense` and rendered "Not uploaded", with no way to change that,
/// so a driver could be onboarded no further than a permanent block.
library;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/document_kind.dart';

class VehicleDraft {
  const VehicleDraft({
    required this.vehicleNumber,
    required this.vehicleType,
    this.brand,
    this.model,
    this.color,
    this.year,
    this.capacity,
  });

  final String vehicleNumber;

  /// Must match a `VehicleType.type` row ("sedan", "suv", ...). The server
  /// looks it up and 400s on an unknown value.
  final String vehicleType;
  final String? brand;
  final String? model;
  final String? color;
  final int? year;
  final int? capacity;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'vehicle_number': vehicleNumber.trim().toUpperCase(),
        'vehicle_type': vehicleType,
        if (brand != null && brand!.trim().isNotEmpty) 'brand': brand!.trim(),
        if (model != null && model!.trim().isNotEmpty) 'model': model!.trim(),
        if (color != null && color!.trim().isNotEmpty) 'color': color!.trim(),
        if (year != null) 'year': year,
        if (capacity != null) 'capacity': capacity,
      };
}

class KycRepository {
  const KycRepository(this._api);

  final ApiClient _api;

  /// Submit the driver's own document keys.
  ///
  /// Only the keys present are sent: a PATCH that includes
  /// `license_doc_back: null` would clear a document the driver already
  /// supplied, which is how a re-upload of one side wipes the other.
  Future<void> submitDriverDocuments(Map<DriverDocument, String> keys) async {
    final body = <String, dynamic>{};
    for (final entry in keys.entries) {
      if (entry.key.target != DocumentTarget.driver) continue;
      body[entry.key.field] = entry.value;
    }
    if (body.isEmpty) return;

    await _api.patch(ApiEndpoints.driverUpdate, body: body);
  }

  /// Create a vehicle with whatever documents have been uploaded so far.
  ///
  /// Returns the new vehicle's id. The server decides whether the set is
  /// complete — this app does not gate on completeness, because the required
  /// set is a server-side, country-driven decision and a client-side copy of
  /// it would be a second answer to the same question.
  Future<int?> createVehicle({
    required VehicleDraft draft,
    Map<DriverDocument, String> documentKeys = const {},
  }) async {
    final body = draft.toJson();
    for (final entry in documentKeys.entries) {
      if (entry.key.target != DocumentTarget.vehicle) continue;
      body[entry.key.field] = entry.value;
    }

    final data = await _api.post(ApiEndpoints.vehicleAdd, body: body);
    final id = data['id'] ?? data['vehicle_id'];
    return id is num ? id.toInt() : int.tryParse('${id ?? ''}');
  }

  /// Attach documents to a vehicle that already exists.
  Future<void> updateVehicleDocuments(
    int vehicleId,
    Map<DriverDocument, String> keys,
  ) async {
    final body = <String, dynamic>{};
    for (final entry in keys.entries) {
      if (entry.key.target != DocumentTarget.vehicle) continue;
      body[entry.key.field] = entry.value;
    }
    if (body.isEmpty) return;

    await _api.patch(ApiEndpoints.vehicle(vehicleId), body: body);
  }
}
