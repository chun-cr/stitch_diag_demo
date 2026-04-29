import 'package:dio/dio.dart';

import '../dio_client.dart';
import '../../platform/app_identity.dart';

class AppIdentityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[DioClient.skipPlatformHeadersExtraKey] == true) {
      options.headers.remove('X-App-Id');
      options.headers.remove('X-Platform');
      handler.next(options);
      return;
    }

    options.headers['X-App-Id'] = await AppIdentity.initialize();
    handler.next(options);
  }
}
