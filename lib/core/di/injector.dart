import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../network/auth_session_store.dart';

final getIt = GetIt.instance;

void initInjector() {
  if (!getIt.isRegistered<AuthSessionStore>()) {
    getIt.registerLazySingleton<AuthSessionStore>(() => AuthSessionStore());
  }
  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerLazySingleton<DioClient>(() => DioClient());
  }
}
