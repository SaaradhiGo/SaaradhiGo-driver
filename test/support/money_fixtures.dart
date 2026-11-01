/// Payloads for the money phase, in the exact shape the backend sends them.
///
/// Copied from the backend's serializers and tests, not invented here:
///   * earnings rows:    servers/driver/earnings.py::EarningRow.to_api and
///                       tests/test_us_passthrough.py, tests/test_promotions_settlement.py
///   * earnings summary: servers/driver/views.py::driver_earnings_summary and
///                       contracts/ride_contracts.json (driver_earnings_summary)
///   * trip detail:      servers/ride/serializers.py::TripDetailSerializer
///   * support end/release socket frames: servers/ride/operator_end.py,
///                       servers/ride/admin_trips.py
///   * trips.operator_ended_driver notice text: servers/notifications/seed_data.py
///
/// Ids are obvious placeholders.
library;

/// India, an ordinary online trip: fare 200.00, commission 15% (30.00), net
/// 170.00. No promo, no pass-through: every module 12 / US key is present but
/// empty, exactly as the API sends them.
Map<String, dynamic> indiaOnlineRow() => {
  'id': 501,
  'trip_id_val': 9001,
  'amount': '200.00',
  'commission': '30.00',
  'net_amount': '170.00',
  'created_at': '2026-11-01T09:30:00+05:30',
  'method': 'online',
  'user_name': 'Test Rider',
  'cash_in_hand': false,
  'commission_percent': '15.00',
  'promo_discount': '0.00',
  'cash_to_collect': null,
  'tax_collected': null,
  'regulatory_fee_collected': null,
  'tax_collected_label': null,
  'regulatory_fee_collected_label': null,
  'deductions': <dynamic>[],
  'promo_paid_by_platform': null,
  'promo_paid_label': null,
  'promo_credited_to_wallet': false,
};

/// An older backend: only the keys that existed before module 12.
Map<String, dynamic> legacyRow() => {
  'id': 500,
  'trip_id_val': 8999,
  'amount': '200.00',
  'commission': '30.00',
  'net_amount': '170.00',
  'created_at': '2026-10-30T09:30:00+05:30',
  'method': 'online',
  'user_name': 'Test Rider',
  'cash_in_hand': false,
  'commission_percent': '15.00',
};

/// India, a CASH trip with a 50.00 platform-funded promo: the driver collects
/// 150.00; gross, commission and net are on the full fare and do not move; the
/// discount was credited to the driver's wallet.
Map<String, dynamic> indiaCashPromoRow() => {
  'id': 502,
  'trip_id_val': 9002,
  'amount': '200.00',
  'commission': '30.00',
  'net_amount': '170.00',
  'created_at': '2026-11-01T10:05:00+05:30',
  'method': 'cash',
  'user_name': 'Test Rider',
  'cash_in_hand': true,
  'commission_percent': '15.00',
  'promo_discount': '50.00',
  'cash_to_collect': '150.00',
  'tax_collected': null,
  'regulatory_fee_collected': null,
  'tax_collected_label': null,
  'regulatory_fee_collected_label': null,
  'deductions': <dynamic>[],
  'promo_paid_by_platform': '50.00',
  'promo_paid_label': 'Promo paid by SaaradhiGo',
  'promo_credited_to_wallet': true,
};

/// India, a cash trip with no promo: "Collect" is the fare.
Map<String, dynamic> indiaCashRow() => {
  ...indiaOnlineRow(),
  'id': 503,
  'trip_id_val': 9003,
  'method': 'cash',
  'cash_in_hand': true,
  'cash_to_collect': '200.00',
};

/// US (additive tax), a CASH trip: fare 20.00, tax 8.25% (1.65), fee 0.50,
/// commission 25%: the driver nets 15.00 and collects 22.15 (tests/test_us_passthrough.py).
Map<String, dynamic> usCashRow() => {
  'id': 601,
  'trip_id_val': 9101,
  'amount': '20.00',
  'commission': '5.00',
  'net_amount': '15.00',
  'created_at': '2026-11-01T14:10:00-05:00',
  'method': 'cash',
  'user_name': 'Test Rider',
  'cash_in_hand': true,
  'commission_percent': '25.00',
  'promo_discount': '0.00',
  'cash_to_collect': '22.15',
  'tax_collected': '1.65',
  'regulatory_fee_collected': '0.50',
  'tax_collected_label': 'Sales tax collected (remitted by SaaradhiGo)',
  'regulatory_fee_collected_label':
      'Regulatory fee collected (remitted by SaaradhiGo)',
  'deductions': [
    {
      'kind': 'tax_collected',
      'label': 'Sales tax collected (remitted by SaaradhiGo)',
      'amount': '1.65',
    },
    {
      'kind': 'regulatory_fee_collected',
      'label': 'Regulatory fee collected (remitted by SaaradhiGo)',
      'amount': '0.50',
    },
  ],
  'promo_paid_by_platform': null,
  'promo_paid_label': null,
  'promo_credited_to_wallet': false,
};

