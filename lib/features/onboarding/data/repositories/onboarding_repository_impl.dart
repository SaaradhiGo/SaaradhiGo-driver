import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/uploads/mime_resolver.dart';
import '../../../../core/uploads/presigned_upload_service.dart';
import '../../../../core/uploads/upload_exceptions.dart';
import '../../../../core/uploads/upload_kind.dart';
import '../../data/models/picked_document.dart';
import '../../data/models/vehicle_request_dto.dart';
import '../../domain/repositories/i_onboarding_repository.dart';
import '../data_sources/onboarding_remote_data_source.dart';

class OnboardingRepositoryImpl implements IOnboardingRepository {
  OnboardingRepositoryImpl(
    this.remoteDataSource, {
    PresignedUploadService? uploadService,
    bool Function()? presignedUploadsEnabled,
    this.activationRetryDelay = const Duration(seconds: 1),
  }) : _uploadService = uploadService,
       _presignedUploadsEnabled = presignedUploadsEnabled ?? (() => false);

  final OnboardingRemoteDataSource remoteDataSource;
  final PresignedUploadService? _uploadService;
  final bool Function() _presignedUploadsEnabled;

  /// Delay between activation retry attempts (injectable so tests run fast).
  final Duration activationRetryDelay;

  /// Activation is retried on transient errors only; 1 initial call + retries.
  static const int _maxActivationAttempts = 3;

  /// Vehicle created but not yet confirmed active. While set, [addVehicle]
  /// never re-creates the vehicle — it retries activation only.
  int? _pendingActivationVehicleId;

  final MimeTypeResolver _mimeTypeResolver = const MimeTypeResolver();
  CancelToken? _activeCancelToken;

  bool get _usePresignedUploads =>
      _uploadService != null && _presignedUploadsEnabled();

  @override
  Future<Either<Failure, void>> updatePersonalDetails(
    Map<String, dynamic> data,
  ) async {
    return _handleExceptions(
      () => remoteDataSource.updatePersonalDetails(data),
    );
  }

  @override
  Future<Either<Failure, void>> updateAvatar(
    PickedDocument document, {
    UploadProgressCallback? onProgress,
  }) {
    return _handleExceptions(() async {
      if (_usePresignedUploads) {
        final key = await _uploadToS3(
          kind: UploadKind.avatar,
          document: document,
          onProgress: onProgress,
        );
        await remoteDataSource.updateAvatarWithKey(key);
      } else {
        await remoteDataSource.updateAvatarMultipart(document);
      }
    });
  }

  @override
  Future<Either<Failure, void>> updateBankDetails(
    Map<String, dynamic> data,
  ) async {
    return _handleExceptions(() => remoteDataSource.updateBankDetails(data));
  }

  @override
  Future<Either<Failure, void>> addVehicle(
    VehicleRequestDto vehicleDto, {
    UploadProgressCallback? onProgress,
  }) async {
    // A previous submit already created this vehicle but activation never
    // completed. Re-submitting would create a duplicate vehicle record, so
    // retry activation only.
    final pendingId = _pendingActivationVehicleId;
    if (pendingId != null) {
      return _activateWithRetry(pendingId);
    }

    Map<String, dynamic>? createResponse;
    final creationResult = await _handleExceptions(() async {
      final document = vehicleDto.rcDocument;
      final pic = vehicleDto.vehiclePicDocument;
      if (_usePresignedUploads) {
        String? rcDocKey;
        if (document != null && document.isAvailable) {
          rcDocKey = await _uploadToS3(
            kind: UploadKind.rcDoc,
            document: document,
            onProgress: onProgress,
          );
        }
        String? vehiclePicKey;
        if (pic != null && pic.isAvailable) {
          // API_Documentation_V2 §3.7 accepts the presigned `vehicle_pic`
          // key directly in the create body — no separate PATCH needed.
          // Uploading before creation means a failed PUT can never leave a
          // half-registered vehicle behind.
          vehiclePicKey = await _uploadToS3(
            kind: UploadKind.vehiclePic,
            document: pic,
            onProgress: onProgress,
          );
        }
        // Plain JSON only — the server never receives file bytes here.
        createResponse = await remoteDataSource.addVehicleWithKeys(
          _vehicleBody(vehicleDto, rcDocKey, vehiclePicKey),
        );
      } else {
        createResponse = await remoteDataSource.addVehicle(vehicleDto);
      }
    });
    if (creationResult.isLeft()) return creationResult;

    final vehicleId = _extractVehicleId(createResponse);
    if (vehicleId == null) {
      // Contract gap: §3.7 guarantees the created Vehicle object with an id.
      return const Left(
        ValidationFailure(
          'Server did not return the new vehicle ID, so it cannot be set as '
          'your active vehicle. Please try again or contact support.',
        ),
      );
    }

    // Mark saved before activating: if activation fails the next submit must
    // skip creation and retry activation for this id.
    _pendingActivationVehicleId = vehicleId;

    // Driver unchecked "Set as my active vehicle" — creation is the whole job.
    if (vehicleDto.setAsActive == false) {
      _pendingActivationVehicleId = null;
      return const Right(null);
    }
    return _activateWithRetry(vehicleId);
  }

