import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../../../../ui/sg_widgets.dart';
import '../providers/payout_plan.dart';

/// Withdraw now (owner ruling, 9 Nov): the amount, then the confirmation with
/// the provider's own fee, SaaradhiGo's fee (0), what the driver receives,
/// where it goes and when it arrives; then the request.
class InstantWithdrawSheet extends ConsumerStatefulWidget {
  const InstantWithdrawSheet({super.key, required this.available});

  final double available;

  static Future<bool?> show(BuildContext context, double available) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstantWithdrawSheet(available: available),
    );
  }

  @override
  ConsumerState<InstantWithdrawSheet> createState() =>
      _InstantWithdrawSheetState();
}

class _InstantWithdrawSheetState extends ConsumerState<InstantWithdrawSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.available.toStringAsFixed(0),
  );
  InstantQuote? _quote;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _why(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['error'] is Map && d['error']['message'] is String) {
        return d['error']['message'] as String;
      }
    }
    return sgL10n(context).instantFailed;
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
      _quote = null;
    });
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        ApiEndpoints.driverInstantQuote,
        queryParameters: {'amount': _amount.text.trim()},
      );
      setState(() => _quote = parseInstantQuote(res.data));
    } catch (e) {
      setState(() => _error = _why(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        ApiEndpoints.driverWithdrawalRequest,
        data: {'amount': _amount.text.trim(), 'instant': true},
      );
      ref.invalidate(payoutPlanProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = _why(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _line(String label, String value, {bool strong = false}) {
    final style = strong
        ? SgText.body.copyWith(fontWeight: FontWeight.w600)
        : SgText.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final q = _quote;
    String m(String v) => formatMoney(double.tryParse(v) ?? 0, q?.currency);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SgSheetSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.instantTitle, style: SgText.title),
            const SizedBox(height: SgSpace.s3),
            TextField(
              key: const Key('instant_amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l.instantAmount),
              onChanged: (_) => setState(() => _quote = null),
            ),
            if (q != null) ...[
              const SizedBox(height: SgSpace.s3),
              _line(l.instantAmount, m(q.amount)),
              _line(q.providerFeeLabel, '−${m(q.providerFee)}'),
              _line(l.instantSaaradhigoFee, m(q.saaradhigoFee)),
              _line(l.instantYouReceive, m(q.youReceive), strong: true),
              if (q.destination != null) _line(l.instantTo, q.destination!),
              _line(l.instantArrives, q.arrival),
            ],
            if (_error != null) ...[
              const SizedBox(height: SgSpace.s2),
              Text(
                _error!,
                key: const Key('instant_error'),
                style: SgText.small.copyWith(color: SgColors.danger),
              ),
            ],
            const SizedBox(height: SgSpace.s3),
            SgPrimaryButton(
              key: const Key('instant_go'),
              label: q != null && q.valid
                  ? l.instantConfirm(m(q.youReceive))
                  : l.instantSeeFee,
              onPressed: _busy
                  ? null
                  : (q != null && q.valid ? _confirm : _check),
            ),
          ],
        ),
      ),
    );
  }
}
