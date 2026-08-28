import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:saaradhigo_driver/core/errors/failures.dart';
import 'package:saaradhigo_driver/core/uploads/presigned_upload_service.dart';
import 'package:saaradhigo_driver/core/uploads/upload_exceptions.dart';
import 'package:saaradhigo_driver/core/uploads/upload_kind.dart';
import 'package:saaradhigo_driver/features/onboarding/data/data_sources/onboarding_remote_data_source.dart';
import 'package:saaradhigo_driver/features/onboarding/data/models/picked_document.dart';
import 'package:saaradhigo_driver/features/onboarding/data/models/vehicle_request_dto.dart';
import 'package:saaradhigo_driver/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:saaradhigo_driver/features/onboarding/domain/repositories/i_onboarding_repository.dart';
import 'package:saaradhigo_driver/features/onboarding/domain/use_cases/submit_bank_details_use_case.dart';
import 'package:saaradhigo_driver/features/onboarding/domain/use_cases/submit_personal_details_use_case.dart';

class _FakeRemoteDataSource implements OnboardingRemoteDataSource {
  Object? avatarError;
  Object? addVehicleError;
  Object? activeVehicleError;
  int activeVehicleTimeoutsBeforeSuccess = 0;

  /// Response returned by both vehicle-creation paths (§3.6 returns the
  /// created Vehicle object). Override per-test for contract-gap cases.
  Map<String, dynamic> Function() addVehicleResponse = () => {
    'data': {'id': 7},
  };

  int avatarKeyCalls = 0;
  int avatarMultipartCalls = 0;
  int vehicleJsonCalls = 0;
  int vehicleMultipartCalls = 0;
  int licenceJsonCalls = 0;
  int licenceMultipartCalls = 0;
  int updateVehicleCalls = 0;
  int setActiveVehicleCalls = 0;

  final List<int> setActiveVehicleIds = [];
  final List<Map<String, dynamic>> vehicleBodies = [];
  final List<Map<String, dynamic>> licenceBodies = [];
  final List<Map<String, dynamic>> updateVehicleBodies = [];
  final List<Map<String, dynamic>> personalDetailBodies = [];
  final List<String> avatarKeys = [];
  final List<bool> licenceMultipartHadBack = [];

  FormData? lastVehicleFormData;

  VehicleRequestDto? lastReceivedVehicleDto;

