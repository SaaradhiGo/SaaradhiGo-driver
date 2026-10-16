/// The driver's own documents: licence front and back.
///
/// First half of onboarding. The second half is the vehicle and its papers,
/// which is [VehicleRegistrationScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../domain/document_kind.dart';
import 'kyc_controller.dart';
import 'widgets/document_tile.dart';

class DocumentUploadScreen extends ConsumerWidget {
  const DocumentUploadScreen({super.key});

  static const String routePath = '/kyc/documents';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycControllerProvider);
    final controller = ref.read(kycControllerProvider.notifier);
    final documents = DriverDocument.driverDocuments;

    final ready = documents.every((d) => state.slot(d).isUploaded);

    return Scaffold(
      appBar: AppBar(title: const Text('Your documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Intro(
            text: 'Photograph both sides of your driving licence. Our team '
                'reviews it, usually within a working day. You cannot go '
                'online until it is approved.',
          ),
          const SizedBox(height: 12),
          for (final document in documents) ...[
            DocumentTile(
              document: document,
              slot: state.slot(document),
              onPick: (source) =>
                  controller.pickAndUpload(document, source: source),
              onRemove: () => controller.remove(document),
            ),
            const SizedBox(height: 10),
          ],
          if (state.submitError != null) ...[
            const SizedBox(height: 6),
            Text(
              state.submitError!,
              key: const Key('kyc_submit_error'),
              style: const TextStyle(color: AppTheme.danger),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('kyc_submit_documents'),
            // Disabled while an upload is in flight: submitting now would send
            // the keys that happen to exist and silently omit the rest.
            onPressed: ready && !state.submitting && !state.anyUploading
                ? () async {
                    final ok = await controller.submitDriverDocuments();
                    if (!ok || !context.mounted) return;
                    context.go(VehicleRegistrationRoute.path);
                  }
                : null,
            child: state.submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit for review'),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Do this later'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Route constants kept together so the router and the screens cannot drift.
class VehicleRegistrationRoute {
  const VehicleRegistrationRoute._();
  static const String path = '/kyc/vehicle';
}
