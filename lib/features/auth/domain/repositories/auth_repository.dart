import '../../data/models/auth_request.dart';
import '../entities/auth_session_entity.dart';
import '../entities/password_register_result_entity.dart';
import '../entities/verification_code_challenge_entity.dart';
import '../entities/verification_code_send_entity.dart';
import '../entities/verification_code_target.dart';
import '../entities/wechat_mini_program_auth_result_entity.dart';

enum VerificationCodeScene { login, register }

abstract class AuthRepository {
  Future<AuthSessionEntity> login(AuthRequest request);
  Future<AuthSessionEntity> register(AuthRequest request);
  Future<PasswordRegisterResultEntity> registerPassword(AuthRequest request);
  Future<WechatMiniProgramAuthResultEntity> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  });

  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  });
  Future<VerificationCodeSendEntity> sendCode({required String challengeId});
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  });
  Future<AuthSessionEntity> authenticateVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  });
  Future<void> logout({required String refreshToken});
}

class AuthRepositoryAdapter implements AuthRepository {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<PasswordRegisterResultEntity> registerPassword(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<WechatMiniProgramAuthResultEntity> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({required String challengeId}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) {
    throw UnimplementedError();
  }
}
