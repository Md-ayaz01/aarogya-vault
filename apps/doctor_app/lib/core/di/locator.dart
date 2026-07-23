import 'package:get_it/get_it.dart';
import '../network/api_client.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
}
