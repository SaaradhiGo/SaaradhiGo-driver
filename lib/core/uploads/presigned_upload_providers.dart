import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'presigned_upload_service.dart';

final presignedUploadServiceProvider = Provider<PresignedUploadService>((ref) {
  return PresignedUploadService(dio: ref.watch(dioClientProvider).dio);
});
