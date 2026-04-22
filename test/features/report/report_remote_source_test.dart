import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/core/platform/app_identity.dart';
import 'package:stitch_diag_demo/features/report/data/sources/report_remote_source.dart';

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
}
