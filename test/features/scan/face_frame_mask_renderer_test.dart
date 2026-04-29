import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/face_frame_mask_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'face_frame_mask_renderer_test',
    );
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createSourceImage(String name) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 120, 120),
      Paint()..color = const Color(0xFF1A1A1A),
    );
    final image = await recorder.endRecording().toImage(120, 120);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(
      bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return file;
  }

  test('returns original frame path when no landmarks are available', () async {
    final sourceFile = await createSourceImage('face-source.png');

    final outputPath = await renderFaceFrameMaskFile(
      sourceImagePath: sourceFile.path,
      normalizedLandmarks: const [],
      analysisImageSize: const Size(120, 120),
      mirrored: false,
    );

    expect(outputPath, sourceFile.path);
  });

  test('renders a face landmark mask file beside the source image', () async {
    final sourceFile = await createSourceImage('face-source-with-mask.png');

    final outputPath = await renderFaceFrameMaskFile(
      sourceImagePath: sourceFile.path,
      normalizedLandmarks: List<Offset>.generate(
        468,
        (index) => Offset(
          0.2 + (index % 18) * 0.03,
          0.2 + (index ~/ 18) * 0.02,
        ),
      ),
      analysisImageSize: const Size(120, 120),
      mirrored: false,
    );

    expect(outputPath, isNot(sourceFile.path));
    expect(outputPath, endsWith('_mask.jpg'));
    final outputFile = File(outputPath);
    expect(outputFile.existsSync(), isTrue);
    final outputBytes = outputFile.readAsBytesSync();
    expect(outputBytes.length, greaterThan(2));
    expect(outputBytes[0], 0xFF);
    expect(outputBytes[1], 0xD8);
  });
}
