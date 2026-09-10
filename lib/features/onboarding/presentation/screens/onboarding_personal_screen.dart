import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/upload_progress_bar.dart';
import '../../data/models/picked_document.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/floating_text_field.dart';
import '../widgets/onboarding_progress_indicator.dart';

class OnboardingPersonalScreen extends ConsumerStatefulWidget {
  const OnboardingPersonalScreen({super.key});

  @override
  ConsumerState<OnboardingPersonalScreen> createState() =>
      _OnboardingPersonalScreenState();
}

class _OnboardingPersonalScreenState
    extends ConsumerState<OnboardingPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedCity;

  final List<String> _cities = [
    'Mumbai',
    'New Delhi',
    'Bangalore',
    'Hyderabad',
  ];

  static const List<String> _genders = ['Male', 'Female', 'Other'];
  String? _selectedGender;

  String? _avatarPath;
  PickedDocument? _avatarDocument;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    // Stop an in-flight S3 upload when the user leaves the screen; entered
    // form data is preserved so the submission can be retried.
    ref.read(onboardingNotifierProvider.notifier).cancelUpload();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Downscale/compress before upload to keep upload payloads small.
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() {
        // On web `image.path` is a blob: URL that NetworkImage can render;
        // bytes for the upload are loaded lazily via readAsBytes().
        _avatarPath = image.path;
        _avatarDocument = PickedDocument(
          path: kIsWeb ? null : image.path,
          name: image.name,
          loadBytes: image.readAsBytes,
        );
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      _showError('Please select a city');
      return;
    }
    if (_selectedGender == null) {
      _showError('Please select your gender');
      return;
    }
    if (_avatarDocument == null) {
      _showError('Please upload a profile photo');
      return;
    }
    // `gender` accepts exactly 'male' | 'female' | 'other' (lowercase),
    // confirmed by the backend for `PATCH /auth/update/` (§1.4).
    final data = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'gender': _selectedGender!.toLowerCase(),
      'city': _selectedCity,
    };
    ref
        .read(onboardingNotifierProvider.notifier)
        .submitPersonalDetails(data, avatar: _avatarDocument);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingNotifierProvider, (previous, next) {
      if (next is OnboardingStateSuccess) {
        context.push('/onboarding/vehicle');
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
    final isLoading = state is OnboardingStateLoading;
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
                      const OnboardingProgressIndicator(currentStep: 1),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Personal Details',
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Let\'s start with your basic information.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildAvatarPicker(),
                      const SizedBox(height: AppSpacing.xl),
                      FloatingTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FloatingTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCityDropdown(),
                      const SizedBox(height: AppSpacing.md),
                      _buildGenderSelector(),
                      if (uploadProgress != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        UploadProgressBar(
                          progress: uploadProgress.progress,
                          label: uploadProgress.label,
                        ),
                      ],
                      const SizedBox(height: 120), // padding for bottom button
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
            color: AppColors.background,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.9),
                AppColors.background.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: PrimaryButton(
            text: 'Next',
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCity,
        hint: Text(
          'City',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        icon: const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
        dropdownColor: AppColors.surfaceContainer,
        style: AppTypography.bodyLg.copyWith(color: AppColors.onBackground),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        items: _cities.map((city) {
          return DropdownMenuItem(value: city, child: Text(city));
        }).toList(),
        onChanged: (val) {
          setState(() => _selectedCity = val);
        },
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(
              color: _avatarPath != null
                  ? AppColors.primary
                  : AppColors.outlineVariant,
              width: 2,
            ),
            image: _avatarPath != null
                ? DecorationImage(
                    image: kIsWeb
                        ? NetworkImage(_avatarPath!) as ImageProvider
                        : FileImage(File(_avatarPath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _avatarPath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo,
                      color: AppColors.onSurfaceVariant,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: _genders
              .map(
                (gender) =>
                    ButtonSegment<String>(value: gender, label: Text(gender)),
              )
              .toList(),
          selected: _selectedGender == null ? const {} : {_selectedGender!},
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.surfaceContainer,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.darkText
                  : AppColors.onSurfaceVariant,
            ),
            side: const WidgetStatePropertyAll(
              BorderSide(color: AppColors.outlineVariant),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              setState(() => _selectedGender = selection.first);
            }
          },
        ),
      ],
    );
  }
}
