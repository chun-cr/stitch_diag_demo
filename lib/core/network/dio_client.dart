import 'package:dio/dio.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  static const String baseUrl = 'https://saas-api.dev51.permillet.com';
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
      ),
    );
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(AppLogInterceptor());
  }
}
