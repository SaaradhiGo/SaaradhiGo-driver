/// Press and hold to send (owner decision D4, 2026-11-02).
///
/// The SOS fired on a single tap, so an accidental tap sent a real alert
/// during the product audit (SOS #6 on QA). Wrap the control in this: a ring
/// fills while the driver holds, letting go early cancels, and completing the
/// hold fires [onConfirmed] at once with a heavy haptic. There is no cancel
/// delay after that; the way back is "Tap if this was a mistake".
///
/// Raw pointer events, not gestures: a tap and a long-press recogniser on one
/// widget cancel each other at the long-press timeout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldToSend extends StatefulWidget {
  const HoldToSend({
    super.key,
    required this.child,
    required this.onConfirmed,
    required this.semanticLabel,
    this.holdFor = const Duration(seconds: 2),
    this.enabled = true,
    this.circular = false,
    this.ringColor = const Color(0xFFFFFFFF),
  });

  final Widget child;
  final VoidCallback onConfirmed;
  final String semanticLabel;
  final Duration holdFor;
  final bool enabled;

  /// A ring around a round button; otherwise a bar along the bottom edge.
  final bool circular;
  final Color ringColor;

  @override
  State<HoldToSend> createState() => _HoldToSendState();
}

class _HoldToSendState extends State<HoldToSend>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdFor,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    HapticFeedback.heavyImpact();
    widget.onConfirmed();
    _hold.reset();
  }

  void _start() {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    _hold.forward(from: 0);
  }

  void _stop() {
    if (_hold.isAnimating) _hold.reverse();
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      hint: 'Press and hold for ${widget.holdFor.inSeconds} seconds to send',
      excludeSemantics: true,
      onLongPress: widget.enabled ? widget.onConfirmed : null,
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: AnimatedBuilder(
          animation: _hold,
          child: widget.child,
          builder: (context, child) => Stack(
            alignment: Alignment.center,
            children: [
              child!,
              if (_hold.value > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: widget.circular
                        ? CircularProgressIndicator(
                            value: _hold.value,
                            strokeWidth: 4,
                            color: widget.ringColor,
                          )
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: LinearProgressIndicator(
                              value: _hold.value,
                              minHeight: 4,
                              color: widget.ringColor,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
