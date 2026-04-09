import '../../../../core/network/dio_client.dart';
import '../models/auth_request.dart';
import '../models/auth_session_model.dart';

class AuthRemoteSource {
  final DioClient _dioClient;

  AuthRemoteSource(this._dioClient);

  Future<AuthSessionModel> login(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login/password',
      data: request.toJson(),
    );
    return AuthSessionModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AuthSessionModel> register(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/password',
      data: request.toJson(),
    );
    return AuthSessionModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
