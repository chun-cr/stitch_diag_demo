import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/utils/logger.dart';
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
  Size? outputImageSize,
  bool includeSourceImage = true,
}) async {
  if (normalizedLandmarks.isEmpty) {
    return sourceImagePath;
  }

  final sourceFile = File(sourceImagePath);

  ui.Codec? codec;
  ui.Image? sourceImage;
  ui.Image? renderedImage;

  try {
    late final Size canvasSize;
    if (includeSourceImage) {
      final sourceBytes = await sourceFile.readAsBytes();
      codec = await ui.instantiateImageCodec(sourceBytes);
      final frame = await codec.getNextFrame();
      sourceImage = frame.image;
      canvasSize = Size(
        sourceImage.width.toDouble(),
        sourceImage.height.toDouble(),
      );
    } else {
      final resolvedSize = outputImageSize ?? analysisImageSize;
      if (resolvedSize.width <= 0 || resolvedSize.height <= 0) {
        throw const FileSystemException(
          'Failed to resolve face frame landmark mask size.',
        );
      }
      canvasSize = resolvedSize;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (sourceImage != null) {
      canvas.drawImage(sourceImage, Offset.zero, Paint());
    }
    FaceLandmarkPainter(
      normalizedLandmarks: normalizedLandmarks,
      imageSize: analysisImageSize.width > 0 && analysisImageSize.height > 0
          ? analysisImageSize
          : canvasSize,
      mirrored: mirrored,
    ).paint(canvas, canvasSize);

    renderedImage = await recorder.endRecording().toImage(
      canvasSize.width.round(),
      canvasSize.height.round(),
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
    await outputFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    final outputBytes = await outputFile.length();
    AppLogger.log(
      'Rendered face frame mask PNG: path=${outputFile.path}, bytes=$outputBytes',
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
