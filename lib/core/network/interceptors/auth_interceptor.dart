import 'package:dio/dio.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!getIt.isRegistered<AuthSessionStore>()) {
      handler.next(options);
      return;
    }

    if (!options.path.contains('/api/v1/saas/mobile/auth/')) {
      final authorization =
          await getIt<AuthSessionStore>().authorizationHeader();
      if (authorization != null) {
        options.headers['Authorization'] = authorization;
      }
    }

    handler.next(options);
  }
}
