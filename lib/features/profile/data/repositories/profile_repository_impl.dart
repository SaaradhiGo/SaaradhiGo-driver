import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/uploads/mime_resolver.dart';
import '../../../../core/uploads/presigned_upload_service.dart';
import '../../../../core/uploads/upload_exceptions.dart';
import '../../../../core/uploads/upload_kind.dart';
import '../../../../domain/models/driver_profile_model.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../data_sources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  ProfileRepositoryImpl(
    this.remoteDataSource, {
    PresignedUploadService? uploadService,
    bool Function()? presignedUploadsEnabled,
  }) : _uploadService = uploadService,
       _presignedUploadsEnabled = presignedUploadsEnabled ?? (() => false);

  final ProfileRemoteDataSource remoteDataSource;
  final PresignedUploadService? _uploadService;
  final bool Function() _presignedUploadsEnabled;

  final MimeTypeResolver _mimeTypeResolver = const MimeTypeResolver();

  bool get _usePresignedUploads =>
      _uploadService != null && _presignedUploadsEnabled();

  @override
  Future<Either<Failure, DriverProfileModel>> getDriverProfile() async {
    try {
      final profile = await remoteDataSource.getDriverProfile();
      return Right(profile);
    } on DioException catch (e) {
      if (e.error is SocketException) {
        return const Left(NetworkFailure());
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const Left(AuthFailure());
      }
      return const Left(ServerFailure());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAvatar({
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      if (_usePresignedUploads) {
        final mimeType = _mimeTypeResolver.resolve(
          fileName: fileName,
          bytes: bytes,
        );
        if (mimeType == null || !UploadKind.avatar.allowsMimeType(mimeType)) {
          throw UploadValidationException(
            'Unsupported file type. Please use '
            '${UploadKind.avatar.friendlyTypeHint}.',
          );
        }
        final result = await _uploadService!.upload(
          kind: UploadKind.avatar,
          bytes: bytes,
          mimeType: mimeType,
          onProgress: onProgress,
        );
        await remoteDataSource.updateAvatarKey(result.key);
      } else {
        await remoteDataSource.updateAvatarMultipart(bytes, fileName);
      }
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on UploadException catch (e) {
      return Left(_mapUploadException(e));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  Failure _mapDioException(DioException e) {
    if (e.error is SocketException) {
      return const NetworkFailure();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('Request timed out. Please try again.');
    }
    final statusCode = e.response?.statusCode;
    final serverMessage = PresignedUploadService.extractServerErrorMessage(
      e.response?.data,
    );
    if (statusCode == 401 || statusCode == 403) {
      return serverMessage == null
          ? const AuthFailure()
          : AuthFailure(serverMessage);
    }
    if (statusCode == 400 || statusCode == 422) {
      return ValidationFailure(serverMessage ?? 'Validation failed');
    }
    return serverMessage == null
        ? const ServerFailure()
        : ServerFailure(serverMessage);
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
