import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/core/network/interceptors/auth_interceptor.dart';

class _AuthRefreshTestAdapter implements HttpClientAdapter {
  int protectedRequestCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/v1/saas/mobile/auth/tokens/refresh') {
      expect(options.data, {'refreshToken': 'stale-refresh'});
      return ResponseBody.fromString(
        jsonEncode({
          'code': 0,
          'message': 'ok',
          'data': {
            'accessToken': 'fresh-access',
            'refreshToken': 'fresh-refresh',
            'tokenType': 'Bearer',
            'expiresIn': 7200,
            'scope': 'profile',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/protected/resource') {
      protectedRequestCount++;
      final authorization = options.headers['Authorization'];
      if (authorization == 'Bearer fresh-access') {
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'message': 'expired'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  test('refreshes token and retries protected request after 401', () async {
    SharedPreferences.setMockInitialValues({
      'auth_access_token': 'stale-access',
      'auth_refresh_token': 'stale-refresh',
      'auth_token_type': 'Bearer',
      'auth_expires_in': 3600,
      'auth_scope': 'mobile',
    });
    initInjector();
    final dioClient = getIt<DioClient>();
    dioClient.dio.interceptors.clear();
    dioClient.dio.interceptors.add(AuthInterceptor());
    final adapter = _AuthRefreshTestAdapter();
    dioClient.dio.httpClientAdapter = adapter;

    final response = await dioClient.dio.get<Map<String, dynamic>>(
      '/protected/resource',
    );

    expect(response.data, {'ok': true});
    expect(adapter.protectedRequestCount, 2);
    expect(
      await getIt<AuthSessionStore>().authorizationHeader(),
      'Bearer fresh-access',
    );
    expect(await getIt<AuthSessionStore>().refreshToken(), 'fresh-refresh');
  });
}
