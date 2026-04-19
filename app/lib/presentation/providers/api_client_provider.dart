import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/local/local_storage.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return ApiClient(localStorage: localStorage);
});
