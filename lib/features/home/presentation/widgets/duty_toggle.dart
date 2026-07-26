import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// The single most important control in the app.
///
/// Deliberately large, unambiguous and slow to change state: an accidental
/// swipe that takes a driver offline costs them rides they never learn about.
/// The colour and the label always agree, and a reconnecting socket is shown
/// as its own state rather than silently reading as "online".
class DutyToggle extends StatelessWidget {
  const DutyToggle({
    super.key,
    required this.isOnline,
    required this.onChanged,
    this.isBusy = false,
    this.isReconnecting = false,
    this.enabled = true,
  });

  final bool isOnline;
  final bool isBusy;
  final bool isReconnecting;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent;
    final String title;
    final String subtitle;

    if (isBusy) {
      accent = AppTheme.warning;
      title = 'Going online…';
      subtitle = 'Getting your location and connecting to dispatch';
    } else if (isReconnecting) {
      accent = AppTheme.warning;
      title = 'Reconnecting…';
      subtitle = 'Your connection dropped. Retrying automatically.';
    } else if (isOnline) {
      accent = AppTheme.online;
      title = "You're online";
      subtitle = 'Waiting for ride requests';
    } else {
      accent = AppTheme.offline;
      title = "You're offline";
      subtitle = enabled
          ? 'Go online to start receiving rides'
          : 'Complete the steps below to start driving';
    }

    return Card(
      color: accent.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Switch.adaptive(
                value: isOnline,
                onChanged: enabled ? onChanged : null,
              ),
          ],
        ),
      ),
    );
  }
}
