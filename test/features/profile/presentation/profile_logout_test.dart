import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/profile_page.dart';
import 'package:stitch_diag_demo/main.dart';

void main() {
  testWidgets('logout from profile returns to login page', (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_access_token': 'token',
      'auth_refresh_token': 'refresh',
      'auth_token_type': 'Bearer',
      'auth_expires_in': 3600,
      'auth_scope': 'mobile',
    });
    setPreviewAuthenticated(true);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump(const Duration(milliseconds: 1500));

    final preferences = await SharedPreferences.getInstance();

    expect(isPreviewAuthenticated, isFalse);
    expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.login);
    expect(preferences.getString('auth_access_token'), isNull);
    expect(preferences.getString('auth_refresh_token'), isNull);
    expect(preferences.getString('auth_token_type'), isNull);
    expect(preferences.getInt('auth_expires_in'), isNull);
    expect(preferences.getString('auth_scope'), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
