import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'response_security_codec.dart';

class SecureResponseTransformer extends BackgroundTransformer {
  @override
  Future<dynamic> transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    if (!_isEncryptedJsonResponse(responseBody.headers)) {
      return super.transformResponse(options, responseBody);
    }

    final responseType = options.responseType;
    if (responseType == ResponseType.stream) {
      return responseBody;
    }

    final responseBytes = await _readBytes(responseBody.stream);
    if (responseType == ResponseType.bytes) {
      return responseBytes;
    }

    final response = await _decodeResponse(
      responseBytes,
      options,
      responseBody,
    );
    if (response == null || response.trim().isEmpty) {
      return response;
    }

    return ResponseSecurityCodec.decryptJsonPayload(
      _normalizeEncryptedPayload(response),
    );
  }

  bool _isEncryptedJsonResponse(Map<String, List<String>> headers) {
    final contentType = _resolveHeaderValue(headers, Headers.contentTypeHeader);
    if (!Transformer.isJsonMimeType(contentType)) {
      return false;
    }
    return _resolveHeaderValue(headers, 'X-Security') == '1';
  }

  String? _resolveHeaderValue(Map<String, List<String>> headers, String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase() &&
          entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }

  Future<Uint8List> _readBytes(Stream<Uint8List> stream) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<String?> _decodeResponse(
    Uint8List responseBytes,
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    if (options.responseDecoder != null) {
      final decoded = options.responseDecoder!(
        responseBytes,
        options,
        responseBody..stream = const Stream.empty(),
      );
      if (decoded is Future<String?>) {
        return decoded;
      }
      return decoded;
    }
    if (responseBytes.isEmpty) {
      return null;
    }
    return utf8.decode(responseBytes, allowMalformed: true);
  }

  String _normalizeEncryptedPayload(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is String) {
          return decoded;
        }
      } on FormatException {
        return trimmed;
      }
    }
    return trimmed;
  }
}
