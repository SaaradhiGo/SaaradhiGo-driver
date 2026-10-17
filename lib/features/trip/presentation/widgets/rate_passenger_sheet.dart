import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../data/data_sources/rating_remote_data_source.dart';
import '../providers/trip_providers.dart';

/// Rate the passenger on a trip that just ended.
///
/// `/ride/rate-trip/` is symmetric -- drivers rate riders as riders rate
/// drivers -- and neither app could submit one, so every average sat at its
/// default. For a driver, a rider rating is the only record that a passenger
/// was abusive or made them wait, which is the input an operator needs to act
/// on a pattern.
///
/// Skippable. A driver with the next ride waiting must not be held on this
/// screen, and a prompt that blocks them is one they learn to tap through.
Future<bool> showRatePassengerSheet(
  BuildContext context, {
  required int tripId,
  String? riderName,
}) async {
  final rated = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RatePassengerSheet(tripId: tripId, riderName: riderName),
  );
  return rated ?? false;
}

class RatePassengerSheet extends ConsumerStatefulWidget {
  const RatePassengerSheet({super.key, required this.tripId, this.riderName});

  final int tripId;
  final String? riderName;

  @override
  ConsumerState<RatePassengerSheet> createState() => _RatePassengerSheetState();
}

class _RatePassengerSheetState extends ConsumerState<RatePassengerSheet> {
  final _commentController = TextEditingController();
  int _score = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score == 0) {
      setState(() => _error = 'Tap a star to rate the passenger.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await ref
        .read(ratingRemoteDataSourceProvider)
        .rateTrip(
          tripId: widget.tripId,
          score: _score,
          comments: _commentController.text,
        );

    if (!mounted) return;
    if (result.isSettled) {
      // Submitted, or already rated. Both mean stop asking.
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = result.message ?? 'Could not save your rating.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final who = widget.riderName?.trim();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              who != null && who.isNotEmpty
                  ? 'How was your trip with $who?'
                  : 'How was your passenger?',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    // Each star is separately labelled: five identical
                    // "star" buttons cannot be used with a screen reader.
                    tooltip: '$star star${star == 1 ? '' : 's'}',
                    iconSize: 38,
                    onPressed: _submitting
                        ? null
                        : () => setState(() {
                            _score = star;
                            _error = null;
                          }),
                    icon: Icon(
                      star <= _score ? Icons.star : Icons.star_border,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _commentController,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Anything the team should know? (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'SUBMIT RATING',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
