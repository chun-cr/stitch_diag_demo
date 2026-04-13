import 'package:dio/dio.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/core/utils/logger.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_session_model.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';

class AuthInterceptor extends Interceptor {
  static const _retryAfterRefreshKey = 'retry_after_token_refresh';
  static const _skipTokenRefreshKey = 'skip_token_refresh';

  bool _isAuthPath(RequestOptions options) {
    return options.path.contains('/api/v1/saas/mobile/auth/');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!getIt.isRegistered<AuthSessionStore>()) {
      handler.next(options);
      return;
    }

    if (!_isAuthPath(options)) {
      final authorization =
          await getIt<AuthSessionStore>().authorizationHeader();
      if (authorization != null) {
        options.headers['Authorization'] = authorization;
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final statusCode = err.response?.statusCode;
    final skipRefresh = requestOptions.extra[_skipTokenRefreshKey] == true;
    final alreadyRetried = requestOptions.extra[_retryAfterRefreshKey] == true;

    if (statusCode != 401 ||
        skipRefresh ||
        alreadyRetried ||
        _isAuthPath(requestOptions) ||
        !getIt.isRegistered<AuthSessionStore>() ||
        !getIt.isRegistered<DioClient>()) {
      handler.next(err);
      return;
    }

    final sessionStore = getIt<AuthSessionStore>();
    final refreshToken = await sessionStore.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final dio = getIt<DioClient>().dio;
      final refreshResponse = await dio.post(
        '/api/v1/saas/mobile/auth/tokens/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_skipTokenRefreshKey: true}),
      );

      final responseData = refreshResponse.data;
      if (responseData is! Map<String, dynamic>) {
        throw const FormatException('Invalid refresh response envelope');
      }
      final data = responseData['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Missing refresh response data');
      }

      final refreshedSession = AuthSessionModel.fromJson(data);
      await sessionStore.saveSession(
        AuthSessionEntity(
          accessToken: refreshedSession.accessToken,
          refreshToken: refreshedSession.refreshToken,
          tokenType: refreshedSession.tokenType,
          expiresIn: refreshedSession.expiresIn,
          scope: refreshedSession.scope,
        ),
      );

      final authorization = await sessionStore.authorizationHeader();
      if (authorization == null) {
        throw const FormatException('Missing refreshed authorization header');
      }

      final retryOptions = requestOptions.copyWith(
        headers: Map<String, dynamic>.from(requestOptions.headers)
          ..['Authorization'] = authorization,
      );
      retryOptions.extra[_retryAfterRefreshKey] = true;

      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } on Object catch (error) {
      AppLogger.log(
        'Token refresh failed for ${requestOptions.path}: $error',
      );
      await sessionStore.clear();
      handler.next(err);
    }
  }
}
