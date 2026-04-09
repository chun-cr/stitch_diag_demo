import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/password_register_result_entity.dart';
import '../../domain/entities/verification_code_challenge_entity.dart';
import '../../domain/entities/verification_code_send_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_request.dart';
import '../models/password_register_result_model.dart';
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

  @override
  Future<PasswordRegisterResultEntity> registerPassword(
    AuthRequest request,
  ) async {
    final model = await _remoteSource.registerPassword(request);
    return PasswordRegisterResultEntity(
      result:
          model.result ==
              PasswordRegisterResultTypeModel.verificationCodeRequired
          ? PasswordRegisterResultType.verificationCodeRequired
          : PasswordRegisterResultType.registered,
      session: model.session == null
          ? null
          : AuthSessionEntity(
              accessToken: model.session!.accessToken,
              refreshToken: model.session!.refreshToken,
              tokenType: model.session!.tokenType,
              expiresIn: model.session!.expiresIn,
              scope: model.session!.scope,
            ),
      challenge: model.challenge == null
          ? null
          : VerificationCodeChallengeEntity(
              challengeId: model.challenge!.challengeId,
              captchaRequired: model.challenge!.captchaRequired,
              captchaProvider: model.challenge!.captchaProvider,
              captchaPayload: model.challenge!.captchaPayload,
              expireAt: model.challenge!.expireAt,
            ),
    );
  }

  @override
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required String countryCode,
    required String phoneNumber,
  }) async {
    final model = await _remoteSource.createVerificationCodeChallenge(
      scene: scene,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    );
    return VerificationCodeChallengeEntity(
      challengeId: model.challengeId,
      captchaRequired: model.captchaRequired,
      captchaProvider: model.captchaProvider,
      captchaPayload: model.captchaPayload,
      channel: model.channel,
      maskedReceiver: model.maskedReceiver,
      expireAt: model.expireAt,
      resendAt: model.resendAt,
    );
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async {
    final model = await _remoteSource.sendCode(challengeId: challengeId);
    return VerificationCodeSendEntity(
      channel: model.channel,
      maskedReceiver: model.maskedReceiver,
      expireAt: model.expireAt,
      resendAt: model.resendAt,
    );
  }

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) {
    return _remoteSource.verifyVerificationCodeCaptcha(
      challengeId: challengeId,
      captchaProvider: captchaProvider,
      captchaPayload: captchaPayload,
    );
  }

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final model = await _remoteSource.authenticateVerificationCode(
      challengeId: challengeId,
      verificationCode: verificationCode,
      inviteTicket: inviteTicket,
    );
    return AuthSessionEntity(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      tokenType: model.tokenType,
      expiresIn: model.expiresIn,
      scope: model.scope,
    );
  }
}
