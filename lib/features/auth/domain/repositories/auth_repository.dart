import '../entities/auth_session_entity.dart';
import '../../data/models/auth_request.dart';

abstract class AuthRepository {
  Future<AuthSessionEntity> login(AuthRequest request);
  Future<AuthSessionEntity> register(AuthRequest request);
}
