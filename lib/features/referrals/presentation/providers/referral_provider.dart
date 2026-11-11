import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/models/referral_models.dart';

/// `GET /api/v1/promotions/referrals/mine/` (the same endpoint the rider app
/// reads; the backend answers for whichever role is signed in).
class ReferralService {
  ReferralService(this.dio);
  final Dio dio;

  Future<ReferralMine?> fetchMine() async {
    final response = await dio.get(ApiEndpoints.promotionsReferralsMine);
    final body = response.data;
    return ReferralMine.fromData(body is Map ? body['data'] : null);
  }
}

final referralServiceProvider = Provider<ReferralService>((ref) {
  return ReferralService(ref.watch(dioClientProvider).dio);
});

/// The driver's code, the offer and the people they referred. Null when the
/// request failed (the screen offers a retry).
final referralMineProvider = FutureProvider.autoDispose<ReferralMine?>((
  ref,
) async {
  try {
    return await ref.watch(referralServiceProvider).fetchMine();
  } catch (_) {
    return null;
  }
});
