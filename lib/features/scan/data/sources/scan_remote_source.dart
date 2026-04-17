import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';

class ScanUploadException implements Exception {
  const ScanUploadException({
    required this.stage,
    required this.path,
    required this.message,
    this.statusCode,
    this.businessCode,
    this.messageKey,
    this.requestId,
    this.responseBody,
  });

  factory ScanUploadException.fromDioException({
    required String stage,
    required String path,
    required DioException error,
  }) {
    final responseData = error.response?.data;
    final envelope = responseData is Map<String, dynamic>
        ? responseData
        : responseData is Map
        ? Map<String, dynamic>.from(responseData)
        : null;

    return ScanUploadException(
      stage: stage,
      path: path,
      message:
          envelope?['message'] as String? ??
          error.message ??
          'Unknown network upload error.',
      statusCode: error.response?.statusCode,
      businessCode: (envelope?['code'] as num?)?.toInt(),
      messageKey: envelope?['messageKey'] as String?,
      requestId: envelope?['requestId'] as String?,
      responseBody: responseData,
    );
  }

  final String stage;
  final String path;
  final String message;
  final int? statusCode;
  final int? businessCode;
  final String? messageKey;
  final String? requestId;
  final Object? responseBody;

  String get debugDescription {
    final buffer = StringBuffer()
      ..writeln('stage: $stage')
      ..writeln('path: $path')
      ..writeln('message: $message');
    if (statusCode != null) {
      buffer.writeln('httpStatus: $statusCode');
    }
    if (businessCode != null) {
      buffer.writeln('businessCode: $businessCode');
    }
    if (messageKey != null && messageKey!.isNotEmpty) {
      buffer.writeln('messageKey: $messageKey');
    }
    if (requestId != null && requestId!.isNotEmpty) {
      buffer.writeln('requestId: $requestId');
    }
    if (responseBody != null) {
      buffer.writeln('responseBody: ${_stringify(responseBody)}');
    }
    return buffer.toString().trimRight();
  }

  static String _stringify(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is String) {
      return value;
    }
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }

  @override
  String toString() => debugDescription;
}

class ScanRemoteSource {
  ScanRemoteSource(this._dioClient);

  final DioClient _dioClient;

  Future<void> uploadFace({
    required String faceFilePath,
    String? faceFrameFilePath,
    ProgressCallback? onSendProgress,
  }) async {
    const path = '/api/v1/saas/mobile/ai/diagnosis/upload/face';
    await _postMultipart(
      stage: 'face',
      path: path,
      data: FormData.fromMap({
        'faceFile': await MultipartFile.fromFile(
          faceFilePath,
          filename: _fileName(faceFilePath),
        ),
        'faceFrameFile': await MultipartFile.fromFile(
          faceFrameFilePath ?? faceFilePath,
          filename: _fileName(faceFrameFilePath ?? faceFilePath),
        ),
      }),
      onSendProgress: onSendProgress,
    );
  }

  Future<void> uploadTongue({
    required String imageFilePath,
    ProgressCallback? onSendProgress,
  }) async {
    const path = '/api/v1/saas/mobile/ai/diagnosis/upload';
    await _postMultipart(
      stage: 'tongue',
      path: path,
      data: FormData.fromMap({
        'imageFile': await MultipartFile.fromFile(
          imageFilePath,
          filename: _fileName(imageFilePath),
        ),
      }),
      onSendProgress: onSendProgress,
    );
  }

  Future<void> uploadPalm({
    required String handFilePath,
    String? handFrameFilePath,
    ProgressCallback? onSendProgress,
  }) async {
    const path = '/api/v1/saas/mobile/ai/diagnosis/upload/hand';
    await _postMultipart(
      stage: 'palm',
      path: path,
      data: FormData.fromMap({
        'handFile': await MultipartFile.fromFile(
          handFilePath,
          filename: _fileName(handFilePath),
        ),
        'handFrameFile': await MultipartFile.fromFile(
          handFrameFilePath ?? handFilePath,
          filename: _fileName(handFrameFilePath ?? handFilePath),
        ),
      }),
      onSendProgress: onSendProgress,
    );
  }

  Future<void> _postMultipart({
    required String stage,
    required String path,
    required FormData data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dioClient.dio.post<dynamic>(
        path,
        data: data,
        onSendProgress: onSendProgress,
      );
      _ensureSuccessEnvelope(stage: stage, path: path, data: response.data);
    } on DioException catch (error) {
      final exception = ScanUploadException.fromDioException(
        stage: stage,
        path: path,
        error: error,
      );
      AppLogger.log('Scan upload failed: ${exception.debugDescription}');
      throw exception;
    }
  }

  void _ensureSuccessEnvelope({
    required String stage,
    required String path,
    required dynamic data,
  }) {
    if (data is! Map<String, dynamic>) {
      throw ScanUploadException(
        stage: stage,
        path: path,
        message: 'Invalid response envelope.',
        responseBody: data,
      );
    }

    final businessCode = (data['code'] as num?)?.toInt();
    if (businessCode != null && businessCode != 0) {
      throw ScanUploadException(
        stage: stage,
        path: path,
        message: data['message'] as String? ?? 'Upload request failed.',
        businessCode: businessCode,
        messageKey: data['messageKey'] as String?,
        requestId: data['requestId'] as String?,
        responseBody: data,
      );
    }
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }
}
