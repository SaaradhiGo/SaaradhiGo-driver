import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../domain/models/trip_model.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../../../../ui/sg_widgets.dart';

export '../../../../domain/models/trip_model.dart' show CancelActor;

/// The cancelled title, naming who cancelled only when the server said so
/// (`cancelled_by`); otherwise a neutral "Trip cancelled".
String cancelledTitle(AppLocalizations l, CancelActor actor) => switch (actor) {
  CancelActor.you => l.tripCancelledByYou,
  CancelActor.rider => l.tripCancelledByRider,
  CancelActor.unknown => l.tripCancelledNeutral,
};

/// Modal bottom sheet shown when an in-flight ride is cancelled.
///
/// Names who cancelled from the trip's cancel actor, shows the reason the
/// server sent (if any), and returns the driver home after a countdown.
class RideCancelledBottomSheet extends StatefulWidget {
  const RideCancelledBottomSheet({
    super.key,
    this.reason,
    this.actor = CancelActor.unknown,
    required this.onDismiss,
    this.autoDismissSeconds = 10,
  });

  /// Optional cancellation message/reason received from the backend.
  final String? reason;

  /// Who cancelled, from the server's `cancelled_by`.
  final CancelActor actor;

  /// Invoked on "Back to home" or when the auto-dismiss timer finishes.
  final VoidCallback onDismiss;

  /// Duration before automatically returning to the dashboard.
  final int autoDismissSeconds;

  @override
  State<RideCancelledBottomSheet> createState() =>
      _RideCancelledBottomSheetState();
}

class _RideCancelledBottomSheetState extends State<RideCancelledBottomSheet> {
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.autoDismissSeconds;
    if (_remainingSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_remainingSeconds > 1) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            _handleDismiss();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _countdownTimer?.cancel();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final reason = widget.reason?.trim();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return PopScope(
      canPop: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
          child: SgSheetSurface(
            padding: EdgeInsets.fromLTRB(
              SgSpace.s5,
              SgSpace.s3,
              SgSpace.s5,
              SgSpace.s5 + MediaQuery.paddingOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: SgColors.tint(SgColors.danger),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SgIcon(
                          SgIcons.close,
                          size: 28,
                          color: SgColors.danger,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: SgSpace.s4),
                  Text(
                    cancelledTitle(l, widget.actor),
                    key: const Key('trip_cancelled_title'),
                    style: SgText.screenTitle,
                    textAlign: TextAlign.center,
                  ),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: SgSpace.s2),
                    Text(
                      l.tripCancelReason(reason),
                      key: const Key('trip_cancelled_reason'),
                      style: SgText.body.copyWith(color: SgColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: SgSpace.s4),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SgSpace.s4,
                        vertical: SgSpace.s2,
                      ),
                      decoration: BoxDecoration(
                        color: SgColors.bg200,
                        borderRadius: BorderRadius.circular(SgRadius.pill),
                        border: Border.all(color: SgColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: SgColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: SgSpace.s2),
                          Flexible(
                            child: Text(
                              l.tripReturningOnline(_remainingSeconds),
                              style: SgText.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: SgSpace.s5),
                  SgPrimaryButton(
                    key: const Key('trip_cancelled_home'),
                    label: l.tripBackHome,
                    onPressed: _handleDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
