import 'package:flutter/material.dart';
import '../widgets/hold_to_send.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/market/market_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../providers/support_providers.dart';
import '../widgets/sos_widgets.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

/// Safety Center Hub (`/safety`).
///
/// Home for the SOS trigger and the driver's safety tools. The large red card
/// raises an SOS immediately at the driver's current coordinates (attached to
/// the active trip when one exists); the tiles route to the emergency contact
/// manager, incident reporting, and the Help & Support center.
class SafetyCenterScreen extends ConsumerWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sos = ref.watch(sosNotifierProvider);
    final tripId = _activeTripId(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Safety Center',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            // Confirmation surfaces for SOS saves/errors.
            const SosFeedbackListener(),
            const SizedBox(height: AppSpacing.unit),

            // SOS Emergency Trigger Card.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: HoldToSend(
                key: const Key('safety_center_sos_hold'),
                semanticLabel: 'Emergency SOS',
                enabled: !sos.isRaising,
                onConfirmed: () => triggerSos(context, ref, tripId: tripId),
                child: Ink(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    // Flat danger fill: no gradients or glows on mobile.
                    color: AppColors.error,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.onError.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: sos.isRaising
                            ? Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: AppColors.onError,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.sos,
                                color: AppColors.onError,
                                size: 30,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency SOS',
                              style: AppTypography.headlineSm.copyWith(
                                color: AppColors.onError,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hold for 2 seconds. Sends your live location '
                              'to our safety team.',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onError.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: SgText.size(13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Help lines.
            Text(
              'Immediate Help',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // SaaradhiGo's own line, from app-config, hidden while none is
                  // configured. It showed the placeholder 1800-000-0000.
                  if (ref.watch(marketConfigProvider).supportPhone
                      case final support?) ...[
                    _buildHelpRow(
                      icon: Icons.phone_in_talk_rounded,
                      title: 'SaaradhiGo support',
                      subtitle: support,
                      color: AppColors.success,
                      onTap: () => _dial(context, support),
                    ),
                    _buildDivider(),
                  ],
                  _buildHelpRow(
                    icon: Icons.local_police_rounded,
                    // From app-config; the built-in text is exactly what shipped.
                    title: ref.watch(marketConfigProvider).emergencyTitle,
                    subtitle: ref.watch(marketConfigProvider).emergencySubtitle,
                    color: AppColors.error,
                    onTap: () => _dial(
                      context,
                      ref.read(marketConfigProvider).emergency.number,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety tools list.
            Text(
              'Safety Tools',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSafetyTile(
                    icon: Icons.contacts_rounded,
                    title: 'Emergency Contacts',
                    subtitle: 'Manage the trusted contact notified during SOS',
                    onTap: () => context.push('/emergency-contacts'),
                  ),
                  _buildDivider(),
                  _buildSafetyTile(
                    icon: Icons.report_problem_rounded,
                    title: 'Report an Incident',
                    subtitle: 'Report safety concerns, crashes or disputes',
                    onTap: () => context.push('/report-incident'),
                  ),
                  _buildDivider(),
                  _buildSafetyTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Help & Support',
                    subtitle: 'View your tickets or raise a new one',
                    onTap: () => context.push('/support'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  int? _activeTripId(WidgetRef ref) {
    final session = ref.read(tripSessionNotifierProvider);
    final status = session.status;
    if (status == null || status.isTerminal) return null;
    final trip = session.trip;
    if (trip == null) return null;
    return trip.id;
  }

  Future<void> _dial(BuildContext context, String number) async {
    final ok = await launchUrl(
      Uri(scheme: 'tel', path: number),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please dial $number from your phone.')),
      );
    }
  }

  Widget _buildHelpRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.dataMono.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSafetyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: SgText.size(13),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.outlineVariant.withValues(alpha: 0.1),
    );
  }
}
