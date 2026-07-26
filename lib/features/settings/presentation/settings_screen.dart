import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../duty/presentation/duty_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final duty = ref.watch(dutyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionHeader(title: 'Appearance'),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) controller.setThemeMode(value);
              },
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(switch (mode) {
                        ThemeMode.system => 'Match system',
                        ThemeMode.light => 'Light',
                        ThemeMode.dark => 'Dark (easier at night)',
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Language'),
          Card(
            // Only English ships in Phase-0. Telugu and Hindi are listed so
            // the roadmap is visible, but they are disabled rather than
            // silently doing nothing when tapped.
            child: RadioGroup<String>(
              groupValue: settings.locale,
              onChanged: (value) {
                if (value != null) controller.setLocale(value);
              },
              child: Column(
                children: [
                  for (final option in const [
                    (code: 'en', label: 'English', enabled: true),
                    (code: 'te', label: 'తెలుగు (Telugu)', enabled: false),
                    (code: 'hi', label: 'हिन्दी (Hindi)', enabled: false),
                  ])
                    RadioListTile<String>(
                      value: option.code,
                      enabled: option.enabled,
                      title: Text(option.label),
                      subtitle:
                          option.enabled ? null : const Text('Coming soon'),
                    ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.pushEnabled,
                  title: const Text('Ride and earnings notifications'),
                  subtitle: const Text(
                    'Safety and payout alerts are always delivered.',
                  ),
                  onChanged: controller.setPushEnabled,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Diagnostics'),
          Card(
            child: Column(
              children: [
                DetailRowTile(
                  label: 'Dispatch connection',
                  value: switch (duty.status) {
                    DutyStatus.online => 'Connected',
                    DutyStatus.reconnecting => 'Reconnecting…',
                    DutyStatus.goingOnline => 'Connecting…',
                    DutyStatus.offline => 'Offline',
                  },
                ),
                DetailRowTile(
                  label: 'Last heartbeat',
                  value: duty.lastHeartbeatAt == null
                      ? '—'
                      : '${DateTime.now().difference(duty.lastHeartbeatAt!).inSeconds}s ago',
                ),
                DetailRowTile(
                  label: 'API',
                  value: Uri.parse(AppConfig.apiBaseUrl).host,
                ),
                const DetailRowTile(label: 'App version', value: '0.1.0'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              // Going offline first is not cosmetic: it closes the duty
              // socket and releases the driver from the dispatch pool before
              // the token is revoked.
              await ref.read(dutyControllerProvider.notifier).goOffline();
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(Routes.login);
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            label: const Text(
              'Sign out',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// A read-only settings row.
class DetailRowTile extends StatelessWidget {
  const DetailRowTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
