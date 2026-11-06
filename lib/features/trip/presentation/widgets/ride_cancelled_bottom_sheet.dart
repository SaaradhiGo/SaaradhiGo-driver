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

/// The cancel reason in the app's words, from the server's reason CODE
/// (`too_long`, `no_driver_accepted`, ...). Null for a missing, unknown or
/// uninformative code ('other'): the screen then shows no reason line, and
/// never the server's generic message.
String? cancelReasonText(
  AppLocalizations l,
  String? code,
  CancelActor actor,
) => switch ((code ?? '').trim().toLowerCase()) {
  'too_long' => l.cancelWhyTooLong,
  'wrong_location' => l.cancelWhyWrongLocation,
  'no_show' =>
    actor == CancelActor.rider ? l.cancelWhyDriverNoShow : l.cancelReasonNoShow,
  'safety' => l.cancelReasonSafety,
  'vehicle_issue' => l.cancelReasonVehicle,
  'personal' => l.cancelReasonPersonal,
  'no_driver_accepted' => l.cancelWhyNoDriver,
  _ => null,
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

  /// The server's cancel reason code; shown only when it maps to text.
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
    final reason = cancelReasonText(l, widget.reason, widget.actor);
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
                  if (reason != null) ...[
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
