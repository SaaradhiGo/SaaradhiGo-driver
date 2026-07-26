import '../../../core/utils/formatters.dart';

/// `GET /driver/withdrawals/balance/`.
class WithdrawalBalance {
  const WithdrawalBalance({
    required this.availableBalance,
    required this.blocked,
    required this.minimumWithdrawal,
    this.feePercent = 0,
    this.blockRemaining,
  });

  final double availableBalance;

  /// The backend enforces a cooldown between withdrawals. When it is on, the
  /// request endpoint refuses — so the button is disabled here with the
  /// remaining time rather than letting the driver tap into a rejection.
  final bool blocked;
  final double minimumWithdrawal;
  final double feePercent;
  final Duration? blockRemaining;

  bool canWithdraw(double amount) =>
      !blocked && amount >= minimumWithdrawal && amount <= availableBalance;

  static const empty = WithdrawalBalance(
    availableBalance: 0,
    blocked: false,
    minimumWithdrawal: 500,
  );

  factory WithdrawalBalance.fromJson(Map<String, dynamic> json) {
    final seconds = json['block_remaining_seconds'];
    return WithdrawalBalance(
      availableBalance: Fmt.toAmount(json['available_balance']),
      blocked: json['blocked'] == true,
      minimumWithdrawal: Fmt.toAmount(json['minimum_withdrawal'] ?? 500),
      feePercent: Fmt.toAmount(json['fee_percent']),
      blockRemaining: seconds == null
          ? null
          : Duration(seconds: Fmt.toAmount(seconds).round()),
    );
  }
}

/// A row from `GET /driver/withdrawals/history/` (WithdrawalRequestSerializer).
class WithdrawalRequest {
  const WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
    this.requestedAt,
    this.processedAt,
    this.adminNotes,
    this.payoutReferenceId,
  });

  final int id;
  final double amount;

  /// pending → approved → processing → completed, or failed / rejected.
  /// `completed` and `failed` only ever arrive via the Cashfree payout
  /// webhook, so a request sitting in `processing` is normal, not stuck.
  final String status;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final String? adminNotes;
  final String? payoutReferenceId;

  bool get isPending =>
      status == 'pending' || status == 'approved' || status == 'processing';
  bool get isSettled => status == 'completed';
  bool get isFailed => status == 'failed' || status == 'rejected';

  /// What the driver should understand from the status, in their terms.
  String get explanation {
    switch (status) {
      case 'pending':
        return 'Waiting for approval from the SaaradhiGo team.';
      case 'approved':
        return 'Approved. Sending to your UPI now.';
      case 'processing':
        return 'Payment in progress with the bank.';
      case 'completed':
        return 'Paid to your UPI.';
      case 'failed':
        return 'The transfer failed. The amount is back in your balance.';
      case 'rejected':
        return adminNotes?.isNotEmpty == true
            ? adminNotes!
            : 'This request was rejected.';
      default:
        return status;
    }
  }

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: Fmt.toAmount(json['amount']),
      status: json['status']?.toString() ?? 'pending',
      requestedAt: Fmt.parseDate(json['requested_at']),
      processedAt: Fmt.parseDate(json['processed_at']),
      adminNotes: json['admin_notes']?.toString(),
      payoutReferenceId: json['payout_reference_id']?.toString(),
    );
  }
}
