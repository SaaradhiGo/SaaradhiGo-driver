import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/driver_home_view.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../requirements/requirements_api.dart';

/// Home's "Set up payouts to get paid" notice (16 Nov ruling: drive before
/// payout setup). Shown only when the server says payouts are not ready; the
/// payouts step itself picks Stripe (US) or bank/UPI (India).
class PayoutSetupBanner extends ConsumerWidget {
  const PayoutSetupBanner({super.key, this.onOpen});

  /// Opens the payouts step; defaults to the onboarding route.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(payoutReadyProvider) != false) return const SizedBox.shrink();
    final text = sgL10n(context).homePayoutSetupBanner;
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('home_payout_setup'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen ?? () => context.push('/onboarding/step/payouts'),
        child: HomeNotice(text),
      ),
    );
  }
}
