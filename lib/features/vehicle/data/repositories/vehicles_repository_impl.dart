import '../../../../core/uploads/mime_resolver.dart';
import '../../../../core/uploads/presigned_upload_service.dart';
import '../../../../core/uploads/upload_kind.dart';
import '../../../../domain/models/vehicle_model.dart';
import '../../../onboarding/data/models/vehicle_request_dto.dart';
import '../../domain/repositories/vehicles_repository.dart';
import '../data_sources/vehicles_remote_data_source.dart';

class VehiclesRepositoryImpl implements VehiclesRepository {
  final VehiclesRemoteDataSource remoteDataSource;
  final PresignedUploadService? _uploadService;
  final MimeTypeResolver _mimeTypeResolver;

  VehiclesRepositoryImpl(
    this.remoteDataSource, {
    PresignedUploadService? uploadService,
    MimeTypeResolver? mimeTypeResolver,
  }) : _uploadService = uploadService,
       _mimeTypeResolver = mimeTypeResolver ?? const MimeTypeResolver();

  @override
  Future<List<VehicleModel>> getVehicles() async {
    return await remoteDataSource.getVehicles();
  }

  @override
  Future<void> switchActiveVehicle(int vehicleId) async {
    await remoteDataSource.switchActiveVehicle(vehicleId);
  }

  @override
  Future<VehicleModel> updateVehicle(
    int vehicleId,
    Map<String, dynamic> data,
  ) async {
    return await remoteDataSource.updateVehicle(vehicleId, data);
  }

  @override
  Future<VehicleModel> addVehicle(
    VehicleRequestDto dto, {
    UploadProgressCallback? onProgress,
  }) async {
    String? rcDocKey = dto.rcDocKey;
    if (dto.rcDocument != null &&
        dto.rcDocument!.isAvailable &&
        _uploadService != null) {
      final bytes = await dto.rcDocument!.resolveBytes();
      final mimeType = _mimeTypeResolver.resolve(
        fileName: dto.rcDocument!.name,
        bytes: bytes,
      );
      if (mimeType != null && UploadKind.rcDoc.allowsMimeType(mimeType)) {
        final uploadResult = await _uploadService.upload(
          kind: UploadKind.rcDoc,
          bytes: bytes,
          mimeType: mimeType,
          onProgress: onProgress,
        );
        rcDocKey = uploadResult.key;
      }
    }

    String? vehiclePicKey;
    if (dto.vehiclePicDocument != null &&
        dto.vehiclePicDocument!.isAvailable &&
        _uploadService != null) {
      final bytes = await dto.vehiclePicDocument!.resolveBytes();
      final mimeType = _mimeTypeResolver.resolve(
        fileName: dto.vehiclePicDocument!.name,
        bytes: bytes,
      );
      if (mimeType != null && UploadKind.vehiclePic.allowsMimeType(mimeType)) {
        final uploadResult = await _uploadService.upload(
          kind: UploadKind.vehiclePic,
          bytes: bytes,
          mimeType: mimeType,
          onProgress: onProgress,
        );
        vehiclePicKey = uploadResult.key;
      }
    }

    final body = <String, dynamic>{
      'vehicle_number': dto.registrationNumber,
      'vehicle_type': dto.vehicleType,
      'make': dto.make,
      'model': dto.model,
      'year': dto.year,
      'color': dto.color,
      'rc_doc': ?rcDocKey,
      'vehicle_pic': ?vehiclePicKey,
    };

    final rawResponse = await remoteDataSource.addVehicleWithKeys(body);
    final map = Map<String, dynamic>.from(rawResponse);

    // Normalize keys in case backend uses 'make' instead of 'brand'
    if (!map.containsKey('brand') && map.containsKey('make')) {
      map['brand'] = map['make'];
    }
    if (!map.containsKey('vehicle_number') &&
        map.containsKey('registration_number')) {
      map['vehicle_number'] = map['registration_number'];
    }
    if (!map.containsKey('vehicle_type')) {
      map['vehicle_type'] = dto.vehicleType;
    }

    final vehicle = VehicleModel.fromJson(map);

    if (dto.setAsActive != false && vehicle.id > 0) {
      await switchActiveVehicle(vehicle.id);
    }

    return vehicle;
  }
}
