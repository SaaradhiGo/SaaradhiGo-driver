import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../providers/support_providers.dart';
import '../widgets/sos_widgets.dart';

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
        backgroundColor: AppColors.surfaceContainer,
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                onTap: sos.isRaising
                    ? null
                    : () => triggerSos(context, ref, tripId: tripId),
                child: Ink(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF93000A), Color(0xFF5C0005)],
                    ),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: sos.isRaising
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: AppColors.whiteText,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.sos,
                                color: AppColors.whiteText,
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
                                color: AppColors.whiteText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sends your live location to our 24x7 safety '
                              'team for immediate help.',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.whiteText.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 13,
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
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildHelpRow(
                    icon: Icons.phone_in_talk_rounded,
                    title: '24x7 Safety Helpline',
                    subtitle: '1800-000-0000',
                    color: AppColors.success,
                    onTap: () => _showNumberSnack(context, '1800-000-0000'),
                  ),
                  _buildDivider(),
                  _buildHelpRow(
                    icon: Icons.local_police_rounded,
                    title: 'Police (India)',
                    subtitle: 'Dial 112 / 100',
                    color: AppColors.error,
                    onTap: () => _showNumberSnack(context, '112'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety tools list.
            Text(
              'Safety Tools',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
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

  void _showNumberSnack(BuildContext context, String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calling $number from your device dialler is not wired yet. '
          'Please dial $number directly.',
        ),
      ),
    );
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
      trailing: const Icon(
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
      leading: Icon(icon, color: AppColors.primary),
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
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
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
