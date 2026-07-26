import '../../../core/utils/formatters.dart';

/// `GET /driver/earnings/summary/`.
///
/// Note what the backend does and does not give us: `total_earned`,
/// `total_commission`, `today_earned`, `today_trips`, `commission_percent`
/// and `wallet_balance`. There is no weekly/monthly aggregate endpoint, so
/// those are derived client-side from the paginated earnings list rather
/// than invented server-side — the brief is explicit that no new endpoints
/// are to be added.
class EarningsSummary {
  const EarningsSummary({
    required this.totalEarned,
    required this.totalCommission,
    required this.totalTrips,
    required this.todayEarned,
    required this.todayTrips,
    required this.commissionPercent,
    required this.walletBalance,
  });

  final double totalEarned;
  final double totalCommission;
  final int totalTrips;
  final double todayEarned;
  final int todayTrips;
  final double commissionPercent;

  /// The driver's settlement balance. Since the wallet split this is a
  /// distinct row from any rider-side credit the same person may hold.
  ///
  /// It goes NEGATIVE on cash trips: the driver has the fare in hand and
  /// owes the platform its commission. The UI has to say that plainly.
  final double walletBalance;

  bool get owesPlatform => walletBalance < 0;

  double get netEarned => totalEarned - totalCommission;

  static const empty = EarningsSummary(
    totalEarned: 0,
    totalCommission: 0,
    totalTrips: 0,
    todayEarned: 0,
    todayTrips: 0,
    commissionPercent: 0,
    walletBalance: 0,
  );

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarned: Fmt.toAmount(json['total_earned']),
      totalCommission: Fmt.toAmount(json['total_commission']),
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
      todayEarned: Fmt.toAmount(json['today_earned']),
      todayTrips: (json['today_trips'] as num?)?.toInt() ?? 0,
      commissionPercent: Fmt.toAmount(json['commission_percent']),
      walletBalance: Fmt.toAmount(json['wallet_balance']),
    );
  }
}

/// One settlement row from `GET /driver/earnings/` (TransactionHistory).
class EarningEntry {
  const EarningEntry({
    required this.id,
    required this.amount,
    this.tripId,
    this.method,
    this.riderName,
    this.createdAt,
    this.netAmount,
    this.commission,
  });

  final int id;
  final double amount;
  final int? tripId;
  final String? method;
  final String? riderName;
  final DateTime? createdAt;
  final double? netAmount;
  final double? commission;

  bool get isCash => (method ?? '').toLowerCase() == 'cash';

  factory EarningEntry.fromJson(Map<String, dynamic> json) {
    return EarningEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: Fmt.toAmount(json['amount'] ?? json['net_amount']),
      tripId: (json['trip_id_val'] as num?)?.toInt(),
      method: json['method']?.toString(),
      riderName: json['user_name']?.toString(),
      createdAt: Fmt.parseDate(json['created_at']),
      netAmount: json['net_amount'] == null
          ? null
          : Fmt.toAmount(json['net_amount']),
      commission: json['commission'] == null
          ? null
          : Fmt.toAmount(json['commission']),
    );
  }
}

/// Client-side rollup over [EarningEntry] rows for the day / week / month
/// tabs. The backend has no period endpoint and we are not adding one.
class EarningsPeriod {
  const EarningsPeriod({
    required this.label,
    required this.gross,
    required this.trips,
    required this.cashCollected,
  });

  final String label;
  final double gross;
  final int trips;

  /// Cash the driver physically holds — the number that matters when they
  /// reconcile at the end of a shift.
  final double cashCollected;

  static EarningsPeriod from(
    String label,
    Iterable<EarningEntry> entries,
    DateTime since,
  ) {
    var gross = 0.0;
    var cash = 0.0;
    var count = 0;
    for (final e in entries) {
      final at = e.createdAt;
      if (at == null || at.isBefore(since)) continue;
      gross += e.amount;
      count++;
      if (e.isCash) cash += e.amount;
    }
    return EarningsPeriod(
      label: label,
      gross: gross,
      trips: count,
      cashCollected: cash,
    );
  }
}
