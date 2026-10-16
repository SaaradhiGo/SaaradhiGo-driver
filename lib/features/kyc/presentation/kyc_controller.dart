/// Holds one KYC submission while a driver works through it.
///
/// A document upload is three steps and the middle one is slow, so state has
/// to survive the driver backing out of a picker, switching apps, and losing
/// signal halfway. Each document therefore carries its own [UploadState] and
/// its own error, rather than the screen having a single "loading" flag that
/// hides which of seven documents failed.
///
/// Uploaded keys are kept in memory and submitted together. That is deliberate:
/// the vehicle endpoint creates the vehicle AND attaches its documents in one
/// request, so a key is useless until the driver has entered the registration
/// number too.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/upload_client.dart';
import '../../../core/providers.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/document_kind.dart';

@immutable
class DocumentSlot {
  const DocumentSlot({
    this.state = UploadState.empty,
    this.key,
    this.localPath,
    this.progress = 0,
    this.error,
  });

  final UploadState state;

  /// The S3 key, once uploaded. This is what gets submitted.
  final String? key;

  /// The picked file, for a thumbnail. Not sent anywhere.
  final String? localPath;
  final double progress;
  final String? error;

  bool get isUploaded => state == UploadState.uploaded && key != null;

  DocumentSlot copyWith({
    UploadState? state,
    String? key,
    String? localPath,
    double? progress,
    String? error,
    bool clearError = false,
  }) =>
      DocumentSlot(
        state: state ?? this.state,
        key: key ?? this.key,
        localPath: localPath ?? this.localPath,
        progress: progress ?? this.progress,
        error: clearError ? null : (error ?? this.error),
      );
}

@immutable
class KycState {
  const KycState({
    this.slots = const {},
    this.submitting = false,
    this.submitError,
    this.submitted = false,
  });

  final Map<DriverDocument, DocumentSlot> slots;
  final bool submitting;
  final String? submitError;
  final bool submitted;

  DocumentSlot slot(DriverDocument doc) =>
      slots[doc] ?? const DocumentSlot();

  /// Keys ready to submit, by document.
  Map<DriverDocument, String> get uploadedKeys => {
        for (final entry in slots.entries)
          if (entry.value.isUploaded) entry.key: entry.value.key!,
      };

  bool get anyUploading =>
      slots.values.any((s) => s.state == UploadState.uploading);

  KycState copyWith({
    Map<DriverDocument, DocumentSlot>? slots,
    bool? submitting,
    String? submitError,
    bool? submitted,
    bool clearSubmitError = false,
  }) =>
      KycState(
        slots: slots ?? this.slots,
        submitting: submitting ?? this.submitting,
        submitError:
            clearSubmitError ? null : (submitError ?? this.submitError),
        submitted: submitted ?? this.submitted,
      );
}

class KycController extends Notifier<KycState> {
  KycController({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  late UploadClient _uploads;
  late KycRepository _repository;

  @override
  KycState build() {
    _uploads = ref.watch(uploadClientProvider);
    _repository = ref.watch(kycRepositoryProvider);
    return const KycState();
  }

  /// Pick and upload one document.
  ///
  /// Cancelling the picker is not an error: the slot is left exactly as it was,
  /// so backing out of the camera does not wipe a document already uploaded.
  Future<void> pickAndUpload(
    DriverDocument document, {
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      // Enough to read a licence number, small enough to upload on mobile
      // data. A 12 MP original is ~4 MB and adds nothing an operator can use.
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (picked == null) return;

    _setSlot(
      document,
      DocumentSlot(
        state: UploadState.uploading,
        localPath: picked.path,
        progress: 0,
      ),
    );

    try {
      final key = await _uploads.uploadFile(
        kind: document.kind,
        file: File(picked.path),
        onProgress: (p) => _setSlot(
          document,
          state.slot(document).copyWith(progress: p),
        ),
      );
      _setSlot(
        document,
        DocumentSlot(
          state: UploadState.uploaded,
          key: key,
          localPath: picked.path,
          progress: 1,
        ),
      );
    } on ApiException catch (e) {
      _setSlot(
        document,
        DocumentSlot(
          state: UploadState.failed,
          localPath: picked.path,
          error: e.message,
        ),
      );
    } on Object catch (e) {
      _setSlot(
        document,
        DocumentSlot(
          state: UploadState.failed,
          localPath: picked.path,
          error: 'Upload failed. Please try again.',
        ),
      );
      if (kDebugMode) debugPrint('KYC upload failed: $e');
    }
  }

  void remove(DriverDocument document) {
    final next = Map<DriverDocument, DocumentSlot>.from(state.slots)
      ..remove(document);
    state = state.copyWith(slots: next);
  }

  /// Submit the driver's own documents (licence).
  Future<bool> submitDriverDocuments() async {
    return _submit(() => _repository.submitDriverDocuments(state.uploadedKeys));
  }

  /// Create the vehicle and attach whatever vehicle documents are uploaded.
  Future<bool> submitVehicle(VehicleDraft draft) async {
    return _submit(() => _repository.createVehicle(
          draft: draft,
          documentKeys: state.uploadedKeys,
        ));
  }

  Future<bool> _submit(Future<void> Function() action) async {
    state = state.copyWith(submitting: true, clearSubmitError: true);
    try {
      await action();
      state = state.copyWith(submitting: false, submitted: true);
      return true;
    } on ApiException catch (e) {
      // The server's own message, which is written for drivers.
      state = state.copyWith(submitting: false, submitError: e.message);
      return false;
    } on Object catch (e) {
      state = state.copyWith(
        submitting: false,
        submitError: 'Could not submit. Please try again.',
      );
      if (kDebugMode) debugPrint('KYC submit failed: $e');
      return false;
    }
  }

  void _setSlot(DriverDocument document, DocumentSlot slot) {
    state = state.copyWith(
      slots: {...state.slots, document: slot},
    );
  }
}

final uploadClientProvider = Provider<UploadClient>(
  (ref) => UploadClient(ref.watch(apiClientProvider)),
);

final kycRepositoryProvider = Provider<KycRepository>(
  (ref) => KycRepository(ref.watch(apiClientProvider)),
);

final kycControllerProvider =
    NotifierProvider<KycController, KycState>(KycController.new);
