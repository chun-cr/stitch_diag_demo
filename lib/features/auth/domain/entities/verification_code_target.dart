enum VerificationCodeTargetType { phone, email }

class VerificationCodeTarget {
  const VerificationCodeTarget.phone({
    required this.value,
    required this.countryCode,
  }) : type = VerificationCodeTargetType.phone,
       assert(countryCode != null);

  const VerificationCodeTarget.email({required this.value})
    : type = VerificationCodeTargetType.email,
      countryCode = null;

  final VerificationCodeTargetType type;
  final String value;
  final String? countryCode;

  bool get isEmail => type == VerificationCodeTargetType.email;
}
