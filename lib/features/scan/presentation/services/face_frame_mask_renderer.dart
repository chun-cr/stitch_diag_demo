import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../../core/utils/logger.dart';
import '../widgets/face_landmark_overlay.dart';

const _maskJpegQuality = 82;
const _maskJpegChroma = img.JpegChroma.yuv420;

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
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (byteData == null) {
      throw const FileSystemException(
        'Failed to encode face frame landmark mask image.',
      );
    }

    final outputFile = File(_buildMaskOutputPath(sourceFile));
    await outputFile.writeAsBytes(
      _jpegBytes(
        width: renderedImage.width,
        height: renderedImage.height,
        data: byteData,
      ),
      flush: true,
    );
    final outputBytes = await outputFile.length();
    AppLogger.log(
      'Rendered face frame mask JPEG: path=${outputFile.path}, bytes=$outputBytes, quality=$_maskJpegQuality',
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
  return '${sourceFile.parent.path}${Platform.pathSeparator}${stem}_mask.jpg';
}

Uint8List _jpegBytes({
  required int width,
  required int height,
  required ByteData data,
}) {
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: data.buffer,
    bytesOffset: data.offsetInBytes,
    rowStride: width * 4,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return img.encodeJpg(
    image,
    quality: _maskJpegQuality,
    chroma: _maskJpegChroma,
  );
}
