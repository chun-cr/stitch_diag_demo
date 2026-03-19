import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS project uses shared assets model sources only', () {
    final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
    final projectText = projectFile.readAsStringSync();

    expect(
      projectText,
      contains('path = ../../assets/models/face_landmarker.task;'),
    );
    expect(
      projectText,
      contains('path = ../../assets/models/gesture_recognizer.task;'),
    );

    final runnerTaskFiles = Directory('ios/Runner')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.task'))
        .toList();

    expect(runnerTaskFiles, isEmpty);
  });
}
