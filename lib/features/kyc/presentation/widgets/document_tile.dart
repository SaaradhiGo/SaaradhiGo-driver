/// One document: pick it, watch it upload, see whether it landed.
///
/// Per-document state, not a single screen-wide spinner. With seven documents
/// a driver needs to know *which* one failed, and a retry must not re-upload
/// the six that succeeded.
library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../domain/document_kind.dart';
import '../kyc_controller.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.slot,
    required this.onPick,
    required this.onRemove,
  });

  final DriverDocument document;
  final DocumentSlot slot;
  final void Function(ImageSource source) onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('doc_card_${document.kind}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        document.hint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                _StatusPill(slot: slot),
              ],
            ),
            if (slot.state == UploadState.uploading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                key: Key('doc_progress_${document.kind}'),
                value: slot.progress > 0 ? slot.progress : null,
              ),
            ],
            if (slot.state == UploadState.failed && slot.error != null) ...[
              const SizedBox(height: 10),
              Text(
                slot.error!,
                key: Key('doc_error_${document.kind}'),
                style: const TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (slot.state != UploadState.uploading) ...[
                  TextButton.icon(
                    key: Key('doc_camera_${document.kind}'),
                    onPressed: () => onPick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(
                      slot.isUploaded ? 'Retake' : 'Camera',
                    ),
                  ),
                  TextButton.icon(
                    key: Key('doc_gallery_${document.kind}'),
                    onPressed: () => onPick(ImageSource.gallery),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Gallery'),
                  ),
                ],
                const Spacer(),
                if (slot.isUploaded)
                  IconButton(
                    key: Key('doc_remove_${document.kind}'),
                    tooltip: 'Remove',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.slot});

  final DocumentSlot slot;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (slot.state) {
      UploadState.empty => ('Needed', AppTheme.warning),
      UploadState.uploading => ('Uploading', Colors.white70),
      // "Uploaded", not "Verified". The document is in S3 and awaiting an
      // operator; telling a driver it is verified would be a lie they would
      // act on by trying to go online.
      UploadState.uploaded => ('Uploaded', AppTheme.brand),
      UploadState.failed => ('Failed', AppTheme.danger),
    };

    return Container(
      key: Key('doc_status_${slot.state.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
