/// Shapes of the referral endpoints, copied from servers/promotions/referrals.py
/// (`mine`). Field names are the backend's.
library;

import '../../core/market/market_format.dart';
import '../../core/utils/money_format.dart' as money;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

String? _s(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Minor units to a displayable amount in the currency the row carries.
String? formatMinor(int minor, String? currency) {
  final code = (currency ?? '').trim().toUpperCase();
  const zero = {'JPY', 'KRW', 'VND'};
  final digits = zero.contains(code) ? 0 : 2;
  var divisor = 1;
  for (var i = 0; i < digits; i++) {
    divisor *= 10;
  }
  final amount = minor / divisor;
  if (code.isEmpty) return '${marketSymbol()}${amount.toStringAsFixed(digits)}';
  return money.formatMoney(amount, code, decimals: digits);
}

class ReferralOffer {
  const ReferralOffer({
    required this.name,
    required this.requiredTrips,
    required this.referrerRewardMinor,
    required this.refereeRewardMinor,
    required this.currency,
  });

  final String name;
  final int requiredTrips;
  final int referrerRewardMinor;
  final int refereeRewardMinor;
  final String currency;

  String? get referrerReward => formatMinor(referrerRewardMinor, currency);
  String? get refereeReward => formatMinor(refereeRewardMinor, currency);

  static ReferralOffer? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return ReferralOffer(
      name: _s(raw['name']) ?? '',
      requiredTrips: _int(raw['required_trips']),
      referrerRewardMinor: _int(raw['referrer_reward_minor']),
      refereeRewardMinor: _int(raw['referee_reward_minor']),
      currency: _s(raw['currency']) ?? '',
    );
  }
}

class ReferralRow {
  const ReferralRow({
    required this.who,
    required this.status,
    required this.tripsCompleted,
    required this.requiredTrips,
    required this.rewardMinor,
    required this.currency,
    this.rewardStatus,
    this.note = '',
  });

  final String who;

  /// `attached`, `qualified`, `rewarded` or `blocked`.
  final String status;
  final int tripsCompleted;
  final int requiredTrips;
  final int rewardMinor;
  final String currency;

  /// `pending_review` for a reward held for review, else null.
  final String? rewardStatus;

  /// `under review` for a blocked reward; never says why.
  final String note;

  /// A held reward or a blocked one reads "Pending review", never why.
  bool get pendingReview =>
      rewardStatus == 'pending_review' || status == 'blocked';

  bool get earned => status == 'rewarded' && !pendingReview;

  /// Joined and completed the required trips.
  bool get qualified => status == 'qualified' || status == 'rewarded';

  static ReferralRow fromJson(Map<dynamic, dynamic> m) => ReferralRow(
    who: _s(m['who']) ?? 'A new member',
    status: _s(m['status']) ?? 'attached',
    tripsCompleted: _int(m['trips_completed']),
    requiredTrips: _int(m['required_trips']),
    rewardMinor: _int(m['reward_minor']),
    currency: _s(m['currency']) ?? '',
    rewardStatus: _s(m['reward_status']),
    note: _s(m['note']) ?? '',
  );
}

class ReferralAttachedTo {
  const ReferralAttachedTo({
    required this.status,
    required this.tripsCompleted,
    required this.requiredTrips,
  });

  final String status;
  final int tripsCompleted;
  final int requiredTrips;
}

class ReferralMine {
  const ReferralMine({
    required this.code,
    required this.offer,
    required this.referrals,
    required this.attachedTo,
  });

  final String code;
  final ReferralOffer? offer;
  final List<ReferralRow> referrals;
  final ReferralAttachedTo? attachedTo;

  int get invites => referrals.length;
  int get qualifiedCount => referrals.where((r) => r.qualified).length;
  int get pendingReviewCount => referrals.where((r) => r.pendingReview).length;

  /// Rewards earned (paid and not under review), per currency, in minor units.
  Map<String, int> get earnedMinorByCurrency {
    final out = <String, int>{};
    for (final r in referrals.where((r) => r.earned)) {
      out[r.currency] = (out[r.currency] ?? 0) + r.rewardMinor;
    }
    return out;
  }

  /// Rewards held for review that carry an amount, per currency.
  Map<String, int> get pendingMinorByCurrency {
    final out = <String, int>{};
    for (final r in referrals.where(
      (r) => r.pendingReview && r.rewardMinor > 0,
    )) {
      out[r.currency] = (out[r.currency] ?? 0) + r.rewardMinor;
    }
    return out;
  }

  /// Parses the `data` object of `GET /promotions/referrals/mine/`.
  static ReferralMine? fromData(Object? data) {
    if (data is! Map) return null;
    final code = _s(data['code']);
    if (code == null) return null;
    final rows = <ReferralRow>[];
    final raw = data['referrals'];
    if (raw is List) {
      for (final r in raw) {
        if (r is Map) rows.add(ReferralRow.fromJson(r));
      }
    }
    final at = data['attached_to'];
    return ReferralMine(
      code: code,
      offer: ReferralOffer.fromJson(data['offer']),
      referrals: rows,
      attachedTo: at is Map
          ? ReferralAttachedTo(
              status: _s(at['status']) ?? '',
              tripsCompleted: _int(at['trips_completed']),
              requiredTrips: _int(at['required_trips']),
            )
          : null,
    );
  }
}
