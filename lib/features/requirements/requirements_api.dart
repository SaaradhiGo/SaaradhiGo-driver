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
      expires = j['expires'] as String?;

  final String key, section, label, help, need, status;
  final bool blocksOnline;
  final String? reason, expires;

  bool get isDone => const {'approved', 'done', 'expiring'}.contains(status);
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
      approved = (raw['checklist'] as Json)['approved'] == true;

  final Json raw;
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
