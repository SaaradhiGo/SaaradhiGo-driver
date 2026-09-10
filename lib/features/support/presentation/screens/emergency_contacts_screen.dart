import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/support_providers.dart';
import '../widgets/sos_widgets.dart';

/// Emergency Contacts manager (`/emergency-contacts`).
///
/// The backend contract (docs/05_API §1.4) stores a single
/// `emergency_contact` string on the user via `PATCH /auth/update/`. This screen
/// reads that value through [emergencyContactProvider] and lets the driver
/// add/edit it; saving goes through [SosNotifier.updateEmergencyContact] so the
/// value is mirrored into the authenticated user and profile immediately.
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(emergencyContactProvider);
    final sos = ref.watch(sosNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Emergency Contacts',
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
            const SosFeedbackListener(),
            const SizedBox(height: AppSpacing.sm),
            const _SavedBanner(),
            Text(
              'Trusted Contact',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This contact is notified with your live location when an SOS '
              'alert is triggered during a trip.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (contact.trim().isEmpty)
              const _NoContactCard()
            else
              _ContactCard(
                contact: contact,
                onEdit: () => _openEditSheet(context, contact),
              ),

            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              text: contact.trim().isEmpty
                  ? 'ADD EMERGENCY CONTACT'
                  : 'EDIT EMERGENCY CONTACT',
              onPressed: sos.isSavingContact
                  ? null
                  : () => _openEditSheet(context, contact),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context, String current) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(initialValue: current),
    );
    if (result == null) return;
    if (result.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a phone number to save.')),
      );
      return;
    }
    if (!mounted) return;
    await ref.read(sosNotifierProvider.notifier).updateEmergencyContact(result);
  }
}

class _SavedBanner extends ConsumerWidget {
  const _SavedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sos = ref.watch(sosNotifierProvider);
    final error = sos.errorMessage;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassPanel(
          borderColor: AppColors.error.withValues(alpha: 0.4),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error),
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
      );
    }
    return const SizedBox.shrink();
  }
}

class _NoContactCard extends StatelessWidget {
  const _NoContactCard();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            size: 40,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No emergency contact added yet',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a family member or friend so they can be reached if you '
            'trigger an SOS.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.onEdit});

  final String contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contact',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact,
                  style: AppTypography.dataMono.copyWith(
                    color: AppColors.onBackground,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit contact',
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.primaryContainer,
            ),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.initialValue});

  final String initialValue;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  late final TextEditingController _controller;
  String _validationError = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 10) {
      return 'Enter a valid phone number (min 10 digits).';
    }
    return null;
  }

  void _submit() {
    final error = _validate(_controller.text);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final sos = ref.watch(sosNotifierProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Emergency Contact',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A family member or friend we can notify during an SOS alert. '
                'They will receive your live trip location.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onBackground,
                ),
                decoration: InputDecoration(
                  hintText: '+91 98XXXXXXXX',
                  hintStyle: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  errorText: _validationError.isEmpty ? null : _validationError,
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  prefixIcon: const Icon(
                    Icons.phone_rounded,
                    color: AppColors.primaryContainer,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  if (_validationError.isNotEmpty) {
                    setState(() => _validationError = '');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'SAVE CONTACT',
                isLoading: sos.isSavingContact,
                onPressed: sos.isSavingContact ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
