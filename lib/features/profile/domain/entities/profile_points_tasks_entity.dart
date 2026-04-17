import 'profile_points_task_entity.dart';

class ProfilePointsTasksEntity {
  const ProfilePointsTasksEntity({
    required this.registerTask,
    required this.tasks,
  });

  final ProfilePointsTaskEntity? registerTask;
  final List<ProfilePointsTaskEntity> tasks;

  factory ProfilePointsTasksEntity.fromJson(Map<String, dynamic> json) {
    final registerTaskJson = json['registerTask'];
    final tasksJson = json['tasks'];
    return ProfilePointsTasksEntity(
      registerTask: registerTaskJson is Map
          ? ProfilePointsTaskEntity.fromJson(
              Map<String, dynamic>.from(registerTaskJson),
            )
          : null,
      tasks: tasksJson is List
          ? tasksJson
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(ProfilePointsTaskEntity.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}
