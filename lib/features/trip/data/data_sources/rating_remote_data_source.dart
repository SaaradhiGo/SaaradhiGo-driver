import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';

/// The outcome of rating a trip.
///
/// The server's refusals are kept apart rather than flattened, because they
/// mean different things to a driver:
///   ALREADY_RATED (409)      -> done; stop offering it
///   TRIP_NOT_COMPLETED (400) -> not yet; the trip has not finished
///   FORBIDDEN (403)          -> not this driver's trip
enum RatingOutcome { submitted, alreadyRated, notEligible, failed }

class RatingResult {
  const RatingResult(this.outcome, {this.message, this.ratingId});

  final RatingOutcome outcome;
  final String? message;
  final int? ratingId;

  bool get isSubmitted => outcome == RatingOutcome.submitted;

  /// Nothing more for the driver to do: it worked, or it was already done.
  bool get isSettled =>
      outcome == RatingOutcome.submitted ||
      outcome == RatingOutcome.alreadyRated;
}

abstract class RatingRemoteDataSource {
  /// Rate the passenger on a completed trip. Never throws.
  Future<RatingResult> rateTrip({
    required int tripId,
    required int score,
    String? comments,
  });
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  RatingRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<RatingResult> rateTrip({
    required int tripId,
    required int score,
    String? comments,
  }) async {
    if (score < 1 || score > 5) {
      // Refused here so a mis-wired star widget cannot spend a round trip
      // learning what the server would have said.
      return const RatingResult(
        RatingOutcome.failed,
        message: 'Choose between 1 and 5 stars.',
      );
    }

    final body = <String, dynamic>{'trip_id': tripId, 'score': score};
    final trimmed = comments?.trim() ?? '';
    if (trimmed.isNotEmpty) body['comments'] = trimmed;

    try {
      final response = await dio.post(ApiEndpoints.rateTrip, data: body);

      // The status is checked here rather than relying on Dio throwing for
      // a non-2xx. Whether it throws depends on `validateStatus`, which is
      // configuration this data source does not own -- and reading a refusal
      // as a success would tell a driver their rating was saved when it was
      // not.
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return _refusal(status, response.data);
      }

      return RatingResult(
        RatingOutcome.submitted,
        ratingId: _ratingIdFrom(response.data),
      );
    } on DioException catch (e) {
      if (e.response == null) {
        return const RatingResult(
          RatingOutcome.failed,
          message: 'Could not reach the server. Your rating was not saved.',
        );
      }
      return _refusal(e.response?.statusCode ?? 0, e.response?.data);
    } catch (e) {
      return const RatingResult(
        RatingOutcome.failed,
        message: 'Could not save your rating.',
      );
    }
  }

  /// Classify a non-2xx response, from whichever path produced it.
  static RatingResult _refusal(int status, dynamic data) {
    final code = _codeFrom(data);
    final message = _messageFrom(data);

    if (status == 409 || code == 'ALREADY_RATED') {
      return RatingResult(RatingOutcome.alreadyRated, message: message);
    }
    if (code == 'TRIP_NOT_COMPLETED' || code == 'FORBIDDEN') {
      return RatingResult(RatingOutcome.notEligible, message: message);
    }
    return RatingResult(
      RatingOutcome.failed,
      message: message ?? 'Could not save your rating (error $status).',
    );
  }

  static int? _ratingIdFrom(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      final raw = inner is Map ? inner['rating_id'] : null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw);
    }
    return null;
  }

  static String? _codeFrom(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['code'] is String)
        return error['code'] as String;
    }
    return null;
  }

  /// The server's own words. "You can only rate a completed trip" is more
  /// use to a driver than any generic substitute.
  static String? _messageFrom(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (data['message'] is String) return data['message'] as String;
    }
    return null;
  }
}
