import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/core/platform/app_identity.dart';

class _CaptureAdapter implements HttpClientAdapter {
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
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app/info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    AppIdentity.resetForTest();
  });

  test('injects native app id into request headers', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAppId');
      return 'com.huaji.myapp.dev';
    });

    final dioClient = DioClient();
    final adapter = _CaptureAdapter();
    dioClient.dio.httpClientAdapter = adapter;

    await dioClient.dio.get<Map<String, dynamic>>('/health');

    expect(
      adapter.lastRequestOptions.headers['X-App-Id'],
      'com.huaji.myapp.dev',
    );
    expect(
      adapter.lastRequestOptions.headers['X-Platform'],
      DioClient.platform,
    );
  });
}
