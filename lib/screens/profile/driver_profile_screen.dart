import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../services/auth_service.dart';
import '../../navigation/route_names.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Account Suite',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.stackLg,
          ),
          child: Column(
            children: [
              // Profile Header Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryContainer.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            backgroundColor: AppColors.surfaceVariant,
                            child: Icon(Icons.person, size: 50, color: AppColors.primary),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Vikram Singh',
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'ELITE PARTNER',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Metrics Bento Grid
              Row(
                children: [
                  Expanded(
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '4.98',
                                style: AppTypography.dataMono.copyWith(
                                  color: AppColors.primaryFixed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rating',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
                      child: Column(
                        children: [
                          Text(
                            '8,420',
                            style: AppTypography.dataMono.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Trips',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
                      child: Column(
                        children: [
                          Text(
                            'Jan \'20',
                            style: AppTypography.dataMono.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Since',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Personal Information Card
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.stackMd,
                        vertical: AppSpacing.stackSm + 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Personal Details',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildInfoRow('Mobile', '+91 98765 43210', isMono: true),
                    _buildInfoRow('Email', 'vikram.s@saaradhi.go'),
                    _buildInfoRow('D.O.B', '12/05/1985', isMono: true),
                    _buildInfoRow('Registered Address', 'Bandra West, Mumbai\nMaharashtra, 400050', isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Quick Actions List
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildActionItem(
                      icon: Icons.description,
                      title: 'Vehicle Documents',
                      onTap: () => Navigator.pushNamed(context, RouteNames.documentVault),
                    ),
                    _buildDivider(),
                    _buildActionItem(
                      icon: Icons.directions_car,
                      title: 'Vehicle Details',
                      onTap: () => Navigator.pushNamed(context, RouteNames.vehicleInfo),
                    ),
                    _buildDivider(),
                    _buildActionItem(
                      icon: Icons.security,
                      title: 'Safety Center',
                      onTap: () => Navigator.pushNamed(context, RouteNames.safetyCenter),
                    ),
                    _buildDivider(),
                    _buildActionItem(
                      icon: Icons.help,
                      title: 'Help & Support',
                      onTap: () => Navigator.pushNamed(context, RouteNames.helpSupport),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMono = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: isMono
                ? AppTypography.dataMono.copyWith(color: AppColors.onSurface)
                : AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          'Log Out',
          style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
        ),
        content: Text(
          'Are you sure you want to log out of SaaradhiGo?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
              }
            },
            child: Text(
              'Log Out',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
