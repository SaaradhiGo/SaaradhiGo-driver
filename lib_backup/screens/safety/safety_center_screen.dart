import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../navigation/route_names.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Safety Center', showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            // SOS Emergency Banner Card
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              backgroundColor: AppColors.errorContainer.withValues(alpha: 0.3),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: AppColors.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sos,
                      color: AppColors.onErrorContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency SOS',
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          'Press for immediate police & ambulance assistance',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Safety Tools
            Text(
              'Safety Tools',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),

            GlassPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSafetyTile(
                    icon: Icons.contacts,
                    title: 'Emergency Contacts',
                    subtitle: 'Manage trusted contacts notified during SOS',
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteNames.emergencyContacts,
                    ),
                  ),
                  _buildDivider(),
                  _buildSafetyTile(
                    icon: Icons.report_problem,
                    title: 'Report an Incident',
                    subtitle: 'Report safety concerns or crashes',
                    onTap: () =>
                        Navigator.pushNamed(context, RouteNames.reportIncident),
                  ),
                  _buildDivider(),
                  _buildSafetyTile(
                    icon: Icons.share_location,
                    title: 'Share Trip Status',
                    subtitle: 'Share live GPS location with family',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        style: AppTypography.bodyLg.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
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
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.05));
  }
}
