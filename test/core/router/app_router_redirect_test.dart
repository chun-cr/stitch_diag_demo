import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';

void main() {
  group('resolvePreviewAuthRedirect', () {
    test('redirects unauthenticated protected routes to login', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.home,
          isAuthenticated: false,
          bypassAuthGuard: false,
        ),
        AppRoutes.login,
      );
    });

    test('keeps home accessible when web debug bypass is enabled', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.home,
          isAuthenticated: false,
          bypassAuthGuard: true,
        ),
        isNull,
      );
    });

    test('keeps complete profile route accessible without session', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.completeProfile,
          isAuthenticated: false,
          bypassAuthGuard: false,
        ),
        isNull,
      );
    });

    test('redirects authenticated users away from login', () {
      expect(
        resolvePreviewAuthRedirect(
          matchedLocation: AppRoutes.login,
          isAuthenticated: true,
          bypassAuthGuard: false,
        ),
        AppRoutes.home,
      );
    });
  });
}
