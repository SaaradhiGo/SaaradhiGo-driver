import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
import '../../data/models/vehicle_request_dto.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/floating_text_field.dart';
import '../widgets/onboarding_progress_indicator.dart';

class OnboardingVehicleScreen extends ConsumerStatefulWidget {
  const OnboardingVehicleScreen({super.key});

  @override
  ConsumerState<OnboardingVehicleScreen> createState() =>
      _OnboardingVehicleScreenState();
}

class _OnboardingVehicleScreenState
    extends ConsumerState<OnboardingVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  String _selectedVehicleType = 'sedan';
  final List<String> _vehicleTypes = [
    'sedan',
    'suv',
    'hatchback',
    'bike',
    'auto',
  ];

  PickedDocument? _rcDocument;
  PickedDocument? _vehiclePicDocument;
  String? _vehiclePicPath;
  final ImagePicker _picker = ImagePicker();
  bool _setActiveVehicle = true;

  bool get _hasRcDoc => _rcDocument != null;
  bool get _hasVehiclePic => _vehiclePicDocument != null;

  @override
  void dispose() {
    // Stop an in-flight S3 upload when the user leaves the screen; entered
    // form data is preserved so the submission can be retried.
    ref.read(onboardingNotifierProvider.notifier).cancelUpload();
    _makeController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickVehiclePic() async {
    // Contract allows images only for `vehicle_pic` (JPG/PNG/WebP/GIF);
    // downscale/compress before upload to keep payloads small.
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
        _vehiclePicPath = image.path;
        _vehiclePicDocument = PickedDocument(
          path: kIsWeb ? null : image.path,
          name: image.name,
          loadBytes: image.readAsBytes,
        );
      });
    }
  }

  Future<void> _pickRcDoc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      // Browsers do not expose a local path, so request the file bytes there.
      withData: kIsWeb,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final String? filePath = kIsWeb ? null : file.path;
    final fileBytes = file.bytes;

    if (!kIsWeb && filePath == null) return;
    if (kIsWeb && (fileBytes == null || fileBytes.isEmpty)) return;

    setState(() {
      _rcDocument = PickedDocument(
        path: filePath,
        bytes: fileBytes,
        name: file.name,
      );
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!_hasRcDoc) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload RC Document'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final vehicleDto = VehicleRequestDto(
        registrationNumber: _plateController.text.trim(),
        vehicleType: _selectedVehicleType,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
        color: _colorController.text.trim(),
        rcDocument: _rcDocument,
        vehiclePicDocument: _vehiclePicDocument,
        setAsActive: _setActiveVehicle,
      );

      ref.read(onboardingNotifierProvider.notifier).submitVehicle(vehicleDto);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingNotifierProvider, (previous, next) {
      if (next is OnboardingStateSuccess) {
        context.push('/onboarding/photo-bank');
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
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'SaaradhiGo',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
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
                      Text(
                        'Vehicle Setup',
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Step 2 of 3: Details & Documents',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const OnboardingProgressIndicator(currentStep: 2),
                      const SizedBox(height: AppSpacing.xl),

                      // Vehicle Details Section
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Vehicle Details',
                              style: AppTypography.headlineSm.copyWith(
                                color: AppColors.onBackground,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildVehicleTypeDropdown(),
                            const SizedBox(height: AppSpacing.md),
                            FloatingTextField(
                              label: 'Vehicle Make (e.g. Maruti)',
                              controller: _makeController,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FloatingTextField(
                              label: 'Vehicle Model (e.g. Swift)',
                              controller: _modelController,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FloatingTextField(
                              label: 'License Plate Number',
                              controller: _plateController,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FloatingTextField(
                              label: 'Registration Year',
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FloatingTextField(
                              label: 'Vehicle Color',
                              controller: _colorController,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Documents Section
                      Text(
                        'Required Documents',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // RC Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: _hasRcDoc
                                ? AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  )
                                : AppColors.primary.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _hasRcDoc
                                        ? AppColors.primaryContainer.withValues(
                                            alpha: 0.2,
                                          )
                                        : AppColors.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.description,
                                    color: _hasRcDoc
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Registration Certificate (RC)',
                                        style: AppTypography.headlineSm
                                            .copyWith(
                                              color: AppColors.onBackground,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            _hasRcDoc
                                                ? Icons.check_circle
                                                : Icons.pending,
                                            size: 16,
                                            color: _hasRcDoc
                                                ? AppColors.primary
                                                : AppColors.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _hasRcDoc
                                                ? 'Verified'
                                                : 'Upload Required',
                                            style: AppTypography.labelCaps
                                                .copyWith(
                                                  color: _hasRcDoc
                                                      ? AppColors.primary
                                                      : AppColors.error,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: isLoading ? null : _pickRcDoc,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _hasRcDoc
                                        ? AppColors.surfaceContainer
                                        : AppColors.primary,
                                    foregroundColor: _hasRcDoc
                                        ? AppColors.onSurfaceVariant
                                        : AppColors.darkText,
                                    minimumSize: const Size(
                                      0,
                                      AppSpacing.touchTarget,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(_hasRcDoc ? 'Edit' : 'Upload'),
                                ),
                              ],
                            ),
                            if (uploadProgress != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              UploadProgressBar(
                                progress: uploadProgress.progress,
                                label: uploadProgress.label,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Vehicle Photo Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: _hasVehiclePic
                                ? AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  )
                                : AppColors.primary.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _hasVehiclePic
                                    ? AppColors.primaryContainer.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                                image: _hasVehiclePic && _vehiclePicPath != null
                                    ? DecorationImage(
                                        image: kIsWeb
                                            ? NetworkImage(_vehiclePicPath!)
                                                  as ImageProvider
                                            : FileImage(File(_vehiclePicPath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: _hasVehiclePic
                                  ? null
                                  : const Icon(
                                      Icons.directions_car,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicle Photo',
                                    style: AppTypography.headlineSm.copyWith(
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        _hasVehiclePic
                                            ? Icons.check_circle
                                            : Icons.info_outline,
                                        size: 16,
                                        color: _hasVehiclePic
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _hasVehiclePic ? 'Added' : 'Optional',
                                        style: AppTypography.labelCaps.copyWith(
                                          color: _hasVehiclePic
                                              ? AppColors.primary
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isLoading ? null : _pickVehiclePic,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasVehiclePic
                                    ? AppColors.surfaceContainer
                                    : AppColors.primary,
                                foregroundColor: _hasVehiclePic
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.darkText,
                                minimumSize: const Size(
                                  0,
                                  AppSpacing.touchTarget,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(_hasVehiclePic ? 'Edit' : 'Upload'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Active Vehicle Selector
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: _setActiveVehicle,
                          onChanged: isLoading
                              ? null
                              : (value) => setState(
                                  () => _setActiveVehicle = value ?? true,
                                ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                          checkColor: AppColors.darkText,
                          title: Text(
                            'Set as my active vehicle',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onBackground,
                            ),
                          ),
                          subtitle: Text(
                            'Rides will be assigned to this vehicle.',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),

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

  Widget _buildVehicleTypeDropdown() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedVehicleType,
        icon: const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
        dropdownColor: AppColors.surfaceContainer,
        style: AppTypography.bodyLg.copyWith(color: AppColors.onBackground),
        decoration: InputDecoration(
          labelText: 'Vehicle Type',
          labelStyle: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        items: _vehicleTypes.map((type) {
          return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedVehicleType = val);
          }
        },
      ),
    );
  }
}
