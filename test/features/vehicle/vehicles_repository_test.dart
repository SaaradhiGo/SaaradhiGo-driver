import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:saaradhigo_driver/core/uploads/presigned_upload_service.dart';
import 'package:saaradhigo_driver/core/uploads/upload_exceptions.dart';
import 'package:saaradhigo_driver/core/uploads/upload_kind.dart';
import 'package:saaradhigo_driver/domain/models/vehicle_model.dart';
import 'package:saaradhigo_driver/features/onboarding/data/models/picked_document.dart';
import 'package:saaradhigo_driver/features/onboarding/data/models/vehicle_request_dto.dart';
import 'package:saaradhigo_driver/features/vehicle/data/data_sources/vehicles_remote_data_source.dart';
import 'package:saaradhigo_driver/features/vehicle/data/repositories/vehicles_repository_impl.dart';

class MockVehiclesRemoteDataSource extends Mock
    implements VehiclesRemoteDataSource {
  @override
  Future<List<VehicleModel>> getVehicles() =>
      super.noSuchMethod(
            Invocation.method(#getVehicles, []),
            returnValue: Future.value(<VehicleModel>[]),
          )
          as Future<List<VehicleModel>>;

  @override
  Future<void> switchActiveVehicle(int? vehicleId) =>
      super.noSuchMethod(
            Invocation.method(#switchActiveVehicle, [vehicleId]),
            returnValue: Future.value(),
          )
          as Future<void>;

  @override
  Future<VehicleModel> updateVehicle(
    int? vehicleId,
    Map<String, dynamic>? data,
  ) =>
      super.noSuchMethod(
            Invocation.method(#updateVehicle, [vehicleId, data]),
            returnValue: Future.value(
              const VehicleModel(
                id: 1,
                vehicleNumber: 'TS07AB1234',
                vehicleType: 'sedan',
              ),
            ),
          )
          as Future<VehicleModel>;

  @override
  Future<Map<String, dynamic>> addVehicleWithKeys(Map<String, dynamic>? body) =>
      super.noSuchMethod(
            Invocation.method(#addVehicleWithKeys, [body]),
            returnValue: Future.value(<String, dynamic>{}),
          )
          as Future<Map<String, dynamic>>;
}

class MockPresignedUploadService extends Mock
    implements PresignedUploadService {
  @override
  Future<S3UploadResult> upload({
    required UploadKind? kind,
    required Uint8List? bytes,
    required String? mimeType,
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) =>
      super.noSuchMethod(
            Invocation.method(#upload, [], {
              #kind: kind,
              #bytes: bytes,
              #mimeType: mimeType,
              #onProgress: onProgress,
              #cancelToken: cancelToken,
            }),
            returnValue: Future.value(const S3UploadResult(key: 'mock-s3-key')),
          )
          as Future<S3UploadResult>;
}

void main() {
  late MockVehiclesRemoteDataSource mockRemoteDataSource;
  late MockPresignedUploadService mockUploadService;
  late VehiclesRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockVehiclesRemoteDataSource();
    mockUploadService = MockPresignedUploadService();
    repository = VehiclesRepositoryImpl(
      mockRemoteDataSource,
      uploadService: mockUploadService,
    );
  });

  test('getVehicles delegates to remoteDataSource', () async {
    when(mockRemoteDataSource.getVehicles()).thenAnswer(
      (_) async => [
        const VehicleModel(
          id: 1,
          vehicleNumber: 'TS07AB1234',
          vehicleType: 'sedan',
        ),
      ],
    );

    final result = await repository.getVehicles();
    expect(result.length, equals(1));
    expect(result.first.vehicleNumber, equals('TS07AB1234'));
    verify(mockRemoteDataSource.getVehicles()).called(1);
  });

  test('switchActiveVehicle delegates to remoteDataSource', () async {
    when(mockRemoteDataSource.switchActiveVehicle(10)).thenAnswer((_) async {});

    await repository.switchActiveVehicle(10);
    verify(mockRemoteDataSource.switchActiveVehicle(10)).called(1);
  });

  test('addVehicle uploads documents and auto-activates vehicle', () async {
    final rcDoc = PickedDocument(
      name: 'rc_book.pdf',
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]), // %PDF
    );

    final vehiclePic = PickedDocument(
      name: 'car.jpg',
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]), // JPEG magic bytes
    );

    when(
      mockUploadService.upload(
        kind: UploadKind.rcDoc,
        bytes: anyNamed('bytes'),
        mimeType: anyNamed('mimeType'),
        onProgress: anyNamed('onProgress'),
      ),
    ).thenAnswer((_) async => const S3UploadResult(key: 's3/rc_book.pdf'));

    when(
      mockUploadService.upload(
        kind: UploadKind.vehiclePic,
        bytes: anyNamed('bytes'),
        mimeType: anyNamed('mimeType'),
        onProgress: anyNamed('onProgress'),
      ),
    ).thenAnswer((_) async => const S3UploadResult(key: 's3/car.jpg'));

    when(mockRemoteDataSource.addVehicleWithKeys(any)).thenAnswer(
      (_) async => {
        'id': 99,
        'vehicle_number': 'TS09CD5678',
        'vehicle_type': 'suv',
        'make': 'Toyota',
        'model': 'Innova',
        'color': 'Silver',
        'year': 2023,
        'rc_doc': 's3/rc_book.pdf',
        'vehicle_pic': 's3/car.jpg',
      },
    );

    when(mockRemoteDataSource.switchActiveVehicle(99)).thenAnswer((_) async {});

    final dto = VehicleRequestDto(
      registrationNumber: 'TS09CD5678',
      vehicleType: 'suv',
      make: 'Toyota',
      model: 'Innova',
      year: 2023,
      color: 'Silver',
      rcDocument: rcDoc,
      vehiclePicDocument: vehiclePic,
      setAsActive: true,
    );

    final created = await repository.addVehicle(dto);

    expect(created.id, equals(99));
    expect(created.vehicleNumber, equals('TS09CD5678'));
    expect(created.brand, equals('Toyota'));
    expect(created.model, equals('Innova'));

    verify(
      mockUploadService.upload(
        kind: UploadKind.rcDoc,
        bytes: anyNamed('bytes'),
        mimeType: anyNamed('mimeType'),
        onProgress: anyNamed('onProgress'),
      ),
    ).called(1);

    verify(
      mockUploadService.upload(
        kind: UploadKind.vehiclePic,
        bytes: anyNamed('bytes'),
        mimeType: anyNamed('mimeType'),
        onProgress: anyNamed('onProgress'),
      ),
    ).called(1);

    verify(mockRemoteDataSource.addVehicleWithKeys(any)).called(1);
    verify(mockRemoteDataSource.switchActiveVehicle(99)).called(1);
  });
}