  @override
  Future<Map<String, dynamic>> updatePersonalDetails(
    Map<String, dynamic> data,
  ) async {
    personalDetailBodies.add(data);
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateAvatarWithKey(String avatarKey) async {
    avatarKeyCalls++;
    avatarKeys.add(avatarKey);
    final error = avatarError;
    if (error != null) throw error;
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateAvatarMultipart(
    PickedDocument document,
  ) async {
    avatarMultipartCalls++;
    final error = avatarError;
    if (error != null) throw error;
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateBankDetails(
    Map<String, dynamic> data,
  ) async => {};

  @override
  Future<Map<String, dynamic>> addVehicleWithKeys(
    Map<String, dynamic> body,
  ) async {
    vehicleJsonCalls++;
    vehicleBodies.add(body);
    final error = addVehicleError;
    if (error != null) throw error;
    return addVehicleResponse();
  }

  @override
  Future<Map<String, dynamic>> addVehicle(VehicleRequestDto vehicleDto) async {
    vehicleMultipartCalls++;
    lastReceivedVehicleDto = vehicleDto;
    final error = addVehicleError;
    if (error != null) throw error;
    return addVehicleResponse();
  }

  @override
  Future<Map<String, dynamic>> updateDrivingLicenceWithKeys(
    Map<String, dynamic> body,
  ) async {
    licenceJsonCalls++;
    licenceBodies.add(body);
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateDrivingLicenceMultipart({
    required String licenseNumber,
    required String licenseExpiry,
    required PickedDocument document,
    PickedDocument? backDocument,
  }) async {
    licenceMultipartCalls++;
    licenceMultipartHadBack.add(backDocument != null);
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String vehicleId,
    Map<String, dynamic> body,
  ) async {
    updateVehicleCalls++;
    updateVehicleBodies.add(body);
    return {};
  }

  @override
  Future<Map<String, dynamic>> setActiveVehicle(int vehicleId) async {
    setActiveVehicleCalls++;
    setActiveVehicleIds.add(vehicleId);
    final error = activeVehicleError;
    if (error != null) throw error;
    if (activeVehicleTimeoutsBeforeSuccess > 0) {
      activeVehicleTimeoutsBeforeSuccess--;
      throw _dioException(type: DioExceptionType.receiveTimeout);
    }
    return {};
  }
}

class _StubUploadService extends PresignedUploadService {
  _StubUploadService() : super(dio: Dio());

  S3UploadResult? nextResult;
  UploadException? nextError;

  /// Per-upload errors consumed in order before falling back to [nextError].
  final List<UploadException?> errorQueue = [];

  final List<UploadKind> kinds = [];
  final List<void Function(int sent, int total)> progressCallbacks = [];

  @override
  Future<S3UploadResult> upload({
    required UploadKind kind,
    required Uint8List bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    kinds.add(kind);
    if (onProgress != null) {
      progressCallbacks.add(onProgress);
      onProgress(bytes.length ~/ 2, bytes.length);
      onProgress(bytes.length, bytes.length);
    }
    final error = errorQueue.isNotEmpty ? errorQueue.removeAt(0) : nextError;
    if (error != null) throw error;
    return nextResult ?? const S3UploadResult(key: 'rc_docs/abc123.png');
  }
}

PickedDocument pngDoc({String name = 'rc.png'}) =>
    PickedDocument(bytes: Uint8List.fromList([1, 2, 3]), name: name);

VehicleRequestDto vehicleDto({
  PickedDocument? document,
  PickedDocument? pic,
  bool? setAsActive,
}) => VehicleRequestDto(
  registrationNumber: 'KA01AB1234',
  vehicleType: 'sedan',
  make: 'Maruti',
  model: 'Swift',
  year: 2022,
  color: 'White',
  rcDocument: document,
  vehiclePicDocument: pic,
  setAsActive: setAsActive,
);

DioException _dioException({
  required DioExceptionType type,
  Response<dynamic>? response,
  Object? error,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/auth/update/'),
    type: type,
    response: response,
    error: error,
  );
}

void main() {
  late _FakeRemoteDataSource dataSource;
  late _StubUploadService uploadService;
  late bool presignedEnabled;

  OnboardingRepositoryImpl buildRepository() => OnboardingRepositoryImpl(
    dataSource,
    uploadService: uploadService,
    presignedUploadsEnabled: () => presignedEnabled,
    activationRetryDelay: Duration.zero,
  );

  setUp(() {
    dataSource = _FakeRemoteDataSource();
    uploadService = _StubUploadService();
    presignedEnabled = true;
  });

  group('presigned flow (flag ON)', () {
    test('addVehicle uploads RC then submits JSON body with the key', () async {
      final repository = buildRepository();

      final result = await repository.addVehicle(
        vehicleDto(document: pngDoc()),
      );

      expect(result.isRight(), isTrue);
      expect(uploadService.kinds, [UploadKind.rcDoc]);
      expect(dataSource.vehicleJsonCalls, 1);
      expect(dataSource.vehicleMultipartCalls, 0);
      expect(dataSource.vehicleBodies.single, {
        'vehicle_number': 'KA01AB1234',
        'vehicle_type': 'sedan',
        'make': 'Maruti',
        'model': 'Swift',
        'year': 2022,
        'color': 'White',
        'rc_doc': 'rc_docs/abc123.png',
      });
    });

    test(
      'addVehicle without a document omits rc_doc but still submits',
      () async {
        final repository = buildRepository();

        await repository.addVehicle(vehicleDto());

        expect(dataSource.vehicleJsonCalls, 1);
        expect(dataSource.vehicleBodies.single.containsKey('rc_doc'), isFalse);
      },
    );

    test(
      'addVehicle uploads RC + picture and submits both keys on create',
      () async {
        final repository = buildRepository();

        final result = await repository.addVehicle(
          vehicleDto(
            document: pngDoc(),
            pic: pngDoc(name: 'car.jpg'),
          ),
        );

        expect(result.isRight(), isTrue);
        expect(uploadService.kinds, [UploadKind.rcDoc, UploadKind.vehiclePic]);
        expect(dataSource.vehicleJsonCalls, 1);
        // V2 §3.7 accepts the picture key on create — no PATCH needed.
        expect(dataSource.updateVehicleCalls, 0);
        expect(dataSource.vehicleBodies.single, {
          'vehicle_number': 'KA01AB1234',
          'vehicle_type': 'sedan',
          'make': 'Maruti',
          'model': 'Swift',
          'year': 2022,
          'color': 'White',
          'rc_doc': 'rc_docs/abc123.png',
          'vehicle_pic': 'rc_docs/abc123.png',
        });
        expect(dataSource.setActiveVehicleCalls, 1);
      },
    );

    test('addVehicle with setAsActive=false skips activation', () async {
      final repository = buildRepository();

      final result = await repository.addVehicle(
        vehicleDto(document: pngDoc(), setAsActive: false),
      );

      expect(result.isRight(), isTrue);
      expect(dataSource.vehicleJsonCalls, 1);
      expect(dataSource.setActiveVehicleCalls, 0);
    });

    test('picture upload failure blocks creation entirely', () async {
      final repository = buildRepository();
      uploadService.errorQueue.addAll([
        null, // RC PUT succeeds...
        const UploadNetworkException('offline'), // ...picture PUT fails.
      ]);

      final first = await repository.addVehicle(
        vehicleDto(document: pngDoc(), pic: pngDoc()),
      );
      expect(first.isLeft(), isTrue);
      expect(first.fold((f) => f, (_) => null), isA<NetworkFailure>());
      // CRITICAL: both keys are uploaded before creation, so a failed PUT
      // can never leave a half-registered vehicle behind.
      expect(dataSource.vehicleJsonCalls, 0);
      expect(dataSource.setActiveVehicleCalls, 0);

      // Clean re-submit uploads both files again and creates exactly once.
      final second = await repository.addVehicle(
        vehicleDto(document: pngDoc(), pic: pngDoc()),
      );

      expect(second.isRight(), isTrue);
      expect(dataSource.vehicleJsonCalls, 1);
      expect(uploadService.kinds.length, 4); // rc, pic, rc, pic
      expect(
        dataSource.vehicleBodies.single['vehicle_pic'],
        'rc_docs/abc123.png',
      );
      expect(dataSource.setActiveVehicleIds.single, 7);
    });

    test('avatar uploads then PATCHes the key as plain JSON', () async {
      final repository = buildRepository();

      await repository.updateAvatar(pngDoc(name: 'me.jpg'));

      expect(uploadService.kinds, [UploadKind.avatar]);
      expect(dataSource.avatarKeyCalls, 1);
      expect(dataSource.avatarKeys.single, 'rc_docs/abc123.png');
      expect(dataSource.avatarMultipartCalls, 0);
    });

    test('licence uploads then PATCHes the key with licence fields', () async {
      final repository = buildRepository();

      await repository.updateDrivingLicence(
        'KA0120220001',
        '2032-01-31',
        pngDoc(name: 'dl.pdf'),
      );

      expect(uploadService.kinds, [UploadKind.licenseDoc]);
      expect(dataSource.licenceJsonCalls, 1);
      expect(dataSource.licenceMultipartCalls, 0);
      expect(dataSource.licenceBodies.single, {
        'license_number': 'KA0120220001',
        'license_expiry': '2032-01-31',
        'license_doc': 'rc_docs/abc123.png',
      });
    });

    test('licence back side uploads and PATCHes license_doc_back', () async {
      final repository = buildRepository();

      await repository.updateDrivingLicence(
        'KA0120220001',
        '2032-01-31',
        pngDoc(name: 'dl-front.jpg'),
        backDocument: pngDoc(name: 'dl-back.jpg'),
      );

      expect(uploadService.kinds, [
        UploadKind.licenseDoc,
        UploadKind.licenseDocBack,
      ]);
      expect(dataSource.licenceBodies.single, {
        'license_number': 'KA0120220001',
        'license_expiry': '2032-01-31',
        'license_doc': 'rc_docs/abc123.png',
        'license_doc_back': 'rc_docs/abc123.png',
      });
    });

    test('upload failure blocks submission and returns a Failure', () async {
      uploadService.nextError = const UploadNetworkException('network down');
      final repository = buildRepository();

      final result = await repository.addVehicle(
        vehicleDto(document: pngDoc()),
      );

      expect(result.isLeft(), isTrue);
      // CRITICAL: the vehicle must NOT be submitted without the uploaded key.
      expect(dataSource.vehicleJsonCalls, 0);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) {});
    });

    test('forbidden uploads map to AuthFailure with server message', () async {
      uploadService.nextError = const UploadForbiddenException(
        'Driver account required.',
      );
      final repository = buildRepository();

      final result = await repository.updateDrivingLicence(
        'N',
        '2032-01-31',
        pngDoc(),
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f, isA<AuthFailure>());
        expect(f.message, 'Driver account required.');
      }, (_) {});
    });

    test('progress callback is forwarded to the service', () async {
      final repository = buildRepository();
      final calls = <double>[];

      await repository.addVehicle(
        vehicleDto(document: pngDoc()),
        onProgress: (sent, total) => calls.add(sent / total),
      );

      // Stub emits half then complete; 3-byte doc -> 1/3 then full.
      expect(calls.first, closeTo(1 / 3, 0.001));
      expect(calls.last, 1.0);
    });

    test('cancelActiveUpload cancels an in-flight upload token', () async {
      presignedEnabled = true;
      CancelToken? captured;
      final uploadStarted = Completer<void>();
      final releaseUpload = Completer<void>();
      final slowService = _BlockingCancelStub(
        onToken: (token) {
          captured = token;
          uploadStarted.complete();
        },
        release: releaseUpload.future,
      );
      final slowRepository = OnboardingRepositoryImpl(
        dataSource,
        uploadService: slowService,
        presignedUploadsEnabled: () => presignedEnabled,
      );

      final future = slowRepository.addVehicle(vehicleDto(document: pngDoc()));
      await uploadStarted.future;
      slowRepository.cancelActiveUpload();
      releaseUpload.complete();
      await future;

      expect(captured?.isCancelled, isTrue);
    });
  });

  group('legacy multipart flow (flag OFF)', () {
    test('addVehicle uses multipart when flag disabled', () async {
      presignedEnabled = false;
      final repository = buildRepository();

      await repository.addVehicle(vehicleDto(document: pngDoc()));

      expect(dataSource.vehicleMultipartCalls, 1);
      expect(dataSource.vehicleJsonCalls, 0);
      expect(uploadService.kinds, isEmpty);
    });

    test('avatar uses multipart when flag disabled', () async {
      presignedEnabled = false;
      final repository = buildRepository();

      await repository.updateAvatar(pngDoc());

      expect(dataSource.avatarMultipartCalls, 1);
      expect(dataSource.avatarKeyCalls, 0);
    });

    test('licence uses multipart when flag disabled', () async {
      presignedEnabled = false;
      final repository = buildRepository();

      await repository.updateDrivingLicence('N', '2032-01-31', pngDoc());

      expect(dataSource.licenceMultipartCalls, 1);
      expect(dataSource.licenceJsonCalls, 0);
      expect(dataSource.licenceMultipartHadBack.single, isFalse);
    });

    test('licence multipart carries the back document when provided', () async {
      presignedEnabled = false;
      final repository = buildRepository();

      await repository.updateDrivingLicence(
        'N',
        '2032-01-31',
        pngDoc(name: 'dl-front.jpg'),
        backDocument: pngDoc(name: 'dl-back.jpg'),
      );

      expect(dataSource.licenceMultipartCalls, 1);
      expect(dataSource.licenceMultipartHadBack.single, isTrue);
    });

    test(
      'vehicle multipart DTO reaches the data source with the picture',
      () async {
        presignedEnabled = false;
        final repository = buildRepository();

        await repository.addVehicle(
          vehicleDto(
            document: pngDoc(),
            pic: pngDoc(name: 'car.jpg'),
          ),
        );

        expect(dataSource.vehicleMultipartCalls, 1);
        // The legacy data source maps this to the `vehicle_pic` field.
        expect(
          dataSource.lastReceivedVehicleDto?.vehiclePicDocument?.name,
          'car.jpg',
        );
      },
    );
  });

  group('updateVehicle (Edit Vehicle data layer)', () {
    test('passes partial JSON through to PATCH endpoint', () async {
      final repository = buildRepository();

      await repository.updateVehicle('42', {'color': 'Matte Black'});

      expect(dataSource.updateVehicleCalls, 1);
    });
  });

  group('active vehicle activation (create-once, retry PATCH only)', () {
    test(
      'activates the created vehicle id from the response envelope',
      () async {
        final repository = buildRepository();

        final result = await repository.addVehicle(vehicleDto());

        expect(result.isRight(), isTrue);
        expect(dataSource.setActiveVehicleCalls, 1);
        expect(dataSource.setActiveVehicleIds.single, 7);
      },
    );

    test('legacy multipart create also activates (flag OFF)', () async {
      presignedEnabled = false;
      final repository = buildRepository();

      await repository.addVehicle(vehicleDto());

      expect(dataSource.vehicleMultipartCalls, 1);
      expect(dataSource.setActiveVehicleIds.single, 7);
    });

    test(
      'missing id in create response -> ValidationFailure, no activation',
      () async {
        dataSource.addVehicleResponse = () => {'status': 'success'};
        final repository = buildRepository();

        final result = await repository.addVehicle(vehicleDto());

        expect(result.isLeft(), isTrue);
        result.fold((f) => expect(f, isA<ValidationFailure>()), (_) {});
        expect(dataSource.setActiveVehicleCalls, 0);
      },
    );

    test('retries transient activation failures then succeeds', () async {
      dataSource.activeVehicleTimeoutsBeforeSuccess = 2;
      final repository = buildRepository();

      final result = await repository.addVehicle(vehicleDto());

      expect(result.isRight(), isTrue);
      // Create ran exactly once despite the two failed activation attempts.
      expect(dataSource.vehicleJsonCalls, 1);
      expect(dataSource.setActiveVehicleCalls, 3);
    });

    test('non-retryable activation failure stops immediately', () async {
      dataSource.activeVehicleError = _dioException(
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/driver/driver/update/'),
          statusCode: 400,
        ),
      );
      final repository = buildRepository();

      final result = await repository.addVehicle(vehicleDto());

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) {});
      expect(dataSource.vehicleJsonCalls, 1);
      expect(dataSource.setActiveVehicleCalls, 1);
    });

