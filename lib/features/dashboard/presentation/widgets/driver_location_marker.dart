import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Gold driver puck: an outward-pulsing ring behind a heading-rotated marker.
///
/// docs/10_LOCATION.md §3 calls for a gold vehicle icon with bearing rotation.
/// The pulse mirrors the `pulse-ring` keyframes in
/// `driver_home_dashboard/code.html:119-122` (scale 0.8 → 2.5, opacity 0.8 → 0).
class DriverLocationMarker extends StatefulWidget {
  const DriverLocationMarker({
    super.key,
    this.heading,
    this.weakSignal = false,
    this.pulsing = true,
  });

  /// Device heading in degrees clockwise from north. When null or invalid the
  /// marker renders as a plain dot rather than pointing in a fake direction.
  final double? heading;

  /// Dims the marker while the last fix is stale.
  final bool weakSignal;

  /// Pulse is reserved for the online state to keep the idle screen calm.
  final bool pulsing;

  static const double size = 96;

  @override
  State<DriverLocationMarker> createState() => _DriverLocationMarkerState();
}

class _DriverLocationMarkerState extends State<DriverLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _pulse.repeat();
  }

  @override
  void didUpdateWidget(DriverLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing == oldWidget.pulsing) return;
    if (widget.pulsing) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _hasHeading {
    final heading = widget.heading;
    return heading != null && heading >= 0 && heading.isFinite;
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.weakSignal ? 0.45 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulsing)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return Transform.scale(
                  scale: 0.8 + (1.7 * _pulse.value),
                  child: Opacity(
                    opacity: 0.8 - (0.8 * _pulse.value),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_hasHeading)
            Transform.rotate(
              angle: widget.heading! * (3.1415926535897932 / 180.0),
              child: const _DriverPuck(showHeading: true),
            )
          else
            const _DriverPuck(showHeading: false),
        ],
      ),
    );
  }
}

class _DriverPuck extends StatelessWidget {
  const _DriverPuck({required this.showHeading});

  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowGlow, blurRadius: 10),
        ],
      ),
      child: showHeading
          ? const Icon(Icons.navigation, size: 14, color: AppColors.darkText)
          : null,
    );
  }
}
