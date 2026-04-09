import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/sources/auth_remote_source.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_repository_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  initInjector();
  final dioClient = getIt<DioClient>();
  final remoteSource = AuthRemoteSource(dioClient);
  return AuthRepositoryImpl(remoteSource);
}
