import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

void main() {
  testWidgets('login page requires phone and verification code before submit', (
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

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('login_primary_button'))),
    );
    await tester.pump();

    expect(find.text('请输入手机号'), findsWidgets);
    expect(find.text('请输入验证码'), findsWidgets);

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
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('login_primary_button'))),
    );
    await tester.pump();

    expect(find.text('请输入正确的手机号'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('password login requires password and validates min length', (
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

    await tester.tap(find.text('密码登录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');

    final button = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('login_primary_button')),
    );
    button.onTap!();
    await tester.pump();
    expect(find.text('请输入密码'), findsWidgets);

    final passwordField = find.descendant(
      of: find.byKey(const ValueKey('password_field')),
      matching: find.byType(TextFormField),
    );

    await tester.enterText(passwordField, '123');
    await tester.pump();
    button.onTap!();
    await tester.pump();
    expect(find.text('密码不能少于6位'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
