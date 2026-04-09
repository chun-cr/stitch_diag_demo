import '../../data/models/auth_request.dart';
import '../entities/auth_session_entity.dart';
import '../entities/password_register_result_entity.dart';
import '../entities/verification_code_challenge_entity.dart';
import '../entities/verification_code_send_entity.dart';

enum VerificationCodeScene { login, register }

abstract class AuthRepository {
  Future<AuthSessionEntity> login(AuthRequest request);
  Future<AuthSessionEntity> register(AuthRequest request);
  Future<PasswordRegisterResultEntity> registerPassword(AuthRequest request);
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required String countryCode,
    required String phoneNumber,
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
}
