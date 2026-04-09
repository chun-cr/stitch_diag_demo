class VerificationCodeChallengeEntity {
  final String challengeId;
  final bool captchaRequired;
  final String? captchaProvider;
  final Map<String, dynamic>? captchaPayload;
  final String? channel;
  final String? maskedReceiver;
  final DateTime? expireAt;
  final DateTime? resendAt;

  const VerificationCodeChallengeEntity({
    required this.challengeId,
    required this.captchaRequired,
    required this.captchaProvider,
    required this.captchaPayload,
    this.channel,
    this.maskedReceiver,
    required this.expireAt,
    this.resendAt,
  });
}
