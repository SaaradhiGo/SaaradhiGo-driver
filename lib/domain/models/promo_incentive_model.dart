/// One live incentive with this driver's progress, exactly as
/// `GET /api/v1/promotions/driver/incentives/` returns it
/// (servers/promotions/incentives.py::driver_view).
///
/// Written by hand rather than generated: it is read-only display data.
library;

import '../../core/utils/money_format.dart';
import '../../core/market/market_format.dart';

/// What the driver is told about one incentive.
enum PromoIncentiveState {
  inProgress('In progress'),
  earned('Earned'),
  pendingReview('Pending review'),
  budgetUsedUp('Offer budget used up'),
  paused('Paused'),
  expired('Ended');

  const PromoIncentiveState(this.label);
  final String label;
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

String? _s(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _date(Object? v) {
  final s = _s(v);
  return s == null ? null : DateTime.tryParse(s);
}

class PromoIncentive {
  const PromoIncentive({
    required this.id,
    required this.name,
    this.description = '',
    this.campaignState = 'live',
    this.targetTrips = 0,
    this.progressTrips = 0,
    this.status = 'in_progress',
    this.rewardMinor = 0,
    this.currency = '',
    this.startsAt,
    this.endsAt,
    this.budgetUsedUp = false,
    this.rewardStatus,
    this.commission = 'none',
    this.tax = 'not configured',
  });

  final int id;
  final String name;
  final String description;

  /// The campaign's own state: `live`, `exhausted` or `paused`.
  final String campaignState;
  final int targetTrips;
  final int progressTrips;

  /// The driver's progress status: `in_progress`, `completed` (reward paid) or
  /// `unfunded` (completed, budget used up).
  final String status;
  final int rewardMinor;
  final String currency;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool budgetUsedUp;

  /// `pending_review` when the reward is held for review, else null.
  final String? rewardStatus;
  final String commission;
  final String tax;

  factory PromoIncentive.fromJson(Map<dynamic, dynamic> m) => PromoIncentive(
    id: _int(m['id']),
    name: _s(m['name']) ?? 'Incentive',
    description: _s(m['description']) ?? '',
    campaignState: _s(m['state']) ?? 'live',
    targetTrips: _int(m['target_trips']),
    progressTrips: _int(m['progress_trips']),
    status: _s(m['status']) ?? 'in_progress',
    rewardMinor: _int(m['reward_minor']),
    currency: _s(m['currency']) ?? '',
    startsAt: _date(m['starts_at']),
    endsAt: _date(m['ends_at']),
    budgetUsedUp: m['budget_used_up'] == true,
    rewardStatus: _s(m['reward_status']),
    commission: _s(m['commission']) ?? 'none',
    tax: _s(m['tax']) ?? 'not configured',
  );

  /// The state to show. A reward held for review reads "Pending review" and
  /// nothing more; the driver is never told why.
  PromoIncentiveState stateAt(DateTime now) {
    if (rewardStatus == 'pending_review') {
      return PromoIncentiveState.pendingReview;
    }
    if (status == 'completed') return PromoIncentiveState.earned;
    if (status == 'unfunded' || budgetUsedUp || campaignState == 'exhausted') {
      return PromoIncentiveState.budgetUsedUp;
    }
    if (campaignState == 'paused') return PromoIncentiveState.paused;
    final end = endsAt;
    if (end != null && !end.isAfter(now)) return PromoIncentiveState.expired;
    return PromoIncentiveState.inProgress;
  }

  bool isActiveAt(DateTime now) =>
      stateAt(now) == PromoIncentiveState.inProgress;

  double get progressFraction {
    if (targetTrips <= 0) return status == 'completed' ? 1.0 : 0.0;
    return (progressTrips / targetTrips).clamp(0.0, 1.0);
  }

  /// "12 of 20 trips".
  String get progressText => targetTrips > 0
      ? '$progressTrips of $targetTrips ${targetTrips == 1 ? 'trip' : 'trips'}'
      : '$progressTrips trips';

  /// The reward in the currency the row carries, else the market's.
  String get rewardText {
    final code = currency.isEmpty ? null : currency;
    final amount = rewardMinor / 100;
    return code == null
        ? '${marketSymbol()}${amount.toStringAsFixed(2)}'
        : formatMoney(amount, code);
  }

  /// "Ends 5 Nov" style text; null when the row has no end.
  String? endsText(DateTime now) {
    final end = endsAt;
    if (end == null) return null;
    final remaining = end.difference(now);
    if (remaining.isNegative) return 'Ended';
    if (remaining.inDays >= 1) return 'Ends in ${remaining.inDays}d';
    if (remaining.inHours >= 1) {
      return 'Ends in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    }
    return 'Ends in ${remaining.inMinutes}m';
  }

  /// "No commission · Tax: not configured · Paid in your weekly payout", the
  /// same wording as the earnings breakdown (earnings_display.rewardNote).
  String get rewardNote {
    final parts = <String>[
      commission.toLowerCase() == 'none'
          ? 'No commission'
          : 'Commission: $commission',
      'Tax: $tax',
      'Paid in your weekly payout',
    ];
    return parts.join(' · ');
  }

  /// Parses `data` of the endpoint: `{incentives: [...], tax: 'not configured'}`.
  static List<PromoIncentive> listFromData(Object? data) {
    final raw = data is Map ? data['incentives'] : null;
    if (raw is! List) return const [];
    return [
      for (final r in raw)
        if (r is Map) PromoIncentive.fromJson(r),
    ];
  }
}
