import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/profile_page.dart';
import 'package:stitch_diag_demo/main.dart';

void main() {
  testWidgets('logout from profile returns to login page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(true);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(isPreviewAuthenticated, isFalse);
    expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.login);

    await tester.binding.setSurfaceSize(null);
  });
}
