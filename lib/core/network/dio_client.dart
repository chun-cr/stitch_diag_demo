import 'package:dio/dio.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  static const String baseUrl = 'http://localhost:8080';
  static const String appId = String.fromEnvironment(
    'X_APP_ID',
    defaultValue: 'stitch_diag_demo',
  );
  static const String platform = String.fromEnvironment(
    'X_PLATFORM',
    defaultValue: 'ANDROID',
  );
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        headers: {'X-App-Id': appId, 'X-Platform': platform},
      ),
    );
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(AppLogInterceptor());
  }
}
