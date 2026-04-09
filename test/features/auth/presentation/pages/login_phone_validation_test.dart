import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

void main() {
  testWidgets('login page requires phone and password before submit', (
    tester,
  ) async {
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

    await tester.tap(find.byKey(const ValueKey('login_idle')));
    await tester.pump();

    expect(find.text('请输入手机号'), findsWidgets);
    expect(find.text('密码不能少于6位'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('login page rejects invalid phone format', (tester) async {
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

    await tester.enterText(find.byType(TextFormField).first, '12ab');
    await tester.tap(find.byKey(const ValueKey('login_idle')));
    await tester.pump();

    expect(find.text('请输入正确的手机号'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
