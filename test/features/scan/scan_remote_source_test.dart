import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/features/scan/data/sources/scan_remote_source.dart';

class _StubResponse {
  const _StubResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class _QueueHttpClientAdapter implements HttpClientAdapter {
  _QueueHttpClientAdapter(this._responses);

  final List<_StubResponse> _responses;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('scan_remote_source_test');
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createFile(String name) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(const <int>[1, 2, 3, 4]);
    return file;
  }

  ScanRemoteSource createSource(_QueueHttpClientAdapter adapter) {
    final dioClient = DioClient();
    dioClient.dio.interceptors.clear();
    dioClient.dio.httpClientAdapter = adapter;
    return ScanRemoteSource(dioClient);
  }

  test('uploadFace posts to the face upload endpoint', () async {
    final file = await createFile('face.jpg');
    final adapter = _QueueHttpClientAdapter(<_StubResponse>[
      const _StubResponse(200, <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{},
      }),
    ]);
    final source = createSource(adapter);

    await source.uploadFace(faceFilePath: file.path);

    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.path,
      '/api/v1/saas/mobile/ai/diagnosis/upload/face',
    );
  });

  test(
    'uploadTongue throws detailed exception for business failure envelope',
    () async {
      final file = await createFile('tongue.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 9001,
          'message': 'tongue upload failed',
          'messageKey': 'POINTLESS',
          'requestId': 'req-business',
        }),
      ]);
      final source = createSource(adapter);

      await expectLater(
        () => source.uploadTongue(imageFilePath: file.path),
        throwsA(
          isA<ScanUploadException>()
              .having((error) => error.stage, 'stage', 'tongue')
              .having((error) => error.businessCode, 'businessCode', 9001)
              .having(
                (error) => error.message,
                'message',
                'tongue upload failed',
              )
              .having((error) => error.messageKey, 'messageKey', 'POINTLESS')
              .having((error) => error.requestId, 'requestId', 'req-business'),
        ),
      );
    },
  );

  test(
    'uploadPalm throws detailed exception for http failure response',
    () async {
      final file = await createFile('palm.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(400, <String, dynamic>{
          'code': 40101,
          'message': 'refresh token expired',
          'messageKey': 'AUTH_REFRESH_EXPIRED',
          'requestId': 'req-http',
        }),
      ]);
      final source = createSource(adapter);

      await expectLater(
        () => source.uploadPalm(handFilePath: file.path),
        throwsA(
          isA<ScanUploadException>()
              .having((error) => error.stage, 'stage', 'palm')
              .having((error) => error.statusCode, 'statusCode', 400)
              .having((error) => error.businessCode, 'businessCode', 40101)
              .having(
                (error) => error.message,
                'message',
                'refresh token expired',
              )
              .having(
                (error) => error.messageKey,
                'messageKey',
                'AUTH_REFRESH_EXPIRED',
              )
              .having((error) => error.requestId, 'requestId', 'req-http'),
        ),
      );
    },
  );
}
