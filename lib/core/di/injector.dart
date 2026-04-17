import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../network/auth_session_store.dart';
import '../security/login_password_store.dart';
import '../../features/scan/data/models/scan_session.dart';

final getIt = GetIt.instance;

void initInjector() {
  if (!getIt.isRegistered<AuthSessionStore>()) {
    getIt.registerLazySingleton<AuthSessionStore>(() => AuthSessionStore());
  }
  if (!getIt.isRegistered<LoginPasswordStore>()) {
    getIt.registerLazySingleton<LoginPasswordStore>(() => LoginPasswordStore());
  }
  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerLazySingleton<DioClient>(() => DioClient());
  }
  if (!getIt.isRegistered<ScanSession>()) {
    getIt.registerLazySingleton<ScanSession>(() => ScanSession());
  }
}
