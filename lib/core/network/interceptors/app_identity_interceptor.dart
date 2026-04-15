import 'package:dio/dio.dart';

import '../../platform/app_identity.dart';

class AppIdentityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-App-Id'] = await AppIdentity.initialize();
    handler.next(options);
  }
}
