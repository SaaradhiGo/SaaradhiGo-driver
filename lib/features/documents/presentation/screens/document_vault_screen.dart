import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/driver_document_model.dart';
import '../../../../shared/widgets/app_server_image.dart';
import '../../../../shared/widgets/bottom_sheet_container.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../providers/document_vault_providers.dart';

class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  ConsumerState<DocumentVaultScreen> createState() =>
      _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentVaultNotifierProvider.notifier).fetchDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentVaultNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        title: Text(
          'Compliance Hub',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
            onPressed: () => ref
                .read(documentVaultNotifierProvider.notifier)
                .fetchDocuments(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () => ref
              .read(documentVaultNotifierProvider.notifier)
              .fetchDocuments(refresh: true),
          child: _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DocumentVaultState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasError && state.documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 54,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load compliance documents',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.errorMessage ??
                    'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Retry',
                onPressed: () => ref
                    .read(documentVaultNotifierProvider.notifier)
                    .fetchDocuments(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: AppColors.onSurfaceVariant,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No Documents Found',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your uploaded compliance documents will appear here.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                text: 'Refresh',
                onPressed: () => ref
                    .read(documentVaultNotifierProvider.notifier)
                    .fetchDocuments(refresh: true),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.margin),
      children: [
        // Subtitle
        Text(
          'Document Management Vault',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your official regulatory certificates and verification records.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Bento Overview Grid
        _buildBentoOverview(state),
        const SizedBox(height: AppSpacing.lg),

        // Upload progress banner if actively uploading
        if (state.isUploading) ...[
          _buildUploadProgressCard(state),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Document Cards List
        for (final doc in state.documents) ...[
          _buildDocumentCard(context, doc, state),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBentoOverview(DocumentVaultState state) {
    final total = state.documents.length;
    final verified = state.verifiedCount;
    final actionReq = state.actionRequiredCount;

    return Row(
      children: [
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$verified/$total',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'VERIFIED',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              children: [
                Icon(
                  actionReq > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: actionReq > 0 ? AppColors.error : AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$actionReq',
                  style: AppTypography.headlineSm.copyWith(
                    color: actionReq > 0 ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ACTION REQ',
                  style: AppTypography.labelCaps.copyWith(
                    color: actionReq > 0
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgressCard(DocumentVaultState state) {
    final pct = (state.uploadProgress * 100).toInt();
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uploading document to S3…',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$pct%',
                style: AppTypography.dataMono.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: state.uploadProgress > 0 ? state.uploadProgress : null,
            backgroundColor: AppColors.surfaceContainerHigh,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    DriverDocumentModel doc,
    DocumentVaultState state,
  ) {
    Color indicatorColor;
    Color badgeBg;
    Color badgeTextColor;
    IconData badgeIcon;

    switch (doc.status) {
      case DocumentStatus.verified:
        indicatorColor = const Color(0xFF4ADE80);
        badgeBg = const Color(0xFF4ADE80).withValues(alpha: 0.15);
        badgeTextColor = const Color(0xFF4ADE80);
        badgeIcon = Icons.check_circle_rounded;
      case DocumentStatus.pending:
        indicatorColor = const Color(0xFFF97316);
        badgeBg = const Color(0xFFF97316).withValues(alpha: 0.15);
        badgeTextColor = const Color(0xFFF97316);
        badgeIcon = Icons.pending_rounded;
      case DocumentStatus.renewalDue:
        indicatorColor = Colors.amber;
        badgeBg = Colors.amber.withValues(alpha: 0.15);
        badgeTextColor = Colors.amber;
        badgeIcon = Icons.warning_amber_rounded;
      case DocumentStatus.expired:
      case DocumentStatus.rejected:
        indicatorColor = AppColors.error;
        badgeBg = AppColors.error.withValues(alpha: 0.15);
        badgeTextColor = AppColors.error;
        badgeIcon = Icons.cancel_rounded;
      case DocumentStatus.missing:
        indicatorColor = AppColors.onSurfaceVariant;
        badgeBg = AppColors.surfaceContainerHigh;
        badgeTextColor = AppColors.onSurfaceVariant;
        badgeIcon = Icons.help_outline_rounded;
    }

    final hasFile = doc.fileUrl != null && doc.fileUrl!.trim().isNotEmpty;
    final expiryFormatted = doc.expiryDate != null
        ? 'Exp: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}'
        : 'No Expiry Date';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: doc.status.isActionRequired
            ? Border.all(color: indicatorColor.withValues(alpha: 0.4))
            : null,
      ),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Stack(
            children: [
              // Left status indicator bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(color: indicatorColor),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    // Icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: indicatorColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getDocIcon(doc.documentTypeKey),
                        color: indicatorColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Title & info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onBackground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      badgeIcon,
                                      size: 12,
                                      color: badgeTextColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      doc.status.label,
                                      style: AppTypography.labelCaps.copyWith(
                                        color: badgeTextColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                expiryFormatted,
                                style: AppTypography.dataMono.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Action button
                    if (hasFile && !doc.status.isActionRequired) ...[
                      IconButton(
                        tooltip: 'View Document',
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _showDocumentPreview(context, doc),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: Text(
                          hasFile ? 'Re-upload' : 'Upload',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showReuploadSheet(context, doc),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocIcon(String key) {
    if (key.contains('license')) return Icons.badge_outlined;
    if (key.contains('rc')) return Icons.directions_car_outlined;
    if (key.contains('insurance')) return Icons.health_and_safety_outlined;
    if (key.contains('fitness') || key.contains('permit')) {
      return Icons.assignment_turned_in_outlined;
    }
    return Icons.description_outlined;
  }

  void _showDocumentPreview(BuildContext context, DriverDocumentModel doc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: GlassPanel(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.title,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: doc.fileUrl != null
                        ? AppServerImage(url: doc.fileUrl!, fit: BoxFit.contain)
                        : const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doc.expiryDate != null
                        ? 'Expires: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}'
                        : 'No Expiration Specified',
                    style: AppTypography.dataMono.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Update'),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _showReuploadSheet(context, doc);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReuploadSheet(BuildContext context, DriverDocumentModel doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BottomSheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: Text(
                'Upload ${doc.title}',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: Text(
                'Please ensure the photo is clear, readable, and properly lit without blur or glare.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                'Take Photo',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Use camera to capture document',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAndUpload(doc, ImageSource.camera);
              },
            ),
            const Divider(color: AppColors.surfaceContainerHigh),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Select existing photo from device',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAndUpload(doc, ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    DriverDocumentModel doc,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final mimeType = lookupMimeType(picked.path) ?? 'image/jpeg';

    final success = await ref
        .read(documentVaultNotifierProvider.notifier)
        .reuploadDocument(
          documentTypeKey: doc.documentTypeKey,
          bytes: bytes,
          fileName: picked.name,
          mimeType: mimeType,
          expiryDate: doc.expiryDate,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${doc.title} uploaded successfully.'
                : 'Upload failed. Please try again.',
          ),
          backgroundColor: success
              ? AppColors.surfaceContainerHigh
              : AppColors.error,
        ),
      );
    }
  }
}
