class VerificationCodeSendEntity {
  final String channel;
  final String maskedReceiver;
  final DateTime? expireAt;
  final DateTime? resendAt;

  const VerificationCodeSendEntity({
    required this.channel,
    required this.maskedReceiver,
    required this.expireAt,
    required this.resendAt,
  });
}