/// US, an ONLINE trip: the tax and the fee are on the row but touch the driver
/// not at all (no deductions).
Map<String, dynamic> usOnlineRow() => {
  ...usCashRow(),
  'id': 602,
  'trip_id_val': 9102,
  'method': 'online',
  'cash_in_hand': false,
  'cash_to_collect': null,
  'deductions': <dynamic>[],
};

/// The summary with every module 12 / US / reward key present and empty: what
/// QA returns today for a driver with no promo, no rewards and no US trips.
Map<String, dynamic> summaryNothingNew() => {
  'total_earned': '1250.00',
  'total_commission': '187.50',
  'total_trips': 7,
  'today_earned': '400.00',
  'today_trips': 2,
  'commission_percent': '15.00',
  'commission_percent_mixed': false,
  'wallet_balance': '0',
  'total_net': '1062.50',
  'today_net': '340.00',
  'cash_collected': '0.00',
  'unresolved_trips': 0,
  'promo_paid_by_platform': '0.00',
  'today_promo_paid_by_platform': '0.00',
  'promo_paid_label': 'Promo paid by SaaradhiGo',
  'tax_collected': '0.00',
  'regulatory_fees_collected': '0.00',
  'tax_collected_label': 'Sales tax collected (remitted by SaaradhiGo)',
  'incentive_rewards': '0.00',
  'referral_rewards': '0.00',
  'incentive_commission': 'none',
  'incentive_tax': 'not configured',
  'rewards_pending_review': '0.00',
  'rewards_pending_review_label': 'Pending review',
  'reward_recovery': '0.00',
  'reward_recovery_label': 'Recovery of reward (reviewed)',
  'reward_recovery_remaining': '0.00',
};

/// The summary for a driver with promo trips and rewards.
Map<String, dynamic> summaryWithPromoAndRewards() => {
  ...summaryNothingNew(),
  'promo_paid_by_platform': '100.00',
  'today_promo_paid_by_platform': '50.00',
  'incentive_rewards': '500.00',
  'referral_rewards': '100.00',
};

/// The US summary: tax and fees collected for remittance, not in earned/net.
Map<String, dynamic> summaryUs() => {
  ...summaryNothingNew(),
  'total_earned': '40.00',
  'total_commission': '10.00',
  'total_net': '30.00',
  'cash_collected': '22.15',
  'tax_collected': '3.30',
  'regulatory_fees_collected': '1.00',
};

/// `GET /ride/trip/<id>/` for a cash trip that held a 50.00 promo.
Map<String, dynamic> tripDetailCashPromo() => {
  'id': 9002,
  'currency': 'INR',
  'status': 'completed',
  'estimated_fare': '200.00',
  'final_fare': '200.00',
  'actual_distance_km': '8.40',
  'actual_duration_min': 22,
  'payment_method': 'cash',
  'payment_status': 'pending',
  'promo_discount': '50.00',
  'rider_payable': '150.00',
};

/// `GET /ride/trip/<id>/` after support ended it as a safety incident or a
/// platform fault: the rider paid 0 and the payment is waived.
Map<String, dynamic> tripDetailPlatformFunded() => {
  'id': 9003,
  'currency': 'INR',
  'status': 'completed',
  'estimated_fare': '200.00',
  'final_fare': '0.00',
  'actual_distance_km': '6.25',
  'actual_duration_min': 17,
  'payment_method': 'cash',
  'payment_status': 'waived',
  'promo_discount': null,
  'rider_payable': null,
};

/// Socket frame: support ended a started trip (operator_end.py).
Map<String, dynamic> supportEndedFrame() => {
  'type': 'trip_status_update',
  'trip_id': 9003,
  'status': 'complete',
  'message': 'Your ride was ended by SaaradhiGo support.',
  'driver_id': 5,
};

/// Socket frame: support released a trip the driver had not reached.
Map<String, dynamic> supportReleasedFrame() => {
  'type': 'trip_status_update',
  'trip_id': 9004,
  'status': 'cancel',
  'message': 'Your ride was cancelled by support.',
  'driver_id': null,
};

/// An ordinary rider cancellation (no support wording).
Map<String, dynamic> riderCancelledFrame() => {
  'type': 'trip_status_update',
  'trip_id': 9005,
  'status': 'cancel',
  'message': 'Rider cancelled the trip.',
};

/// The in-app notice for a platform-funded end (template
/// trips.operator_ended_driver, in_app, with earnings_text for that rule).
const String platformFundedNoticeText =
    'Trip #9003 was ended by SaaradhiGo support. SaaradhiGo pays you '
    '₹120.00 for the distance driven. You are free to take new trips.';

/// The notice for a standard end.
const String standardEndNoticeText =
    'Trip #9006 was ended by SaaradhiGo support. You earn ₹92.40 for the '
    'distance driven, after commission. You are free to take new trips.';
