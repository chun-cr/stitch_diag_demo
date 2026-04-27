import '../../../../core/network/dio_client.dart';
import '../../domain/entities/verification_code_target.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_request.dart';
import '../models/auth_session_model.dart';
import '../models/password_register_result_model.dart';
import '../models/verification_code_challenge_model.dart';
import '../models/verification_code_send_model.dart';
import '../models/wechat_mini_program_auth_result_model.dart';

class AuthRemoteSource {
  final DioClient _dioClient;

  AuthRemoteSource(this._dioClient);

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

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

  Map<String, dynamic> _loginPayload(AuthRequest request) {
    final loginValue = request.phoneNumber.trim();
    final password = _trimmedOrNull(request.password);
    final countryCode = _trimmedOrNull(request.countryCode);
    final inviteTicket = _trimmedOrNull(request.inviteTicket);
    final payload = <String, dynamic>{'loginValue': loginValue};
    if (countryCode != null) {
      payload['countryCode'] = countryCode;
    }
    if (password != null) {
      payload['password'] = password;
    }
    if (inviteTicket != null) {
      payload['inviteTicket'] = inviteTicket;
    }
    return payload;
  }

  Map<String, dynamic> _passwordRegisterPayload(AuthRequest request) {
    final password = _trimmedOrNull(request.password);
    final payload = <String, dynamic>{
      'countryCode': request.countryCode.trim(),
      'phoneNumber': request.phoneNumber.trim(),
    };
    if (password != null) {
      payload['password'] = password;
    }
    return payload;
  }

  Future<AuthSessionModel> login(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login/password',
      data: _loginPayload(request),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<AuthSessionModel> register(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/password',
      data: _passwordRegisterPayload(request),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<WechatMiniProgramAuthResultModel> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  }) async {
    final normalizedInviteTicket = _trimmedOrNull(inviteTicket);
    final payload = <String, dynamic>{
      'appId': DioClient.wechatMiniProgramAppId,
      'wechatCode': wechatCode.trim(),
      'inviteTicket': normalizedInviteTicket,
    }..removeWhere((key, value) => value == null);
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login/wechat-mini-program',
      data: payload,
    );
    return WechatMiniProgramAuthResultModel.fromJson(_dataMap(response.data));
  }

  Future<PasswordRegisterResultModel> registerPassword(
    AuthRequest request,
  ) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/password',
      data: _passwordRegisterPayload(request),
    );
    return PasswordRegisterResultModel.fromJson(_dataMap(response.data));
  }

  Future<VerificationCodeChallengeModel> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  }) async {
    final loginValue = _trimmedOrNull(target.value) ?? '';
    final normalizedCountryCode = _trimmedOrNull(target.countryCode);
    final challengePayload = <String, dynamic>{
      'scene': _sceneValue(scene),
      'phoneNumber': loginValue,
      'loginValue': loginValue,
    };
    if (normalizedCountryCode != null) {
      challengePayload['countryCode'] = normalizedCountryCode;
    }
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/verification-code/challenge',
      data: challengePayload,
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
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login-or-register/verification-code',
      data: {
        'challengeId': challengeId,
        'verificationCode': verificationCode,
        if (inviteTicket != null && inviteTicket.isNotEmpty)
          'inviteTicket': inviteTicket,
      },
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<void> logout({required String refreshToken}) async {
    await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
