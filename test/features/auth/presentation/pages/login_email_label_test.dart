import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

void main() {
  testWidgets('login page shows 手机号 label in zh after email removal', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: LoginPage()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('邮箱'), findsNothing);
    expect(find.text('手机号/邮箱'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
