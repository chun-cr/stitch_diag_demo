class ProfilePointsAccountSimpleEntity {
  const ProfilePointsAccountSimpleEntity({
    required this.id,
    required this.userId,
    required this.availableAmount,
  });

  final String id;
  final String userId;
  final int availableAmount;

  factory ProfilePointsAccountSimpleEntity.fromJson(Map<String, dynamic> json) {
    return ProfilePointsAccountSimpleEntity(
      id: _normalizedString(json['id']) ?? '',
      userId: _normalizedString(json['userId']) ?? '',
      availableAmount: _normalizedInt(json['availableAmount']),
    );
  }
}

String? _normalizedString(dynamic value) {
  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

int _normalizedInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
