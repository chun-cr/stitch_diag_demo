import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/face_landmark_overlay.dart';

bool shouldMirrorFaceFrameMask({
  required TargetPlatform platform,
  required bool isBackCamera,
}) {
  return platform == TargetPlatform.android && !isBackCamera;
}

Future<String> renderFaceFrameMaskFile({
  required String sourceImagePath,
  required List<Offset> normalizedLandmarks,
  required Size analysisImageSize,
  required bool mirrored,
}) async {
  if (normalizedLandmarks.isEmpty) {
    return sourceImagePath;
  }

  final sourceFile = File(sourceImagePath);
  final sourceBytes = await sourceFile.readAsBytes();

  ui.Codec? codec;
  ui.Image? sourceImage;
  ui.Image? renderedImage;

  try {
    codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    sourceImage = frame.image;

    final canvasSize = Size(
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(sourceImage, Offset.zero, Paint());
    FaceLandmarkPainter(
      normalizedLandmarks: normalizedLandmarks,
      imageSize: analysisImageSize.width > 0 && analysisImageSize.height > 0
          ? analysisImageSize
          : canvasSize,
      mirrored: mirrored,
    ).paint(canvas, canvasSize);

    renderedImage = await recorder.endRecording().toImage(
      sourceImage.width,
      sourceImage.height,
    );
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw const FileSystemException(
        'Failed to encode face frame landmark mask image.',
      );
    }

    final outputFile = File(_buildMaskOutputPath(sourceFile));
    await outputFile.writeAsBytes(
      _pngBytes(byteData),
      flush: true,
    );
    return outputFile.path;
  } finally {
    codec?.dispose();
    sourceImage?.dispose();
    renderedImage?.dispose();
  }
}

String _buildMaskOutputPath(File sourceFile) {
  final fileName = sourceFile.uri.pathSegments.isNotEmpty
      ? sourceFile.uri.pathSegments.last
      : sourceFile.path.split(Platform.pathSeparator).last;
  final extensionIndex = fileName.lastIndexOf('.');
  final stem = extensionIndex > 0
      ? fileName.substring(0, extensionIndex)
      : fileName;
  return '${sourceFile.parent.path}${Platform.pathSeparator}${stem}_mask.png';
}

Uint8List _pngBytes(ByteData data) {
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
