import 'profile_points_entry_entity.dart';

class ProfilePointsLogPageEntity {
  const ProfilePointsLogPageEntity({
    required this.records,
    required this.total,
    required this.pageNo,
    required this.pageSize,
  });

  final List<ProfilePointsEntryEntity> records;
  final int total;
  final int pageNo;
  final int pageSize;

  bool get hasMore => records.length < total;

  factory ProfilePointsLogPageEntity.fromJson(Map<String, dynamic> json) {
    final records = json['records'];
    return ProfilePointsLogPageEntity(
      records: records is List
          ? records
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(ProfilePointsEntryEntity.fromJson)
                .toList(growable: false)
          : const [],
      total: _normalizedInt(json['total']),
      pageNo: _normalizedInt(json['pageNo']),
      pageSize: _normalizedInt(json['pageSize']),
    );
  }
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
