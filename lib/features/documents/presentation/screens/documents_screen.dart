import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/market/market_providers.dart';
import '../../../../ui/driver_documents_view.dart';
import '../../../../ui/driver_f_logic.dart';
import '../../../../ui/sg_format.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_text.dart';
import '../../../../ui/sg_tokens.dart';
import '../../../../ui/sg_widgets.dart';
import '../../../earnings/presentation/providers/tier3_providers.dart';
import '../providers/document_vault_providers.dart';

/// `/documents` (Tier 3, screen 6), from the onboarding checklist.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final docs = ref.watch(docsOverviewProvider);
    final payoutOnFile = ref.watch(payoutDetailsOnFileProvider).value;
    final vault = ref.watch(documentVaultNotifierProvider);
    final market = ref.watch(marketConfigProvider);
    final support = market.supportPhone;
    // Expiry dates come from the requirements checklist, the one list the
    // server keeps (the same items the setup screen shows).

    Future<void> refresh() async {
      ref.invalidate(docsOverviewProvider);
      ref.invalidate(payoutDetailsOnFileProvider);
      await ref
          .read(docsOverviewProvider.future)
          .catchError((_) => const DocsOverview(items: []));
    }

    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(title: Text(l.docsTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: docs.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: SgColors.gold500),
            ),
            error: (_, _) => ListView(
              padding: const EdgeInsets.all(SgSpace.s5),
              children: [
                const SizedBox(height: SgSpace.s7),
                Text(
                  l.docsLoadFailed,
                  textAlign: TextAlign.center,
                  style: SgText.title,
                ),
                const SizedBox(height: SgSpace.s4),
                SgPrimaryButton(
                  label: l.earnRetry,
                  height: kSgTouch,
                  onPressed: refresh,
                ),
              ],
            ),
            data: (overview) => DriverDocumentsView(
              overview: overview,
              expiries: {
                for (final i in overview.items)
                  if (sgMarketDateText(
                    i.expires,
                    market.countryCode,
                  ).isNotEmpty)
                    i.key: sgMarketDateText(i.expires, market.countryCode),
              },
              payoutMissing: payoutOnFile == false,
              uploadingKey: vault.isUploading
                  ? _backendKeyFor(overview, vault.uploadingDocumentKey)
                  : null,
              canOpenCamera: (item) =>
                  uploadKeyFor(item.fileKey ?? item.key) != null,
              onOpenCamera: (item) => _retake(context, ref, overview, item),
              onAddPayout: () => context.push('/onboarding/photo-bank'),
              onCallSupport: support == null
                  ? null
                  : () => launchUrl(
                      Uri(scheme: 'tel', path: support),
                      mode: LaunchMode.externalApplication,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _backendKeyFor(DocsOverview o, String? uploadKey) {
    for (final i in o.items) {
      if (uploadKeyFor(i.fileKey ?? i.key) == uploadKey) return i.key;
    }
    return null;
  }

  /// The existing upload (presigned upload, then the document key on the
  /// driver or vehicle), from the camera.
  Future<void> _retake(
    BuildContext context,
    WidgetRef ref,
    DocsOverview overview,
    DocItem item,
  ) async {
    final key = uploadKeyFor(item.fileKey ?? item.key);
    if (key == null) return;
    final l = sgL10n(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    // Only the upload needs the old onboarding data: the vehicle id.
    int? vehicleId;
    if (item.vehicle) {
      try {
        final res = await ref
            .read(dioClientProvider)
            .dio
            .get(ApiEndpoints.driverOnboarding);
        vehicleId = parseDocsOverview(res.data)?.vehicleId;
      } catch (_) {}
    }
    final ok = await ref
        .read(documentVaultNotifierProvider.notifier)
        .reuploadDocument(
          documentTypeKey: key,
          bytes: bytes,
          fileName: picked.name,
          mimeType: lookupMimeType(picked.path) ?? 'image/jpeg',
          vehicleId: vehicleId,
        );
    ref.invalidate(docsOverviewProvider);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(ok ? l.docsUploadedOk : l.docsUploadFailed),
        backgroundColor: ok ? SgColors.bg200 : SgColors.danger,
      ),
    );
  }
}
