import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../trip/presentation/trip_controller.dart';
import 'safety_controller.dart';

/// Safety hub: SOS, emergency numbers, incident reporting.
///
/// SOS is the only zero-error-budget path on the platform, so the button is
/// large, unmissable, and behind a hold-to-confirm rather than a tap — an
/// accidental panic alert wastes the on-call responder's time on a real
/// emergency queue.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sos = ref.watch(sosControllerProvider);
    final trip = ref.watch(tripControllerProvider).trip;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (sos.isRaised)
            _RaisedCard(onDone: () {
              ref.read(sosControllerProvider.notifier).reset();
            })
          else
            _SosButton(
              isSending: sos.isSending,
              onConfirm: () async {
                final ok = await ref.read(sosControllerProvider.notifier).raise();
                if (!context.mounted) return;
                if (!ok) {
                  final error = ref.read(sosControllerProvider).error;
                  if (error != null) showErrorSnack(context, error);
                }
              },
            ),
          if (trip != null) ...[
            const SizedBox(height: 12),
            Text(
              'Your current trip #${trip.id} will be attached to the alert.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SectionHeader(title: 'Emergency contacts'),
          _ContactTile(
            icon: Icons.local_police_outlined,
            label: 'Police',
            number: '100',
          ),
          _ContactTile(
            icon: Icons.emergency_outlined,
            label: 'Ambulance',
            number: '108',
          ),
          _ContactTile(
            icon: Icons.woman_outlined,
            label: 'Women’s helpline',
            number: '1091',
          ),
          _ContactTile(
            icon: Icons.support_agent_outlined,
            label: 'SaaradhiGo support',
            number: '1800000000',
          ),
          const SectionHeader(title: 'Report an incident'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Raise a support ticket'),
              subtitle: const Text(
                'Lost item, fare dispute, rider behaviour, vehicle damage',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.support),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosButton extends StatefulWidget {
  const _SosButton({required this.onConfirm, required this.isSending});

  final Future<void> Function() onConfirm;
  final bool isSending;

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> {
  static const _holdDuration = Duration(milliseconds: 1200);
  bool _holding = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => setState(() => _holding = true),
          onLongPressEnd: (_) => setState(() => _holding = false),
          onLongPressCancel: () => setState(() => _holding = false),
          onLongPress: widget.isSending ? null : widget.onConfirm,
          child: AnimatedContainer(
            duration: _holdDuration,
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _holding
                  ? AppTheme.danger
                  : AppTheme.danger.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.danger.withValues(alpha: 0.4),
                  blurRadius: _holding ? 36 : 18,
                  spreadRadius: _holding ? 8 : 2,
                ),
              ],
            ),
            child: Center(
              child: widget.isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sos_rounded, size: 60, color: Colors.white),
                        SizedBox(height: 6),
                        Text(
                          'HOLD FOR SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Press and hold. Our 24×7 safety team is alerted immediately with '
          'your location.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RaisedCard extends StatelessWidget {
  const _RaisedCard({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.danger.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.shield_rounded, size: 46, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(
              'Help is on the way',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our safety team has your location and trip details, and is '
              'contacting you now. Stay where you are if it is safe to do so.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onDone, child: const Text('Dismiss')),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.number,
  });

  final IconData icon;
  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(number),
        trailing: const Icon(Icons.call_rounded),
        onTap: () => launchUrl(Uri.parse('tel:$number')),
      ),
    );
  }
}
