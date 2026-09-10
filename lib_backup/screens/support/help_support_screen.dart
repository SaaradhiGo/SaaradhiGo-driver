import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<bool> _expandedFaqs = [false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Help Center', showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            // Search Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'How can we help you?',
                        hintStyle: AppTypography.bodyLg.copyWith(
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Help Topics Grid
            Text(
              'Help Topics',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildTopicTile(Icons.directions_car, 'Ride'),
                _buildTopicTile(Icons.payments, 'Payment'),
                _buildTopicTile(Icons.person, 'Account'),
                _buildTopicTile(Icons.local_taxi, 'Vehicle'),
                _buildTopicTile(Icons.description, 'Document'),
                _buildTopicTile(Icons.shield, 'Safety'),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Contact Support Banner
            GlassPanel(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 40,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority 24/7 Support',
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Dedicated team for Elite Partners',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Call',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // FAQs Section
            Text(
              'Frequently Asked Questions',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildFaqItem(
              index: 0,
              question: 'How do I update my payment details?',
              answer:
                  'Navigate to the Payment section in your Driver Profile. Tap on Edit Payment Method to securely update your bank details. Changes take up to 24 hours to reflect.',
            ),
            _buildFaqItem(
              index: 1,
              question: 'What happens if a rider cancels?',
              answer:
                  'If a rider cancels after 2 minutes of booking, a cancellation fee is automatically credited to your wallet.',
            ),
            _buildFaqItem(
              index: 2,
              question: 'How is my Elite tier maintained?',
              answer:
                  'Elite status requires maintaining a minimum rating of 4.8 and a 95% acceptance rate over 30 rolling days.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTile(IconData icon, String label) {
    return GlassPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required int index,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedFaqs[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        onTap: () {
          setState(() {
            _expandedFaqs[index] = !_expandedFaqs[index];
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                answer,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
