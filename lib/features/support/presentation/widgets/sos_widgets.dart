import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/support_providers.dart';

/// Raises an SOS alert at the driver's last known coordinates.
///
/// Shared by the floating SOS button on the trip screens and the big SOS card
/// on the Safety Center. [tripId] is supplied when an active trip exists so the
/// alert is associated with it (`POST /sos/`); otherwise a standalone alert is
/// raised.
Future<void> triggerSos(
  BuildContext context,
  WidgetRef ref, {
  int? tripId,
}) async {
  final position = ref.read(driverPositionProvider);
  if (position == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your location is unavailable. Please enable GPS and try again.',
        ),
      ),
    );
    return;
  }
  await ref
      .read(sosNotifierProvider.notifier)
      .raiseSos(
        tripId: tripId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
}

/// Surfaces SOS outcomes as transient banners wherever a SOS control is shown.
///
/// Render this once (e.g. alongside a SOS button or at the root of a screen
/// body). It watches [sosNotifierProvider] and shows a SnackBar for the last
/// confirmation, a saved emergency contact, or a recoverable error.
class SosFeedbackListener extends ConsumerWidget {
  const SosFeedbackListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sosNotifierProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        ref.read(sosNotifierProvider.notifier).acknowledgeError();
        return;
      }
      final confirmation = next.confirmationMessage;
      if (confirmation != null &&
          confirmation != previous?.confirmationMessage) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(confirmation),
            backgroundColor: AppColors.successContainer,
          ),
        );
        ref.read(sosNotifierProvider.notifier).clearConfirmation();
        return;
      }
      final saved = next.contactSavedMessage;
      if (saved != null && saved != previous?.contactSavedMessage) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(saved),
            backgroundColor: AppColors.successContainer,
          ),
        );
        ref.read(sosNotifierProvider.notifier).clearConfirmation();
      }
    });
    return const SizedBox.shrink();
  }
}

/// Compact circular SOS button used as a floating affordance on trip screens.
class TripSosButton extends ConsumerWidget {
  const TripSosButton({super.key, this.tripId, this.size = 48});

  /// Active trip id to attach the alert to, when the button is shown mid-trip.
  final int? tripId;

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sosNotifierProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: state.isRaising
                ? null
                : () => triggerSos(context, ref, tripId: tripId),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF4D4D), Color(0xFF93000A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: state.isRaising
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: AppColors.whiteText,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sos, color: AppColors.whiteText, size: 22),
            ),
          ),
        ),
        const SosFeedbackListener(),
      ],
    );
  }
}

/// Compact circular chat button that opens the live passenger chat.
class TripChatButton extends ConsumerWidget {
  const TripChatButton({
    super.key,
    required this.tripId,
    this.riderName,
    this.size = 48,
  });

  final int tripId;
  final String? riderName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = riderName?.trim();
    final iconSize = size < 44 ? 18.0 : 22.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push(
          '/trip-chat/$tripId'
          '${(name == null || name.isEmpty) ? '' : '?riderName=${Uri.encodeQueryComponent(name)}'}',
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            Icons.chat_bubble_rounded,
            color: AppColors.primary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

/// Top-right action cluster (chat + SOS) layered over trip map screens.
class TripSafetyActions extends ConsumerWidget {
  const TripSafetyActions({
    super.key,
    required this.tripId,
    this.riderName,
    this.size = 48,
  });

  final int tripId;
  final String? riderName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TripChatButton(tripId: tripId, riderName: riderName, size: size),
        const SizedBox(width: AppSpacing.sm),
        TripSosButton(tripId: tripId, size: size),
      ],
    );
  }
}
