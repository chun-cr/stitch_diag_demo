import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/core/platform/app_identity.dart';
import 'package:stitch_diag_demo/features/report/data/sources/report_remote_source.dart';

import 'report_test_data.dart';

typedef _AdapterHandler = ResponseBody Function(RequestOptions options);

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this._handler);

  final _AdapterHandler _handler;

  late RequestOptions lastRequestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return _handler(options);
  }
}

ResponseBody _jsonResponse(Object? data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app/info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAppId');
      return 'com.permillet.myapp.dev';
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    AppIdentity.resetForTest();
  });

  test('getReportShareQrCode hits report share endpoint', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'imageUrl': 'https://example.com/report-share.png',
          'shareUrl': 'https://example.com/report?reportId=report-1',
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getReportShareQrCode('report-1');

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/report-1/share/qrcode',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(result.imageUrl, 'https://example.com/report-share.png');
    expect(result.shareUrl, 'https://example.com/report?reportId=report-1');
  });

  test('getReportShareQrCode accepts scalar url payloads', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': 'https://example.com/report-share.png',
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getReportShareQrCode('report-2');

    expect(result.imageUrl, 'https://example.com/report-share.png');
    expect(result.shareUrl, 'https://example.com/report-share.png');
  });

  test(
    'getAllReports resolves face images from detail when summary payload omits them',
    () async {
      final requestPaths = <String>[];
      final detail = buildDiagnosisReportDetail(
        id: 'report-1',
        imageUrl: 'https://example.com/tongue.png',
        faceImageUrl: 'https://example.com/face.png',
      );
      final dioClient = DioClient();
      final adapter = _CaptureAdapter((options) {
        requestPaths.add(options.path);
        if (options.path == '/api/v1/saas/physiques/reports') {
          return _jsonResponse({
            'code': 0,
            'message': 'ok',
            'data': {
              'datas': [
                {
                  'id': 'report-1',
                  'testTime': '2026-04-17 10:30',
                  'healthScore': 82,
                  'physiqueName': 'Balanced',
                  'imageUrl': 'https://example.com/tongue.png',
                  'lockedStatus': '1',
                  'deepPredicts': const <String, Object>{},
                },
              ],
              'totalCount': 1,
            },
          });
        }

        if (options.path ==
            '/api/v1/saas/mobile/ai/diagnosis/report/report-1') {
          return _jsonResponse({
            'code': 0,
            'message': 'ok',
            'data': detail.raw,
          });
        }

        throw StateError('Unexpected path: ${options.path}');
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ReportRemoteSource(dioClient);

      final result = await remoteSource.getAllReports(resolveFaceImages: true);

      expect(result, hasLength(1));
      expect(result.first.imageUrl, 'https://example.com/tongue.png');
      expect(result.first.faceImageUrl, 'https://example.com/face.png');
      expect(
        requestPaths,
        equals([
          '/api/v1/saas/physiques/reports',
          '/api/v1/saas/mobile/ai/diagnosis/report/report-1',
        ]),
      );
    },
  );
}
