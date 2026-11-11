import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/elite_status_model.dart';
import '../../../../domain/models/incentive_quest_model.dart';

abstract class IncentivesRemoteDataSource {
  Future<List<IncentiveQuestModel>> getIncentives();
  Future<EliteStatusModel> getEliteStatus();
}

class IncentivesRemoteDataSourceImpl implements IncentivesRemoteDataSource {
  final Dio dio;

  IncentivesRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'] as List<dynamic>? ?? [];
      }
      if (data is List) {
        return data;
      }
      if (responseData.containsKey('results')) {
        return responseData['results'] as List<dynamic>? ?? [];
      }
    }
    if (responseData is List) {
      return responseData;
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return responseData;
    }
    return {};
  }

  @override
  Future<List<IncentiveQuestModel>> getIncentives() async {
    // One request. This used to try a single-segment path first and retry the
    // doubled one on 404; the single-segment path never existed, so the retry
    // was the only call that ever worked.
    final response = await dio.get(ApiEndpoints.driverIncentives);

    final rawList = _extractList(response.data);
    return rawList
        .map(
          (e) =>
              IncentiveQuestModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  @override
  Future<EliteStatusModel> getEliteStatus() async {
    final response = await dio.get(ApiEndpoints.driverEliteStatus);

    final rawMap = _extractMap(response.data);
    return EliteStatusModel.fromJson(rawMap);
  }
}
