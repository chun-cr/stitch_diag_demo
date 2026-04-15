import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../platform/app_identity.dart';
import 'interceptors/app_identity_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  static const String _defaultNativeBaseUrl =
      'https://saas-api.dev51.permillet.com';
  static const String _defaultLocalProxyBaseUrl = 'http://localhost:8080';
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String appId = AppIdentity.fallbackAppId;
  static const String wechatMiniProgramAppId = String.fromEnvironment(
    'WECHAT_MINI_PROGRAM_APP_ID',
    defaultValue: appId,
  );
  static const String _platformOverride = String.fromEnvironment('X_PLATFORM');

  static String get platform {
    if (_platformOverride.isNotEmpty) {
      return _platformOverride;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'IOS',
      TargetPlatform.android => 'ANDROID',
      _ => 'ANDROID',
    };
  }

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }
    if (kIsWeb) {
      return _webBaseUrl(Uri.base);
    }
    return _defaultNativeBaseUrl;
  }

  static String _webBaseUrl(Uri currentUri) {
    final host = currentUri.host.toLowerCase();
    final isLoopbackHost =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';

    // Flutter web debug server usually runs on a random localhost port and
    // does not proxy `/api`, so use the local nginx proxy for API requests.
    if (isLoopbackHost && currentUri.hasPort && currentUri.port != 8080) {
      return _defaultLocalProxyBaseUrl;
    }

    return currentUri.origin;
  }

  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        headers: {'X-App-Id': AppIdentity.currentAppId, 'X-Platform': platform},
      ),
    );
    dio.interceptors.add(AppIdentityInterceptor());
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(AppLogInterceptor());
  }
}
