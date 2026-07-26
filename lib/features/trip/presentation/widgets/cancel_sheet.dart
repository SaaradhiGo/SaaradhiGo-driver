import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

typedef CancelResult = ({String reason, String? note});

/// Driver-side cancellation.
///
/// The reason list is exactly the server's `valid_reasons` set for
/// `/ride/trip/<id>/driver-cancel/` — sending anything else is a 400. The
/// consequences are spelled out because they are real: three cancels in 24
/// hours costs the driver an hour of online time and 0.1 of their rating.
Future<CancelResult?> showCancelSheet(BuildContext context) {
  return showModalBottomSheet<CancelResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CancelSheet(),
  );
}

const _reasons = <({String value, String label})>[
  (value: 'no_show', label: 'Rider did not show up'),
  (value: 'vehicle_issue', label: 'Vehicle problem'),
  (value: 'safety', label: 'Safety concern'),
  (value: 'personal', label: 'Personal emergency'),
  (value: 'other', label: 'Other'),
];

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cancel this trip?',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Frequent cancellations affect your rating and can temporarily '
            'stop you going online.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.warning),
          ),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (value) => setState(() => _reason = value),
            child: Column(
              children: [
                for (final reason in _reasons)
                  RadioListTile<String>(
                    value: reason.value,
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason.label),
                  ),
              ],
            ),
          ),
          if (_reason == 'other') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Tell us what happened',
                counterText: '',
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: _reason == null
                ? null
                : () => Navigator.of(context).pop(
                      (reason: _reason!, note: _note.text.trim()),
                    ),
            child: const Text('Cancel trip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep driving'),
          ),
        ],
      ),
    );
  }
}
