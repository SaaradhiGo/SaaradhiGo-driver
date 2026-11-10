import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Earnings history (10 Nov v2): any period, every month since joining, and monthly
/// statements. Amounts are decimal strings in `currency`, kept as the server sent them.

typedef Json = Map<String, dynamic>;

Json _data(Object? body) {
  if (body is Map && body['data'] is Map) {
    return Map<String, dynamic>.from(body['data'] as Map);
  }
  return Map<String, dynamic>.from(body as Map);
}

class EarningsBar {
  EarningsBar(this.key, this.earned, this.trips);
  final String key, earned;
  final int trips;
}

class EarningsHistory {
  EarningsHistory.fromJson(Json j)
    : period = j['period'] as String,
      start = DateTime.parse(j['start'] as String),
      end = DateTime.parse(j['end'] as String),
      currency = (j['currency'] as String?) ?? '',
      hasPrev = j['has_prev'] == true,
      hasNext = j['has_next'] == true,
      prev = j['prev'] as String?,
      next = j['next'] as String?,
      summary = Map<String, dynamic>.from(j['summary'] as Map? ?? const {}),
      unit = ((j['chart'] as Map?)?['unit'] as String?) ?? 'day',
      bars = [
        for (final b in ((j['chart'] as Map?)?['bars'] as List? ?? const []))
          EarningsBar(
            '${(b as Map)['key']}',
            '${b['earned']}',
            (b['trips'] as num?)?.toInt() ?? 0,
          ),
      ];

  final String period, currency, unit;
  final DateTime start, end;
  final bool hasPrev, hasNext;
  final String? prev, next;
  final Json summary;
  final List<EarningsBar> bars;

  String? s(String key) => summary[key]?.toString();
  int n(String key) => int.tryParse('${summary[key]}') ?? 0;
}

class EarningsMonths {
  EarningsMonths.fromJson(Json j)
    : currency = (j['currency'] as String?) ?? '',
      months = [
        for (final m in (j['months'] as List? ?? const []))
          Map<String, dynamic>.from(m as Map),
      ];
  final String currency;
  final List<Json> months;
}

/// One history request; a record so the provider family compares by value.
typedef HistoryQuery = ({
  String period,
  String? date,
  String? start,
  String? end,
});

class EarningsHistoryApi {
  EarningsHistoryApi(this.dio);
  final Dio dio;

  Future<EarningsHistory> history(HistoryQuery q) async {
    final res = await dio.get(
      '/driver/earnings/history/',
      queryParameters: {
        'period': q.period,
        'date': ?q.date,
        'start': ?q.start,
        'end': ?q.end,
      },
    );
    return EarningsHistory.fromJson(_data(res.data));
  }

  Future<EarningsMonths> months() async => EarningsMonths.fromJson(
    _data((await dio.get('/driver/earnings/months/')).data),
  );

  /// The month's statement as PDF bytes.
  Future<List<int>> statementPdf(String month) async {
    final res = await dio.get<List<int>>(
      '/driver/earnings/statement/',
      queryParameters: {'month': month, 'as': 'pdf'},
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }
}

final earningsHistoryApiProvider = Provider<EarningsHistoryApi>(
  (ref) => EarningsHistoryApi(ref.watch(dioClientProvider).dio),
);

final earningsHistoryProvider = FutureProvider.autoDispose
    .family<EarningsHistory, HistoryQuery>(
      (ref, q) => ref.watch(earningsHistoryApiProvider).history(q),
    );

final earningsMonthsProvider = FutureProvider.autoDispose<EarningsMonths>(
  (ref) => ref.watch(earningsHistoryApiProvider).months(),
);
