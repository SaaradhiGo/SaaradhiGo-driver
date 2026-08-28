import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/uploads/presigned_upload_service.dart';
import 'package:saaradhigo_driver/core/uploads/upload_exceptions.dart';
import 'package:saaradhigo_driver/core/uploads/upload_kind.dart';
import 'package:saaradhigo_driver/domain/models/driver_profile_model.dart';
import 'package:saaradhigo_driver/features/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:saaradhigo_driver/features/profile/data/repositories/profile_repository_impl.dart';

class _FakeProfileDataSource implements ProfileRemoteDataSource {
  Object? updateAvatarError;
  final List<String> avatarKeys = [];
  final List<Uint8List> multipartBodies = [];
  int avatarKeyCalls = 0;
  int multipartCalls = 0;

  @override
  Future<DriverProfileModel> getDriverProfile() async =>
      DriverProfileModel.fromJson(const {});

  @override
  Future<void> updateAvatarKey(String avatarKey) async {
    avatarKeyCalls++;
    avatarKeys.add(avatarKey);
    final error = updateAvatarError;
    if (error != null) throw error;
  }

  @override
  Future<void> updateAvatarMultipart(Uint8List bytes, String? fileName) async {
    multipartCalls++;
    multipartBodies.add(bytes);
  }
}

class _StubUploadService extends PresignedUploadService {
  _StubUploadService() : super(dio: Dio());

  UploadException? nextError;

  @override
  Future<S3UploadResult> upload({
    required UploadKind kind,
    required Uint8List bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final error = nextError;
    if (error != null) throw error;
    return const S3UploadResult(key: 'avatars/def456.jpg');
  }
}

void main() {
  late _FakeProfileDataSource dataSource;
  late _StubUploadService uploadService;
  late bool presignedEnabled;
  late ProfileRepositoryImpl repository;

  setUp(() {
    dataSource = _FakeProfileDataSource();
    uploadService = _StubUploadService();
    presignedEnabled = true;
    repository = ProfileRepositoryImpl(
      dataSource,
      uploadService: uploadService,
      presignedUploadsEnabled: () => presignedEnabled,
    );
  });

  group('updateAvatar (presigned, flag ON)', () {
    test('uploads then submits the object key as plain JSON', () async {
      final result = await repository.updateAvatar(
        bytes: Uint8List.fromList([9, 9, 9]),
        fileName: 'me.jpg',
      );

      expect(result.isRight(), isTrue);
      expect(dataSource.avatarKeyCalls, 1);
      // Key passthrough: exactly what the presign flow returned.
      expect(dataSource.avatarKeys.single, 'avatars/def456.jpg');
      expect(dataSource.multipartCalls, 0);
    });

    test('rejects unsupported MIME types before any network call', () async {
      final result = await repository.updateAvatar(
        bytes: Uint8List.fromList([1]),
        fileName: 'doc.pdf',
      );

      expect(result.isLeft(), isTrue);
      expect(dataSource.avatarKeyCalls, 0);
      result.fold((f) => expect(f.message, contains('Unsupported')), (_) {});
    });

    test('maps server 403 error envelope to AuthFailure with message',
        () async {
      dataSource.updateAvatarError = DioException(
        requestOptions: RequestOptions(path: '/auth/update/'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/auth/update/'),
          statusCode: 403,
          data: {
            'status': 'error',
            'error': {'code': 'PERMISSION', 'message': 'Not allowed.'},
          },
        ),
      );

      final result = await repository.updateAvatar(
        bytes: Uint8List.fromList([1]),
        fileName: 'me.png',
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f.message, 'Not allowed.');
      }, (_) {});
    });
  });

  test('legacy multipart path used when flag OFF', () async {
    presignedEnabled = false;

    await repository.updateAvatar(
      bytes: Uint8List.fromList([7]),
      fileName: 'me.jpg',
    );

    expect(dataSource.multipartCalls, 1);
    expect(dataSource.avatarKeyCalls, 0);
  });
}
