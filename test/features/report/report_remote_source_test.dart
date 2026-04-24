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

ResponseBody _encryptedJsonResponse(String data) {
  return ResponseBody.fromString(
    data,
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      'X-Security': ['1'],
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

  test(
    'getAllReports does not resolve face images from detail by default',
    () async {
      final requestPaths = <String>[];
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

        throw StateError('Unexpected path: ${options.path}');
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ReportRemoteSource(dioClient);

      final result = await remoteSource.getAllReports();

      expect(result, hasLength(1));
      expect(result.first.faceImageUrl, isEmpty);
      expect(requestPaths, equals(['/api/v1/saas/physiques/reports']));
    },
  );

  test('getAllReports decrypts X-Security protected payloads', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      if (options.path != '/api/v1/saas/physiques/reports') {
        throw StateError('Unexpected path: ${options.path}');
      }

      return _encryptedJsonResponse(
        'WFy8PpSj4QM4+LqSWcH4SHMM/iooHXtYxaSMfBDclAo3JUEYhWi16CkASSqqjYYdWzwdlk3+6fraFrWfOIRA4BsNrXfCpDm2QVvrO8bWc0bp7jKGP8Q+rjFD6TLjt5TR+pXCZnqde7MoQcgJkibnyppmHc2RYWYiu8ErZ5g6XXlSIpuHi0KQWgsD5REhsnfLWtCiGZcf9V9Hqt5Z2zKSraTWtkb5TGY/6EYznCx8Wcsy0fBuYwd7OILQ8IkLnVfxAPLeHexKU5t9rEu8C0X2BRhX/EsXb1MK0LaLaJOf0N4qg+zz8RUu46VIOMDc3KKdXl2vpYi3B2Tx2omlESSrhSjmJ6zD7mZfab5ejR+InPNEtxnzfGFbfJ6At539rcLR6rlGCU3vtPZ7rx6MWHZ7Uli1dvnS89vFFQcFzHGIDuBe/1mLiE7muu+UUdK4fRx7',
      );
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getAllReports();

    expect(result, hasLength(1));
    expect(result.first.id, 'report-secure-1');
    expect(result.first.physiqueName, 'Balanced');
    expect(result.first.deepPredicts.categoryProbabilities, hasLength(2));
    expect(
      result.first.deepPredicts.categoryProbabilities.first.name,
      'risk-a',
    );
    expect(
      result.first.deepPredicts.categoryProbabilities.first.rawProbability,
      closeTo(0.67, 0.0001),
    );
  });
}
