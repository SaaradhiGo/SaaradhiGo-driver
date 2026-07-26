import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../trip/presentation/trip_controller.dart';
import 'dispatch_controller.dart';

/// The incoming ride card.
///
/// Rules this screen has to respect, all of them learned from the server's
/// dispatch design:
///   * it must dismiss itself when the countdown runs out — the server has
///     already moved on to the next wave
///   * it must dismiss on `trip_taken`, immediately, because the trip now
///     belongs to another driver
///   * Accept must be idempotent-safe under a double tap
///   * losing the race is a normal outcome, not an error
class RideOfferSheet extends ConsumerStatefulWidget {
  const RideOfferSheet({super.key});

  @override
  ConsumerState<RideOfferSheet> createState() => _RideOfferSheetState();
}

class _RideOfferSheetState extends ConsumerState<RideOfferSheet> {
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _accept(int tripId) async {
    final dispatch = ref.read(dispatchControllerProvider.notifier);
    dispatch.setResponding(true);

    final won = await ref.read(tripControllerProvider.notifier).acceptOffer(tripId);

    if (!mounted) return;
    dispatch.setResponding(false);
    _close();

    if (won) {
      context.go(Routes.activeTrip);
    } else {
      showInfoSnack(context, 'That ride was taken by another driver.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatchControllerProvider);
    final offer = state.offer;

    // The controller cleared the offer (expired / taken / accepted): the
    // sheet has no reason to exist any more.
    if (offer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final seconds = offer.remaining.inSeconds;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: offer.progress,
                          strokeWidth: 4,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            seconds <= 5 ? AppTheme.danger : AppTheme.brand,
                          ),
                        ),
                        Text(
                          '$seconds',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New ride request',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (offer.riderName != null)
                          Text(
                            offer.riderName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (offer.estimatedFare != null)
                    Text(
                      Fmt.money(offer.estimatedFare),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brand,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _LegRow(
                icon: Icons.trip_origin_rounded,
                color: AppTheme.brand,
                label: 'Pickup',
                address: offer.pickupAddress ?? 'Pickup location',
              ),
              const SizedBox(height: 10),
              _LegRow(
                icon: Icons.place_rounded,
                color: AppTheme.danger,
                label: 'Drop',
                address: offer.destinationAddress ?? 'Drop location',
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isResponding
                          ? null
                          : () {
                              ref
                                  .read(dispatchControllerProvider.notifier)
                                  .reject();
                              _close();
                            },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed:
                          state.isResponding ? null : () => _accept(offer.tripId),
                      child: state.isResponding
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                address,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
