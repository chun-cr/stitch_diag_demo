import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/l10n/seasonal_context.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';
import 'package:stitch_diag_demo/main.dart';

void main() {
  testWidgets('login page shows the current seasonal tag from shared context', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(milliseconds: 900));

    final context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context);
    final expectedTag = l10n.seasonalTagLabel(SeasonalContext.now());

    expect(find.text(expectedTag), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
