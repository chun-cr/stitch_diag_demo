import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/main.dart';

class _SuccessfulAuthRepository implements AuthRepository {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const AuthSessionEntity(
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresIn: 3600,
      scope: 'mobile',
    );
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw UnimplementedError();
  }
}

class _FailingAuthRepository implements AuthRepository {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/v1/saas/mobile/auth/login/password'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/saas/mobile/auth/login/password'),
        data: {'message': '账号或密码错误'},
        statusCode: 401,
      ),
    );
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('login button enters subdued submitting state without playful phases', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SuccessfulAuthRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const ValueKey('login_idle')), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), 'preview123');
    await tester.pump();

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

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 700));

    final preferences = await SharedPreferences.getInstance();

    expect(isPreviewAuthenticated, isTrue);
    expect(appRouter.state.matchedLocation, AppRoutes.home);
    expect(preferences.getString('auth_access_token'), 'token');
    expect(preferences.getString('auth_refresh_token'), 'refresh');
    expect(preferences.getString('auth_token_type'), 'Bearer');
    expect(preferences.getInt('auth_expires_in'), 3600);
    expect(preferences.getString('auth_scope'), 'mobile');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tapping outside input fields dismisses the keyboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('login shows server message and resets button on failure', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FailingAuthRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), 'preview123');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('login_idle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('账号或密码错误'), findsOneWidget);
    expect(find.byKey(const ValueKey('login_idle')), findsOneWidget);
    expect(isPreviewAuthenticated, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

}
