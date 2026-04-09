import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/register_page.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

class _FailingRegisterAuthRepository implements AuthRepository {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/v1/saas/mobile/auth/register/password'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/saas/mobile/auth/register/password'),
        data: {'message': '该手机号已注册'},
        statusCode: 409,
      ),
    );
  }
}

Future<void> _pumpRegisterPage(
  WidgetTester tester, {
  AuthRepository? repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null) authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RegisterPage(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('register page focuses on account creation only', (tester) async {
    await _pumpRegisterPage(tester);

    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('密码'), findsOneWidget);
    expect(find.text('确认密码'), findsOneWidget);
    expect(find.text('微信'), findsNothing);
    expect(find.text('Apple 登录'), findsNothing);
    expect(find.text('昵称'), findsNothing);
    expect(find.text('性别'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('register page blocks submit on invalid phone format', (
    tester,
  ) async {
    await _pumpRegisterPage(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '12ab');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1');
    await tester.enterText(find.byType(TextFormField).at(2), 'Password1');
    await tester.tap(find.text('创建账号'));
    await tester.pump();

    expect(find.text('请输入正确的手机号'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('register page keeps password validation on account creation page', (
    tester,
  ) async {
    await _pumpRegisterPage(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), '1234567');
    await tester.enterText(find.byType(TextFormField).at(2), '7654321');
    await tester.tap(find.text('创建账号'));
    await tester.pump();

    expect(find.text('密码不少于8位'), findsOneWidget);
    expect(find.text('两次密码不一致'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('register page shows server message on failure', (tester) async {
    await _pumpRegisterPage(
      tester,
      repository: _FailingRegisterAuthRepository(),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1');
    await tester.enterText(find.byType(TextFormField).at(2), 'Password1');
    await tester.tap(find.byKey(const ValueKey('register_terms_row')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('register_create_account_button')));
    await tester.pump();

    expect(find.text('该手机号已注册'), findsOneWidget);
    expect(find.byType(RegisterPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
