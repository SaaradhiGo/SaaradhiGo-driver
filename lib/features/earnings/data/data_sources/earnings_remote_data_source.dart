import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/earning_model.dart';
import '../../../../domain/models/earnings_summary_model.dart';
import '../../../../domain/models/withdrawal_balance_model.dart';
import '../../../../domain/models/withdrawal_block_status_model.dart';
import '../../../../domain/models/withdrawal_model.dart';

abstract class EarningsRemoteDataSource {
  Future<EarningsSummaryModel> getEarningsSummary({String period = 'today'});
  Future<List<EarningModel>> getEarningsList({int page = 1, int pageSize = 20});
  Future<WithdrawalBalanceModel> getWithdrawalBalance();
  Future<WithdrawalModel> requestWithdrawal(double amount);
  Future<List<WithdrawalModel>> getWithdrawalHistory({
    int page = 1,
    int pageSize = 20,
  });
  Future<WithdrawalBlockStatusModel> getWithdrawalBlockStatus();
}

class EarningsRemoteDataSourceImpl implements EarningsRemoteDataSource {
  final Dio dio;

  EarningsRemoteDataSourceImpl(this.dio);

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data') &&
        responseData['data'] != null) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    return <String, dynamic>{};
  }

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

  @override
  Future<EarningsSummaryModel> getEarningsSummary({
    String period = 'today',
  }) async {
    final response = await dio.get(
      ApiEndpoints.driverEarningsSummary,
      queryParameters: {'period': period},
    );
    final dataMap = _extractData(response.data);
    return EarningsSummaryModel.fromJson(dataMap);
  }

  @override
  Future<List<EarningModel>> getEarningsList({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get(
      ApiEndpoints.driverEarnings,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final rawList = _extractList(response.data);
    return rawList
        .map((item) => EarningModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WithdrawalBalanceModel> getWithdrawalBalance() async {
    final response = await dio.get(ApiEndpoints.driverWithdrawalBalance);
    final dataMap = _extractData(response.data);
    return WithdrawalBalanceModel.fromJson(dataMap);
  }

  @override
  Future<WithdrawalModel> requestWithdrawal(double amount) async {
    final response = await dio.post(
      ApiEndpoints.driverWithdrawalRequest,
      data: {'amount': amount},
    );
    final dataMap = _extractData(response.data);
    return WithdrawalModel.fromJson(dataMap);
  }

  @override
  Future<List<WithdrawalModel>> getWithdrawalHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get(
      ApiEndpoints.driverWithdrawalHistory,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final rawList = _extractList(response.data);
    return rawList
        .map((item) => WithdrawalModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WithdrawalBlockStatusModel> getWithdrawalBlockStatus() async {
    final response = await dio.get(ApiEndpoints.driverWithdrawalBlockStatus);
    final dataMap = _extractData(response.data);
    return WithdrawalBlockStatusModel.fromJson(dataMap);
  }
}
