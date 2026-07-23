// lib/core/di/di.dart
import 'package:get_it/get_it.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  // Register ApiClient as a lazy singleton
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // Register AuthRepository implementation
  getIt.registerFactory<AuthRepository>(() => AuthRepositoryImpl(apiClient: getIt<ApiClient>()));
}
