import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

/// What a driver provides, per market (10 Nov). The server decides which items the market asks
/// for (`/driver/requirements/`); the screens render what they are told and keep no per-country
/// list of their own. The same endpoints serve the web.

typedef Json = Map<String, dynamic>;

Json _data(Response<dynamic> r) {
  final body = r.data as Json;
  return (body['data'] as Json?) ?? body;
}

class ChecklistItem {
  ChecklistItem.fromJson(Json j)
    : key = j['key'] as String,
      section = j['section'] as String,
      label = j['label'] as String,
      help = (j['help'] as String?) ?? '',
      need = j['need'] as String,
      blocksOnline = j['blocks_online'] == true,
      status = j['status'] as String,
      reason = j['reason'] as String?,
      expires = j['expires'] as String?,
      step = j['step'] as String?,
      files = [
        for (final f in (j['files'] as List? ?? const []))
          ReqFile.fromJson(f as Json),
      ];

  final String key, section, label, help, need, status;
  final bool blocksOnline;
  final String? reason, expires, step;
  final List<ReqFile> files;

  bool get isDone => const {'approved', 'done', 'expiring'}.contains(status);
}

/// One file behind an item (v2): its own status, reviewer reason and upload time.
class ReqFile {
  ReqFile.fromJson(Json j)
    : key = j['key'] as String,
      label = (j['label'] as String?) ?? j['key'] as String,
      rawStatus = (j['status'] as String?) ?? 'missing',
      reason = j['reason'] as String?,
      uploadedAt = DateTime.tryParse('${j['uploaded_at']}'),
      vehicle = j['vehicle'] == true;

  final String key, label, rawStatus;
  final String? reason;
  final DateTime? uploadedAt;
  final bool vehicle;

  /// A file that is on the server and not yet decided is in review, never missing.
  String get status =>
      rawStatus == 'missing' && uploadedAt != null ? 'in_review' : rawStatus;
}

/// One of the six setup steps the server sends, in order; absent steps are not shown.
class SetupStep {
  SetupStep.fromJson(Json j)
    : key = j['key'] as String,
      number = j['number'] as int,
      items = List<String>.from(j['items'] as List? ?? const []),
      status = (j['status'] as String?) ?? 'todo';

  final String key, status;
  final int number;
  final List<String> items;
}

class Requirements {
  Requirements.fromJson(this.raw)
    : country = (raw['config'] as Json)['country'] as String,
      languages = List<String>.from(
        (raw['config'] as Json)['languages'] as List,
      ),
      items = [
        for (final i in ((raw['checklist'] as Json)['items'] as List))
          ChecklistItem.fromJson(i as Json),
      ],
      done = (raw['checklist'] as Json)['done'] as int,
      total = (raw['checklist'] as Json)['total'] as int,
      blocking = List<String>.from(
        (raw['checklist'] as Json)['blocking'] as List,
      ),
      approved = (raw['checklist'] as Json)['approved'] == true,
      steps = [
        for (final st in ((raw['checklist'] as Json)['steps'] as List? ?? []))
          SetupStep.fromJson(st as Json),
      ],
      nextStep = (raw['checklist'] as Json)['next_step'] as String?,
      minutesLeft = ((raw['checklist'] as Json)['minutes_left'] as int?) ?? 0;

  final Json raw;
  final List<SetupStep> steps;
  final String? nextStep;
  final int minutesLeft;
  int get stepsDone => steps.where((s) => s.status == 'done').length;

  SetupStep? step(String key) {
    for (final s in steps) {
      if (s.key == key) return s;
    }
    return null;
  }

  List<ChecklistItem> itemsOf(SetupStep s) => [
    for (final k in s.items) ?item(k),
  ];

  /// File key -> the upload field, from the server's `upload_kinds`.
  Map<String, String> get uploadKinds =>
      Map<String, String>.from(raw['upload_kinds'] as Map? ?? const {});
  final String country;
  final List<String> languages;
  final List<ChecklistItem> items;
  final int done, total;
  final List<String> blocking;
  final bool approved;

  bool asks(String key) => items.any((i) => i.key == key);
  ChecklistItem? item(String key) {
    for (final i in items) {
      if (i.key == key) return i;
    }
    return null;
  }

  Json get personal => raw['personal'] as Json;
  Json get identity => raw['identity'] as Json;
  Json get payoutMethod => raw['payout_method'] as Json;
  List<Json> get states => List<Json>.from(raw['states'] as List);
  List<Json> get relationships => List<Json>.from(raw['relationships'] as List);
  List<String> get vehicleTypes =>
      List<String>.from(raw['vehicle_types'] as List);
  List<int> get vehicleYears => List<int>.from(raw['vehicle_years'] as List);
  int? get minAge => (raw['config'] as Json)['min_driver_age'] as int?;
}

class RequirementsApi {
  RequirementsApi(this.dio);
  final Dio dio;
  static const _upload = Duration(seconds: 120);

  Future<Requirements> load() async =>
      Requirements.fromJson(_data(await dio.get('/driver/requirements/')));
  Future<Json> savePersonal(Json body) async =>
      _data(await dio.patch('/driver/personal/', data: body));
  Future<Json> saveIdentity(Json body) async =>
      _data(await dio.patch('/driver/identity/', data: body));
  Future<Json> savePayoutMethod(Json body) async =>
      _data(await dio.put('/driver/payout-method/', data: body));
  Future<String> stripeLink() async =>
      _data(await dio.post('/driver/payout-method/stripe/', data: {}))['url']
          as String;
  Future<Json> ifsc(String code) async =>
      _data(await dio.get('/driver/ifsc/$code/'));
  Future<Json> catalogue(String type) async => _data(
    await dio.get(
      '/driver/vehicle-catalogue/',
      queryParameters: {'type': type},
    ),
  );
  Future<List<Json>> vehicles() async {
    final body = (await dio.get('/driver/vehicles/')).data;
    final list = body is Map ? (body['data'] ?? body['results'] ?? []) : body;
    return List<Json>.from(
      list is Map ? (list['results'] ?? []) : list as List,
    );
  }

  Future<Json> saveVehicle(int? id, Json body) async => _data(
    id == null
        ? await dio.post('/driver/vehicles/add/', data: body)
        : await dio.patch('/driver/vehicles/$id/', data: body),
  );

  /// One file to the endpoint that owns it: `personal/` (photo), `identity/` (documents), a vehicle.
  Future<void> upload(String target, String field, String path) async {
    final url = target.startsWith('vehicle:')
        ? '/driver/vehicles/${target.substring(8)}/'
        : '/driver/$target/';
    await dio.patch(
      url,
      data: FormData.fromMap({field: await MultipartFile.fromFile(path)}),
      options: Options(sendTimeout: _upload, receiveTimeout: _upload),
    );
  }
}

final requirementsApiProvider = Provider<RequirementsApi>(
  (ref) => RequirementsApi(ref.watch(dioClientProvider).dio),
);
final requirementsProvider = FutureProvider.autoDispose<Requirements>(
  (ref) => ref.watch(requirementsApiProvider).load(),
);

/// The server's message for a refused save, else null.
String? serverMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return (data['error'] as Map)['message'] as String?;
    }
  }
  return null;
}
