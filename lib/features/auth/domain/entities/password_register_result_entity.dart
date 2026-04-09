import 'auth_session_entity.dart';
import 'verification_code_challenge_entity.dart';

enum PasswordRegisterResultType { registered, verificationCodeRequired }

class PasswordRegisterResultEntity {
  const PasswordRegisterResultEntity({
    required this.result,
    required this.session,
    required this.challenge,
  });

  final PasswordRegisterResultType result;
  final AuthSessionEntity? session;
  final VerificationCodeChallengeEntity? challenge;
}
