import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_top_bar.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  String? _selectedCategory = 'Vehicle Collision';

  final List<String> _categories = [
    'Vehicle Collision',
    'Rider Misbehavior',
    'Payment Dispute',
    'Navigation Error',
    'Safety Concern',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Report Incident', showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              'Incident Category',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),

            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.surfaceContainerHigh,
                  isExpanded: true,
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            Text(
              'Incident Details',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),

            GlassPanel(
              padding: const EdgeInsets.all(12),
              child: TextField(
                maxLines: 5,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe what happened in detail...',
                  hintStyle: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incident report submitted successfully'),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  'SUBMIT INCIDENT REPORT',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
