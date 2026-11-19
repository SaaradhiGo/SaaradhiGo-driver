import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../ui/sg_l10n.dart';
import '../providers/trip_providers.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';
import 'package:saaradhigo_driver/ui/sg_format.dart';
import 'package:saaradhigo_driver/core/market/market_config.dart';
import 'package:saaradhigo_driver/core/market/market_providers.dart';

/// Driver-cancellation reasons accepted by the backend
/// (`POST /ride/trip/<id>/driver-cancel/` and the socket `cancel` action):
/// `no_show | vehicle_issue | safety | personal | other`.
List<(String, String)> _cancelReasons(AppLocalizations l) => [
  ('no_show', l.cancelReasonNoShow),
  ('vehicle_issue', l.cancelReasonVehicle),
  ('safety', l.cancelReasonSafety),
  ('personal', l.cancelReasonPersonal),
  ('other', l.cancelReasonOther),
];

/// Presents the cancellation reason picker; a reason cancels the trip over the
/// socket only once the driver confirms. The reason is required by the backend.
Future<void> showCancelTripSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.margin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sgL10n(sheetCtx).cancelSheetTitle,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sgL10n(sheetCtx).cancelSheetBody,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: SgText.sizeSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (code, label) in _cancelReasons(sgL10n(sheetCtx)))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onBackground,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () async {
                    final yes = await confirmCancelTrip(sheetCtx, ref, code);
                    if (!sheetCtx.mounted) return;
                    if (yes) {
                      ref
                          .read(tripSessionNotifierProvider.notifier)
                          .cancelTrip(reason: code);
                    }
                    Navigator.pop(sheetCtx);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// The market's cancellation fee in one line, or null where none applies.
/// Mirrors backend `ride.cancellation_penalty`: off unless app-config says
/// `charges_fee`, and never for a safety cancel.
String? cancelFeeLine(AppLocalizations l, MarketConfig m, String reason) {
  final percent = num.tryParse(m.cancelFeePercent ?? '');
  final capMinor = m.cancelFeeCapMinor;
  if (percent == null ||
      percent <= 0 ||
      capMinor == null ||
      reason == 'safety') {
    return null;
  }
  final cap = sgMoney(
    capMinor / math.pow(10, m.currency.minorUnits),
    currency: m.currencyCode,
  );
  if (cap == null) return null;
  final pct = percent == percent.truncate()
      ? percent.truncate().toString()
      : percent.toString();
  return l.cancelConfirmFee(pct, cap);
}

/// "Cancel this trip?": true only on the destructive button. Dismissing the
/// dialog or "Keep trip" cancels nothing.
Future<bool> confirmCancelTrip(
  BuildContext context,
  WidgetRef ref,
  String reason,
) async {
  final l = sgL10n(context);
  final fee = cancelFeeLine(l, ref.read(marketConfigProvider), reason);
  final yes = await showDialog<bool>(
    context: context,
    builder: (dCtx) => AlertDialog(
      key: const Key('cancel_confirm_dialog'),
      title: Text(l.cancelConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.cancelConfirmBody),
          if (fee != null) ...[
            const SizedBox(height: 8),
            Text(fee, key: const Key('cancel_confirm_fee')),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_confirm_keep'),
          onPressed: () => Navigator.pop(dCtx, false),
          child: Text(l.cancelConfirmKeep),
        ),
        TextButton(
          key: const Key('cancel_confirm_yes'),
          onPressed: () => Navigator.pop(dCtx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(l.cancelConfirmYes),
        ),
      ],
    ),
  );
  return yes == true;
}
