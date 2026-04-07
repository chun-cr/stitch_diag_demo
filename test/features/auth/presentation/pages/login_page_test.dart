import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/main.dart';

void main() {
  testWidgets('login button enters subdued submitting state without playful phases', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const ValueKey('login_idle')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('login_idle')));
    await tester.pump();

    expect(find.byKey(const ValueKey('login_submitting')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_idle')), findsNothing);
    expect(find.byKey(const ValueKey('login_loading')), findsNothing);
    expect(find.byKey(const ValueKey('login_confirming')), findsNothing);

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('login_submitting')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_loading')), findsNothing);
    expect(find.byKey(const ValueKey('login_confirming')), findsNothing);

    await tester.pump(const Duration(milliseconds: 2500));

    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(null);
  });
}
