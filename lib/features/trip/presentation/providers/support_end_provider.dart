import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/earning_model.dart';
import '../../../earnings/presentation/providers/earnings_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../domain/support_end.dart';

/// What the API says the driver got for a trip support ended.
///
/// Two places say it, and the app shows whichever it finds, as written:
///   * the trip's settlement row in the earnings list (`net_amount` after the
///     standard commission), present when the trip settled normally;
///   * the `trips.operator_ended_driver` notice (backend, operator_end.py), which
///     carries the sentence "SaaradhiGo pays you [amount] for the distance
///     driven." when SaaradhiGo paid the earnings (a safety incident or a
///     platform fault) or "You earn [amount] for the distance driven, after
///     commission." otherwise.
///
/// Neither is parsed for numbers or recomputed.
class SupportEndInfo {
  const SupportEndInfo({this.earning, this.notice});

  final EarningModel? earning;
  final String? notice;

  bool get isEmpty => earning == null && notice == null;
}

/// Reads [SupportEndInfo] for [tripId]. Best effort: a failure on one source
/// leaves the other, and both failing leaves an empty info, never an error.
final supportEndInfoProvider = FutureProvider.autoDispose
    .family<SupportEndInfo, int>((ref, tripId) async {
      EarningModel? earning;
      String? notice;

      try {
        final rows = await ref
            .read(earningsRepositoryProvider)
            .getEarningsList();
        for (final row in rows) {
          if (row.tripId == tripId) {
            earning = row;
            break;
          }
        }
      } catch (error, stackTrace) {
        AppLogger.w('Support-end earnings read failed', error, stackTrace);
      }

      try {
        final notices = await ref
            .read(notificationsRepositoryProvider)
            .getNotifications();
        for (final n in notices) {
          if (isSupportEndMessage(n.message) &&
              n.message.contains('#$tripId')) {
            notice = n.message;
            break;
          }
        }
      } catch (error, stackTrace) {
        AppLogger.w('Support-end notice read failed', error, stackTrace);
      }

      return SupportEndInfo(earning: earning, notice: notice);
    });
