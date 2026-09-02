import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/trip_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../providers/support_providers.dart';

/// Report an Incident (`/report-incident`).
///
/// Submits a new support ticket for the chosen category via
/// [SupportTicketsNotifier.submitTicket] (backend: `POST /support/tickets/`).
/// On success the screen navigates to the freshly created ticket thread so the
/// driver can track the report and reply if needed.
class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  static const List<String> _categories = [
    'Vehicle Collision',
    'Rider Misbehavior',
    'Payment Dispute',
    'Safety Concern',
    'Navigation / App Issue',
    'Other',
  ];

  String? _category = _categories.first;
  final TextEditingController _description = TextEditingController();
  String _errorText = '';

  int? get _tripId {
    final session = ref.read(tripSessionNotifierProvider);
    final status = session.status;
    if (status == null || status.isTerminal) return null;
    return session.trip?.id;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final category = _category;
    final description = _description.text.trim();
    if (category == null || description.isEmpty) {
      setState(() => _errorText = 'Please describe what happened.');
      return;
    }
    FocusScope.of(context).unfocus();
    ref
        .read(supportTicketsNotifierProvider.notifier)
        .submitTicket(
          category: category,
          subject: category,
          description: description,
          tripId: _tripId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportTicketsNotifierProvider);
    final error = state.errorMessage;

    // Navigate to the new thread after a successful submit.
    final createdId = state.createdTicketId;
    if (createdId != null && createdId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(supportTicketsNotifierProvider.notifier).clearCreatedTicket();
        context.push('/support/ticket/$createdId');
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Report an Incident',
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
            if (error != null) ...[
              GlassPanel(
                borderColor: AppColors.error.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        error,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            Text(
              'Incident Category',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceContainerHigh,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.primaryContainer,
                  ),
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onBackground,
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _category = value),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Incident Details',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassPanel(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _description,
                maxLines: 6,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onBackground,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe what happened in detail…',
                  hintStyle: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  errorText: _errorText.isEmpty ? null : _errorText,
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  if (_errorText.isNotEmpty) {
                    setState(() => _errorText = '');
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _tripId == null
                  ? 'Submitted as a general report (no active trip).'
                  : 'This report will be linked to your active trip #$_tripId.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              text: 'SUBMIT INCIDENT REPORT',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
