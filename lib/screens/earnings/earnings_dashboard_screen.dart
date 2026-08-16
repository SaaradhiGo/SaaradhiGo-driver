import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() => _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  int _selectedPeriod = 2; // 0: Today, 1: This Week, 2: This Month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Earnings',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.stackMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Filters
              GlassPanel(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildFilterChip('Today', 0),
                    _buildFilterChip('This Week', 1),
                    _buildFilterChip('This Month', 2),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Main Earnings Card
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Stack(
                  children: [
                    // Glow effect
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Total Earnings (Oct)',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹12,840',
                          style: AppTypography.displayLg.copyWith(
                            color: AppColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '84',
                                    style: AppTypography.dataMono.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completed Trips',
                                    style: AppTypography.labelCaps.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '62h',
                                    style: AppTypography.dataMono.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Online Hours',
                                    style: AppTypography.labelCaps.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Graph Section (Trend)
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trend',
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Icon(
                          Icons.trending_up,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    // Chart Box
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 160),
                            painter: _TrendChartPainter(),
                          ),
                          Positioned(
                            top: 12,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Oct 24',
                                    style: AppTypography.labelCaps.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '₹1,240',
                                    style: AppTypography.dataMono.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '8 Trips',
                                    style: AppTypography.labelCaps.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(Icons.speed, '₹207', 'Avg / Hour'),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: _buildStatBox(Icons.payments, '₹4,200', 'Cash'),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: _buildStatBox(Icons.account_balance_wallet, '₹8,640', 'Digital'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),

              // Breakdown Section
              GlassPanel(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Breakdown',
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(Icons.route, 'Trip Fares', '₹9,800', isAccent: false),
                    _buildBreakdownRow(Icons.star, 'Incentives', '+₹2,500', isAccent: true),
                    _buildBreakdownRow(Icons.card_giftcard, 'Bonuses', '+₹500', isAccent: true),
                    _buildBreakdownRow(Icons.volunteer_activism, 'Tips', '₹240', isAccent: false),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                    _buildBreakdownRow(Icons.money_off, 'Adjustments', '-₹200', isError: true),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.5)) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelCaps.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      child: Column(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.dataMono.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(IconData icon, String label, String amount, {bool isAccent = false, bool isError = false}) {
    Color color = AppColors.onSurface;
    if (isAccent) color = AppColors.primary;
    if (isError) color = AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.bodyMd.copyWith(
                  color: isError ? AppColors.onSurfaceVariant : AppColors.onSurface,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: AppTypography.dataMono.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryContainer.withValues(alpha: 0.3),
          AppColors.primaryContainer.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.6)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.6, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.2);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Highlight dot
    final dotPaint = Paint()..color = AppColors.primaryContainer;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.45), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
