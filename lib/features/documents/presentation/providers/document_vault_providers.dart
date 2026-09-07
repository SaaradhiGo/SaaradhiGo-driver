import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/documents_remote_data_source.dart';
import '../../data/repositories/documents_repository_impl.dart';
import '../../domain/repositories/documents_repository.dart';
import 'document_vault_notifier.dart';
import 'document_vault_state.dart';

export 'document_vault_notifier.dart';
export 'document_vault_state.dart';

final documentsRemoteDataSourceProvider = Provider<DocumentsRemoteDataSource>((
  ref,
) {
  return DocumentsRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepositoryImpl(ref.watch(documentsRemoteDataSourceProvider));
});

final documentVaultNotifierProvider =
    NotifierProvider<DocumentVaultNotifier, DocumentVaultState>(() {
      return DocumentVaultNotifier();
    });
