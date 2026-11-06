import 'package:flutter/material.dart';

import '../../../../core/market/market_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/earning_model.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../earnings_display.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

const String kPromoPaidLabel = 'Promo paid by SaaradhiGo';

/// One settled trip in the earnings list.
///
/// The top row is what it always was: trip number, time, and the net the API
/// returned. Everything underneath is shown ONLY when the API sent it, as the
/// API sent it:
///
///   * `cash_to_collect`: "Collect" with the amount on a cash trip (the fare less a
///     promo; on a US trip it already includes tax and the fee);
///   * `promo_paid_by_platform` as its own line, labelled by
///     `promo_paid_label`, with a note when it was credited to the wallet;
///   * US pass-through: the `deductions` lines (cash trips) or, on an online
///     trip, `tax_collected` / `regulatory_fee_collected`. Never earnings.
///
/// Gross, commission and net are not touched or recomputed here.
class EarningTripTile extends StatelessWidget {
  const EarningTripTile({super.key, required this.earning, this.timestamp});

  final EarningModel earning;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final symbol = marketSymbol();
    final extras = <Widget>[];

    if (earning.cashToCollect != null) {
      extras.add(
        _line(
          key: const Key('earning_collect'),
          label: 'Collect',
          value: '$symbol${earning.cashToCollect}',
          color: AppColors.onBackground,
          bold: true,
        ),
      );
    }
    if (isPositiveAmount(earning.promoPaidByPlatform)) {
      extras.add(
        _line(
          key: const Key('earning_promo_paid'),
          label: (earning.promoPaidLabel?.trim().isNotEmpty ?? false)
              ? earning.promoPaidLabel!.trim()
              : kPromoPaidLabel,
          value: '$symbol${earning.promoPaidByPlatform}',
          color: AppColors.onBackground,
          note: earning.promoCreditedToWallet == true
              ? 'Credited to your wallet'
              : null,
        ),
      );
    }
    if (earning.deductions.isNotEmpty) {
      for (final d in earning.deductions) {
        extras.add(
          _line(
            key: Key('earning_deduction_${d.kind}'),
            label: d.label,
            value: '$symbol${d.amount}',
            color: AppColors.onSurfaceVariant,
          ),
        );
      }
    } else {
      // An online US trip: the platform collected the tax and the fee from the
      // rider. Shown on the row so the totals reconcile, never as earnings.
      if (isPositiveAmount(earning.taxCollected)) {
        extras.add(
          _line(
            key: const Key('earning_tax_collected'),
            label: 'Sales tax collected (remitted by SaaradhiGo)',
            value: '$symbol${earning.taxCollected}',
            color: AppColors.onSurfaceVariant,
          ),
        );
      }
      if (isPositiveAmount(earning.regulatoryFeeCollected)) {
        extras.add(
          _line(
            key: const Key('earning_fee_collected'),
            label: 'Regulatory fee collected (remitted by SaaradhiGo)',
            value: '$symbol${earning.regulatoryFeeCollected}',
            color: AppColors.onSurfaceVariant,
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: AppColors.onBackground,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip #${earning.tripId ?? earning.id}',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timestamp ?? 'Completed',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: SgText.size(13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  earning.netEarning == null
                      ? ''
                      : '+$symbol${earning.netEarning}',
                  style: AppTypography.dataMono.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                height: 1,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...extras,
            ],
          ],
        ),
      ),
    );
  }

  Widget _line({
    required Key key,
    required String label,
    required String value,
    required Color color,
    String? note,
    bool bold = false,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: SgText.size(13),
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: SgText.size(13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.dataMono.copyWith(
              color: color,
              fontSize: SgText.size(13),
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
