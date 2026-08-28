import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/upload_progress_bar.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/models/picked_document.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/floating_text_field.dart';

class OnboardingLicenceScreen extends ConsumerStatefulWidget {
  const OnboardingLicenceScreen({super.key});

  @override
  ConsumerState<OnboardingLicenceScreen> createState() =>
      _OnboardingLicenceScreenState();
}

class _OnboardingLicenceScreenState
    extends ConsumerState<OnboardingLicenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();

  PickedDocument? _frontDocument;
  PickedDocument? _backDocument;

  @override
  void dispose() {
    // Stop an in-flight S3 upload when the user leaves the screen; entered
    // form data is preserved so the submission can be retried.
    ref.read(onboardingNotifierProvider.notifier).cancelUpload();
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickDoc(bool isFront) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      // Browsers do not expose a local path, so request the file bytes there.
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final file = result.files.single;
    final String? filePath = kIsWeb ? null : file.path;
    final fileBytes = file.bytes;

    if (!kIsWeb && filePath == null) return;
    if (kIsWeb && (fileBytes == null || fileBytes.isEmpty)) return;

    setState(() {
      if (isFront) {
        _frontDocument = PickedDocument(
          path: filePath,
          bytes: fileBytes,
          name: file.name,
        );
      } else {
        _backDocument = PickedDocument(
          path: filePath,
          bytes: fileBytes,
          name: file.name,
        );
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_frontDocument == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload the front of your Driving Licence'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Front is required by the contract (`license_doc`); the back is an
      // optional `license_doc_back` field ([CONFIRMED]
      // API_Documentation_V2 §3.2), sent only when picked.
      ref
          .read(onboardingNotifierProvider.notifier)
          .submitLicence(
            _numberController.text.trim(),
            _expiryController.text.trim(),
            _frontDocument!,
            backDocument: _backDocument,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingNotifierProvider, (previous, next) async {
      if (next is OnboardingStateSuccess) {
        // The route guard classifies the driver from the cached profile,
        // which was last fetched at login (before any uploads). Refetch it
        // so the redirect sees license_doc/active_vehicle and routes to
        // /verification-status instead of bouncing back to /onboarding/personal.
        // Navigate even if the refetch fails: the verification screen has a
        // manual "Refresh Status" retry.
        await ref.read(driverProfileNotifierProvider.notifier).fetchProfile();
        if (context.mounted) context.go('/verification-status');
      } else if (next is OnboardingStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final state = ref.watch(onboardingNotifierProvider);
    final isLoading =
        state is OnboardingStateLoading || state is OnboardingStateUploading;
    final uploadProgress = state is OnboardingStateUploading ? state : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Upload Documents',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      // Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'STEP 4 OF 4',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Vehicle Details',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1.0, // Step 4 of 4
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        'Driving Licence',
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please upload clear photos of your valid commercial driving licence.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      FloatingTextField(
                        label: 'Licence Number',
                        controller: _numberController,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // NOTE: Expiry date was added because the backend requires it, but the UI template did not have it.
                      FloatingTextField(
                        label: 'Expiry Date (YYYY-MM-DD)',
                        controller: _expiryController,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      _buildUploadCard(
                        'Front of Licence',
                        _frontDocument,
                        true,
                        busy: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildUploadCard(
                        'Back of Licence',
                        _backDocument,
                        false,
                        busy: isLoading,
                      ),
                      if (uploadProgress != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: UploadProgressBar(
                            progress: uploadProgress.progress,
                            label: uploadProgress.label,
                          ),
                        ),
                      ],

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.lg,
            AppSpacing.margin,
            AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: PrimaryButton(
            text: 'Continue',
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(
    String title,
    PickedDocument? document,
    bool isFront, {
    required bool busy,
  }) {
    final hasDoc = document != null && document.isAvailable;
    return GestureDetector(
      onTap: busy ? null : () => _pickDoc(isFront),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                if (hasDoc)
                  const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasDoc
                      ? AppColors.outlineVariant.withValues(alpha: 0.3)
                      : AppColors.outlineVariant,
                  style: hasDoc ? BorderStyle.solid : BorderStyle.none,
                ),
                image: hasDoc ? _previewDecoration(document) : null,
              ),
              child: !hasDoc
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.replay,
                              size: 16,
                              color: AppColors.onBackground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Retake',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _previewDecoration(PickedDocument document) {
    ImageProvider image;
    final path = document.path;
    if (!kIsWeb && path != null && path.isNotEmpty) {
      image = FileImage(File(path));
    } else if (document.bytes != null && document.bytes!.isNotEmpty) {
      image = MemoryImage(document.bytes!);
    } else {
      return null;
    }
    return DecorationImage(
      image: image,
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.4),
        BlendMode.darken,
      ),
    );
  }
}
