/// The documents a driver must supply, and the upload kind each maps to.
///
/// WHY THIS LIST IS NOT INVENTED HERE
/// ----------------------------------
/// The required set is decided by the driver's country on the server
/// (`servers/driver/compliance.py`, driven by `base/countries.py`), and the
/// operator console approves against that same source. This file only knows
/// how to *collect* them: which upload `kind` the backend expects, which field
/// name carries the resulting key, and what to call each document to a driver.
///
/// The `kind` strings must match `base/media.py`'s `UPLOAD_KINDS` exactly — a
/// kind the registry does not know is refused by `/uploads/presign/`, and a
/// mis-spelling here is a document that can never be submitted.
///
/// India is the launch market, so the India set is what the app offers. A US
/// driver's set differs (registration, insurance, inspection) and the server
/// already models it; wiring the app to ask the server which documents to
/// request is listed as follow-up work rather than guessed at here.
library;

enum DriverDocument {
  licenceFront(
    kind: 'license_doc',
    field: 'license_doc',
    label: 'Driving licence (front)',
    hint: 'The side with your photo and licence number.',
    target: DocumentTarget.driver,
  ),
  licenceBack(
    kind: 'license_doc_back',
    field: 'license_doc_back',
    label: 'Driving licence (back)',
    hint: 'The side with the validity dates and vehicle classes.',
    target: DocumentTarget.driver,
  ),
  registrationCertificate(
    kind: 'rc_doc',
    field: 'rc_doc',
    label: 'Registration Certificate (RC)',
    hint: 'The RC for the vehicle you will drive.',
    target: DocumentTarget.vehicle,
  ),
  insurance(
    kind: 'insurance_doc',
    field: 'insurance_doc',
    label: 'Insurance',
    hint: 'A valid commercial motor insurance policy.',
    target: DocumentTarget.vehicle,
  ),
  permit(
    kind: 'permit_doc',
    field: 'permit_doc',
    label: 'Commercial permit',
    hint: 'The passenger permit for your operating region.',
    target: DocumentTarget.vehicle,
  ),
  fitness(
    kind: 'fitness_doc',
    field: 'fitness_doc',
    label: 'Fitness certificate',
    hint: 'Confirms the vehicle is roadworthy.',
    target: DocumentTarget.vehicle,
  ),
  pollution(
    kind: 'puc_doc',
    field: 'puc_doc',
    label: 'Pollution Under Control (PUC)',
    hint: 'Your current PUC certificate.',
    target: DocumentTarget.vehicle,
  );

  const DriverDocument({
    required this.kind,
    required this.field,
    required this.label,
    required this.hint,
    required this.target,
  });

  /// The `UPLOAD_KINDS` key in `base/media.py`.
  final String kind;

  /// The API field the resulting S3 key is submitted under.
  final String field;

  final String label;
  final String hint;
  final DocumentTarget target;

  static List<DriverDocument> get driverDocuments => DriverDocument.values
      .where((d) => d.target == DocumentTarget.driver)
      .toList(growable: false);

  static List<DriverDocument> get vehicleDocuments => DriverDocument.values
      .where((d) => d.target == DocumentTarget.vehicle)
      .toList(growable: false);
}

/// Whether the document belongs to the person or to the vehicle. It decides
/// which endpoint the key is submitted to, and nothing else.
enum DocumentTarget { driver, vehicle }

/// One document's progress through pick -> upload -> submitted.
enum UploadState { empty, uploading, uploaded, failed }
