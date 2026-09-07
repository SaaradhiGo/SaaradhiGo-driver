import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/upload_progress_bar.dart';
import '../../../onboarding/data/models/picked_document.dart';
import '../../../onboarding/data/models/vehicle_request_dto.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/vehicle_info_providers.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
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
    'auto',
    'bike',
  ];

  PickedDocument? _rcDocument;
  PickedDocument? _vehiclePicDocument;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String? _uploadStageMessage;
  String? _errorMessage;

  bool get _isDirty =>
      _makeController.text.trim().isNotEmpty ||
      _modelController.text.trim().isNotEmpty ||
      _plateController.text.trim().isNotEmpty ||
      _yearController.text.trim().isNotEmpty ||
      _colorController.text.trim().isNotEmpty ||
      _rcDocument != null ||
      _vehiclePicDocument != null;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return false;
    if (!_isDirty) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        title: Text(
          'Discard Changes?',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        content: Text(
          'You have unsaved vehicle information. Are you sure you want to leave?',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Editing',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Discard',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  Future<void> _handlePop() async {
    final shouldPop = await _onWillPop();
    if (!mounted) return;
    if (shouldPop) {
      context.pop();
    }
  }

  Future<void> _pickRcDoc() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
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
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick RC document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickVehiclePic() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _vehiclePicDocument = PickedDocument(
            path: kIsWeb ? null : image.path,
            name: image.name,
            loadBytes: image.readAsBytes,
          );
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick vehicle photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_rcDocument == null) {
      setState(() {
        _errorMessage = 'Registration Certificate (RC) document is required.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.05;
      _uploadStageMessage = 'Preparing vehicle documents...';
      _errorMessage = null;
    });

    try {
      final dto = VehicleRequestDto(
        registrationNumber: _plateController.text.trim().toUpperCase(),
        vehicleType: _selectedVehicleType,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
        color: _colorController.text.trim(),
        rcDocument: _rcDocument,
        vehiclePicDocument: _vehiclePicDocument,
        setAsActive: true,
      );

      final repo = ref.read(vehiclesRepositoryProvider);

      setState(() {
        _uploadStageMessage = 'Uploading documents to secure S3 vault...';
      });

      await repo.addVehicle(
        dto,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() {
              _uploadProgress = 0.1 + (sent / total) * 0.7;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _uploadProgress = 0.9;
        _uploadStageMessage = 'Synchronizing driver profile & fleet...';
      });

      // Synchronize profile and fleet state across app
      await Future.wait([
        ref.read(driverProfileNotifierProvider.notifier).fetchProfile(),
        ref
            .read(vehicleInfoNotifierProvider.notifier)
            .fetchVehicleInfo(refresh: true),
      ]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Vehicle successfully registered and set as active.',
                  style: TextStyle(color: AppColors.onBackground),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.primary),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
        _uploadStageMessage = null;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty && !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceContainer,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.onBackground,
            ),
            onPressed: _handlePop,
          ),
          title: Text(
            'Add New Vehicle',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onBackground,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.margin),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Headline & Description
                  Text(
                    'Vehicle Details',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a new vehicle to your SaaradhiGo fleet. It will be set as your active vehicle upon approval.',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Error Banner if present
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Vehicle Type Selector
                  Text(
                    'CATEGORY / TYPE',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _vehicleTypes.map((type) {
                      final isSelected = _selectedVehicleType == type;
                      return ChoiceChip(
                        label: Text(
                          type.toUpperCase(),
                          style: AppTypography.labelCaps.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryContainer.withValues(
                          alpha: 0.2,
                        ),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outlineVariant.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        onSelected: _isSubmitting
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() => _selectedVehicleType = type);
                                }
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Inputs Section
                  _buildInputField(
                    label: 'Brand / Make',
                    hint: 'e.g. Maruti Suzuki, Hyundai',
                    controller: _makeController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Brand is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildInputField(
                    label: 'Model Name',
                    hint: 'e.g. Dzire, WagonR, Creta',
                    controller: _modelController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Model is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildInputField(
                    label: 'License Plate / Registration Number',
                    hint: 'e.g. TS09AB1234',
                    controller: _plateController,
                    isMono: true,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'License plate number is required';
                      }
                      if (v.trim().length < 6) {
                        return 'Enter a valid license plate number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'Year',
                          hint: '2023',
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            final year = int.tryParse(v.trim());
                            if (year == null ||
                                year < 2000 ||
                                year > DateTime.now().year + 1) {
                              return 'Invalid year';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildInputField(
                          label: 'Exterior Color',
                          hint: 'White, Silver, Black',
                          controller: _colorController,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Documents Section
                  Text(
                    'VEHICLE DOCUMENTS',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // RC Document Uploader
                  _buildDocumentCard(
                    title: 'Registration Certificate (RC)',
                    subtitle: 'PDF or clear image of original RC booklet/card',
                    isRequired: true,
                    document: _rcDocument,
                    onPick: _pickRcDoc,
                    onClear: () => setState(() => _rcDocument = null),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Vehicle Photo Uploader
                  _buildDocumentCard(
                    title: 'Vehicle Front/Side Photo',
                    subtitle: 'Clear daylight photo of the vehicle (Optional)',
                    isRequired: false,
                    document: _vehiclePicDocument,
                    onPick: _pickVehiclePic,
                    onClear: () => setState(() => _vehiclePicDocument = null),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submission Progress Bar if submitting
                  if (_isSubmitting) ...[
                    UploadProgressBar(
                      progress: _uploadProgress,
                      label: _uploadStageMessage,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Action Buttons
                  PrimaryButton(
                    text: 'Register & Set Active Vehicle',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    text: 'Cancel',
                    onPressed: _isSubmitting ? null : _handlePop,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isMono = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !_isSubmitting,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: isMono
              ? AppTypography.dataMono.copyWith(color: AppColors.onBackground)
              : AppTypography.bodyLg.copyWith(color: AppColors.onBackground),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margin,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required bool isRequired,
    required PickedDocument? document,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final hasDoc = document != null;

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDoc
                    ? Icons.check_circle_rounded
                    : Icons.file_upload_outlined,
                color: hasDoc ? const Color(0xFF4ADE80) : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isRequired
                      ? AppColors.pendingContainer.withValues(alpha: 0.2)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: isRequired
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  isRequired ? 'Required' : 'Optional',
                  style: AppTypography.labelCaps.copyWith(
                    color: isRequired
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasDoc) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attachment_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      document.name ?? 'Document',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  if (!_isSubmitting)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      onPressed: onClear,
                      tooltip: 'Remove file',
                    ),
                ],
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(isRequired ? 'Upload Document' : 'Upload Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: _isSubmitting ? null : onPick,
            ),
          ],
        ],
      ),
    );
  }
}
