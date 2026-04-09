import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_request.dart';
import '../models/auth_session_model.dart';
import '../models/password_register_result_model.dart';
import '../models/verification_code_challenge_model.dart';
import '../models/verification_code_send_model.dart';

class AuthRemoteSource {
  final DioClient _dioClient;

  AuthRemoteSource(this._dioClient);

  Map<String, dynamic> _dataMap(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const FormatException('Invalid response envelope');
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing response data');
    }
    return data;
  }

  String _sceneValue(VerificationCodeScene scene) {
    return switch (scene) {
      VerificationCodeScene.login => 'LOGIN',
      VerificationCodeScene.register => 'REGISTER',
    };
  }

  Future<AuthSessionModel> login(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login/password',
      data: request.toJson(),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<AuthSessionModel> register(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/password',
      data: request.toJson(),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<PasswordRegisterResultModel> registerPassword(
    AuthRequest request,
  ) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/password',
      data: request.toJson(),
    );
    return PasswordRegisterResultModel.fromJson(_dataMap(response.data));
  }

  Future<VerificationCodeChallengeModel> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required String countryCode,
    required String phoneNumber,
  }) async {
    final response = await _dioClient.dio.post(
      scene == VerificationCodeScene.register
          ? '/api/v1/saas/mobile/auth/register/verification-code/challenge'
          : '/api/v1/saas/mobile/auth/verification-code/challenge',
      data: scene == VerificationCodeScene.register
          ? {'countryCode': countryCode, 'phoneNumber': phoneNumber}
          : {
              'scene': _sceneValue(scene),
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
            },
    );
    return VerificationCodeChallengeModel.fromJson(_dataMap(response.data));
  }

  Future<VerificationCodeSendModel> sendCode({
    required String challengeId,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/verification-code/send',
      data: {'challengeId': challengeId},
    );
    return VerificationCodeSendModel.fromJson(_dataMap(response.data));
  }

  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/verification-code/captcha/verify',
      data: {
        'challengeId': challengeId,
        'captchaProvider': captchaProvider,
        'captchaPayload': captchaPayload,
      },
    );
    return _dataMap(response.data)['captchaVerified'] == true;
  }

  Future<AuthSessionModel> authenticateVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/verification-code/authenticate',
      data: {
        'challengeId': challengeId,
        'verificationCode': verificationCode,
        if (inviteTicket != null && inviteTicket.isNotEmpty)
          'inviteTicket': inviteTicket,
      },
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }
}
