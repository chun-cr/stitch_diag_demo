import '../../domain/entities/auth_session_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_request.dart';
import '../sources/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource _remoteSource;

  AuthRepositoryImpl(this._remoteSource);

  @override
  Future<AuthSessionEntity> login(AuthRequest request) async {
    final model = await _remoteSource.login(request);
    return AuthSessionEntity(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      tokenType: model.tokenType,
      expiresIn: model.expiresIn,
      scope: model.scope,
    );
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) async {
    final model = await _remoteSource.register(request);
    return AuthSessionEntity(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      tokenType: model.tokenType,
      expiresIn: model.expiresIn,
      scope: model.scope,
    );
  }
}