  /// Extracts the created vehicle's id from a `{status, data: {id}}`
  /// envelope (same unpacking convention as ProfileRemoteDataSource).
  int? _extractVehicleId(Map<String, dynamic>? response) {
    if (response == null) return null;
    final data = response['data'];
    final vehicle = data is Map<String, dynamic> ? data : response;
    final id = vehicle['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    if (id is String) return int.tryParse(id);
    return null;
  }

  Future<Either<Failure, void>> _activateWithRetry(int vehicleId) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxActivationAttempts; attempt++) {
      try {
        await remoteDataSource.setActiveVehicle(vehicleId);
        _pendingActivationVehicleId = null;
        return const Right(null);
      } on DioException catch (e) {
        lastError = e;
        if (!_isRetryableActivationError(e)) break;
        if (attempt == _maxActivationAttempts) break;
        await Future<void>.delayed(activationRetryDelay);
      } catch (e) {
        lastError = e;
        break;
      }
    }
    return Left(_mapActivationFailure(lastError));
  }

  bool _isRetryableActivationError(DioException e) {
    if (e.error is SocketException) return true;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return code != null && code >= 500;
      default:
        return false;
    }
  }

  Failure _mapActivationFailure(Object? error) {
    const context =
        'Your vehicle was saved, but it could not be set as your active '
        'vehicle.';
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final serverMessage = PresignedUploadService.extractServerErrorMessage(
        error.response?.data,
      );
      if (statusCode == 401 || statusCode == 403) {
        // Session-level failure: drop the pending id so a future login cannot
        // accidentally skip creation against a different account.
        _pendingActivationVehicleId = null;
        return AuthFailure(serverMessage ?? 'Please log in again.');
      }
      if (statusCode == 400 || statusCode == 422) {
        return ValidationFailure(
          '$context ${serverMessage ?? 'Invalid data.'}',
        );
      }
      if (_isRetryableActivationError(error)) {
        return NetworkFailure('$context Please try again.');
      }
      return ServerFailure(
        '$context ${serverMessage ?? 'Server error.'} Please try again.',
      );
    }
    return UnknownFailure(context);
  }

  @override
  Future<Either<Failure, void>> updateDrivingLicence(
    String licenseNumber,
    String licenseExpiry,
    PickedDocument document, {
    PickedDocument? backDocument,
    UploadProgressCallback? onProgress,
  }) {
    return _handleExceptions(() async {
      if (_usePresignedUploads) {
        final key = await _uploadToS3(
          kind: UploadKind.licenseDoc,
          document: document,
          onProgress: onProgress,
        );
        final body = <String, dynamic>{
          'license_number': licenseNumber,
          'license_expiry': licenseExpiry,
          'license_doc': key,
        };
        // Back side is optional: its key/field are pending backend
        // confirmation, so it is only sent when the driver picked one.
        if (backDocument != null && backDocument.isAvailable) {
          body['license_doc_back'] = await _uploadToS3(
            kind: UploadKind.licenseDocBack,
            document: backDocument,
            onProgress: onProgress,
          );
        }
        await remoteDataSource.updateDrivingLicenceWithKeys(body);
      } else {
        await remoteDataSource.updateDrivingLicenceMultipart(
          licenseNumber: licenseNumber,
          licenseExpiry: licenseExpiry,
          document: document,
          backDocument: backDocument,
        );
      }
    });
  }

  @override
  Future<Either<Failure, void>> updateVehicle(
    String vehicleId,
    Map<String, dynamic> partialUpdate,
  ) {
    return _handleExceptions(
      () => remoteDataSource.updateVehicle(vehicleId, partialUpdate),
    );
  }

  @override
  void cancelActiveUpload() {
    _activeCancelToken?.cancel('screen_disposed');
    _activeCancelToken = null;
  }

  /// Resolves bytes + MIME, validates client-side, then runs the presign →
  /// S3 PUT flow and returns the object key to submit in JSON payloads.
  Future<String> _uploadToS3({
    required UploadKind kind,
    required PickedDocument document,
    required UploadProgressCallback? onProgress,
  }) async {
    final bytes = await document.resolveBytes();

    final mimeType = _mimeTypeResolver.resolve(
      fileName: document.name,
      bytes: bytes,
    );
    if (mimeType == null || !kind.allowsMimeType(mimeType)) {
      throw UploadValidationException(
        'Unsupported file type. Please use ${kind.friendlyTypeHint}.',
      );
    }

    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;
    try {
      final result = await _uploadService!.upload(
        kind: kind,
        bytes: bytes,
        mimeType: mimeType,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return result.key;
    } finally {
      _activeCancelToken = null;
    }
  }

  Map<String, dynamic> _vehicleBody(
    VehicleRequestDto dto,
    String? rcDocKey,
    String? vehiclePicKey,
  ) {
    return <String, dynamic>{
      'vehicle_number': dto.registrationNumber,
      'vehicle_type': dto.vehicleType,
      'make': dto.make,
      'model': dto.model,
      'year': dto.year,
      'color': dto.color,
      'rc_doc': ?rcDocKey,
      'vehicle_pic': ?vehiclePicKey,
    };
  }

  Future<Either<Failure, void>> _handleExceptions(
    Future<void> Function() call,
  ) async {
    try {
      await call();
      return const Right(null);
    } on DioException catch (e) {
      if (e.error is SocketException) {
        return const Left(
          NetworkFailure('Request timed out. Please try again.'),
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(
          NetworkFailure('Request timed out. Please try again.'),
        );
      }
      final statusCode = e.response?.statusCode;
      final serverMessage = PresignedUploadService.extractServerErrorMessage(
        e.response?.data,
      );
      if (statusCode == 401 || statusCode == 403) {
        return Left(
          serverMessage == null
              ? const AuthFailure()
              : AuthFailure(serverMessage),
        );
      }
      if (statusCode == 400 || statusCode == 422) {
        return Left(ValidationFailure(serverMessage ?? 'Validation failed'));
      }
      return Left(
        serverMessage == null
            ? const ServerFailure()
            : ServerFailure(serverMessage),
      );
    } on UploadCancelledException catch (e) {
      return Left(UnknownFailure(e.message));
    } on UploadException catch (e) {
      return Left(_mapUploadException(e));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  Failure _mapUploadException(UploadException e) {
    return switch (e) {
      UploadValidationException() => ValidationFailure(e.message),
      UploadAuthException() => AuthFailure(e.message),
      UploadForbiddenException() => AuthFailure(e.message),
      UploadNetworkException() => NetworkFailure(e.message),
      UploadExpiredException() => NetworkFailure(e.message),
      UploadServerException() => ServerFailure(e.message),
      UploadCancelledException() => UnknownFailure(e.message),
    };
  }
}
