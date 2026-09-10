class EarningsSummaryModel {
  final String totalEarned;
  final String totalCommission;
  final int totalTrips;
  final String todayEarned;
  final int todayTrips;
  final double commissionPercent;

  EarningsSummaryModel({
    required this.totalEarned,
    required this.totalCommission,
    required this.totalTrips,
    required this.todayEarned,
    required this.todayTrips,
    required this.commissionPercent,
  });

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    return EarningsSummaryModel(
      totalEarned: json['total_earned']?.toString() ?? '0.00',
      totalCommission: json['total_commission']?.toString() ?? '0.00',
      totalTrips: json['total_trips'] ?? 0,
      todayEarned: json['today_earned']?.toString() ?? '0.00',
      todayTrips: json['today_trips'] ?? 0,
      commissionPercent: (json['commission_percent'] ?? 0.0).toDouble(),
    );
  }
}

class EarningModel {
  final int id;
  final int tripId;
  final String amountCollected;
  final String platformFee;
  final String netEarning;
  final String createdAt;

  EarningModel({
    required this.id,
    required this.tripId,
    required this.amountCollected,
    required this.platformFee,
    required this.netEarning,
    required this.createdAt,
  });

  factory EarningModel.fromJson(Map<String, dynamic> json) {
    return EarningModel(
      id: json['id'] ?? 0,
      tripId: json['trip_id'] ?? 0,
      amountCollected: json['amount_collected']?.toString() ?? '0.00',
      platformFee: json['platform_fee']?.toString() ?? '0.00',
      netEarning: json['net_earning']?.toString() ?? '0.00',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