    test('activation failure on 401 drops pending id to avoid cross-account '
        'skip-creation', () async {
      dataSource.activeVehicleError = _dioException(
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/driver/driver/update/'),
          statusCode: 401,
        ),
      );
      final repository = buildRepository();

      final first = await repository.addVehicle(vehicleDto());
      expect(first.isLeft(), isTrue);

      // Next submit must re-create (pending id was cleared), not skip.
      dataSource.activeVehicleError = null;
      final second = await repository.addVehicle(vehicleDto());

      expect(second.isRight(), isTrue);
      expect(dataSource.vehicleJsonCalls, 2);
    });

    test(
      'exhausted retries keep pending id: re-submit never re-creates',
      () async {
        dataSource.activeVehicleError = _dioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/driver/driver/update/'),
            statusCode: 500,
          ),
        );
        final repository = buildRepository();

        final first = await repository.addVehicle(vehicleDto());
        expect(first.isLeft(), isTrue);
        final failure = first.fold((f) => f, (_) => fail('expected Left'));
        // Exhausted timeout/connection retries surface as a network failure.
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, contains('vehicle was saved'));
        expect(dataSource.vehicleJsonCalls, 1);
        expect(dataSource.setActiveVehicleCalls, 3);

        // Driver presses Continue again after fixing connectivity: only
        // activation is retried; the vehicle is NOT duplicated.
        dataSource.activeVehicleError = null;
        final second = await repository.addVehicle(vehicleDto());

        expect(second.isRight(), isTrue);
        expect(dataSource.vehicleJsonCalls, 1);
        expect(dataSource.setActiveVehicleIds.every((id) => id == 7), isTrue);
      },
    );
  });

  group('failure mapping (JSON submission errors)', () {
    test(
      'maps 400 with new-style error envelope to ValidationFailure',
      () async {
        dataSource.addVehicleError = _dioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/driver/vehicles/add/'),
            statusCode: 400,
            data: {
              'status': 'error',
              'error': {
                'code': 'INVALID_RC_DOC',
                'message': 'rc_doc does not exist in storage',
              },
            },
          ),
        );
        final repository = buildRepository();

        final result = await repository.addVehicle(vehicleDto());

        final failure = result.fold((f) => f, (_) => fail('expected Left'));
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'rc_doc does not exist in storage');
      },
    );

    test('maps receiveTimeout to NetworkFailure', () async {
      dataSource.avatarError = _dioException(
        type: DioExceptionType.receiveTimeout,
      );
      final repository = buildRepository();

      final result = await repository.updateAvatar(pngDoc());

      final failure = result.fold((f) => f, (_) => fail('expected Left'));
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('timed out'));
    });

    test('maps SocketException to NetworkFailure', () async {
      dataSource.avatarError = _dioException(
        type: DioExceptionType.connectionError,
        error: const SocketException('Network unreachable'),
      );
      final repository = buildRepository();

      final result = await repository.updateAvatar(pngDoc());

      expect(
        result.fold((f) => f, (_) => fail('expected Left')),
        isA<NetworkFailure>(),
      );
    });

    test('maps 401 to AuthFailure', () async {
      dataSource.avatarError = _dioException(
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/auth/update/'),
          statusCode: 401,
        ),
      );
      final repository = buildRepository();

      final result = await repository.updateAvatar(pngDoc());

      expect(
        result.fold((f) => f, (_) => fail('expected Left')),
        isA<AuthFailure>(),
      );
    });

    test('maps 500 to ServerFailure', () async {
      dataSource.addVehicleError = _dioException(
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/driver/vehicles/add/'),
          statusCode: 500,
        ),
      );
      final repository = buildRepository();

      final result = await repository.addVehicle(vehicleDto());

      expect(
        result.fold((f) => f, (_) => fail('expected Left')),
        isA<ServerFailure>(),
      );
    });
  });

  group('SubmitPersonalDetailsUseCase sequencing', () {
    test('uploads avatar only after personal details succeed', () async {
      uploadService.nextError = const UploadNetworkException('offline');
      final IOnboardingRepository repo = buildRepository();
      final useCase = SubmitPersonalDetailsUseCase(repo);

      final result = await useCase.execute({
        'full_name': 'Test Driver',
        'email': 'driver@example.com',
        'gender': 'male',
        'city': 'Mumbai',
      }, avatar: pngDoc(name: 'me.jpg'));

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) {});
      expect(dataSource.personalDetailBodies.single['gender'], 'male');
      expect(dataSource.avatarKeyCalls, 0); // S3 PUT failed before submit
    });

    test('skips the avatar step when no photo was picked', () async {
      final IOnboardingRepository repo = buildRepository();
      final useCase = SubmitPersonalDetailsUseCase(repo);

      final result = await useCase.execute({'full_name': 'A'});

      expect(result.isRight(), isTrue);
      expect(uploadService.kinds, isEmpty);
      expect(dataSource.avatarKeyCalls, 0);
    });
  });

  group('SubmitBankDetailsUseCase', () {
    test('passes the bank payload through to the repository', () async {
      final IOnboardingRepository repo = buildRepository();
      final useCase = SubmitBankDetailsUseCase(repo);

      final Either<Failure, void> result = await useCase.execute({
        'bank_name': 'SBI',
        'account_number': '12345678901',
        'ifsc_code': 'SBIN0001234',
      });

      expect(result.isRight(), isTrue);
    });
  });
}

class _BlockingCancelStub extends PresignedUploadService {
  _BlockingCancelStub({required this.onToken, required this.release})
    : super(dio: Dio());

  final void Function(CancelToken token) onToken;
  final Future<void> release;

  @override
  Future<S3UploadResult> upload({
    required UploadKind kind,
    required Uint8List bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken != null) {
      onToken(cancelToken);
    }
    await release;
    return const S3UploadResult(key: 'rc_docs/abc123.png');
  }
}
