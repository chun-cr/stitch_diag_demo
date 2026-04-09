import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/register_page.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/main.dart';

class _SuccessfulRegisterAuthRepository implements AuthRepository {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) async {
    return const AuthSessionEntity(
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresIn: 3600,
      scope: 'profile',
    );
  }
}

void main() {
  testWidgets('router exposes complete profile page route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoutes.completeProfile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(CompleteProfilePage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('complete profile skip without session routes back to login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoutes.completeProfile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final zhFinder = find.text('跳过');
    final enFinder = find.text('Skip');
    await tester.tap(zhFinder.evaluate().isNotEmpty ? zhFinder : enFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(CompleteProfilePage), findsNothing);
    expect(appRouter.state.matchedLocation, AppRoutes.login);
    expect(isPreviewAuthenticated, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('register page go-login action always routes back to login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoutes.register);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final zhFinder = find.text('去登录');
    final enFinder = find.text('Go to login');
    await tester.tap(zhFinder.evaluate().isNotEmpty ? zhFinder : enFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(RegisterPage), findsNothing);
    expect(appRouter.state.matchedLocation, AppRoutes.login);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('successful register routes to complete profile page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _SuccessfulRegisterAuthRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    appRouter.go(AppRoutes.register);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1');
    await tester.enterText(find.byType(TextFormField).at(2), 'Password1');
    await tester.tap(find.byKey(const ValueKey('register_terms_row')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('register_create_account_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CompleteProfilePage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
