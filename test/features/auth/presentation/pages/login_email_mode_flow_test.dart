import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

class _EmailLoginCaptureRepository implements AuthRepository {
  AuthRequest? lastLoginRequest;

  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    lastLoginRequest = request;
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/login/password',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/login/password',
        ),
        statusCode: 400,
        data: {'message': 'capture'},
      ),
    );
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<PasswordRegisterResultEntity> registerPassword(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required String countryCode,
    required String phoneNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({required String challengeId}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) async => true;

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

Future<void> _pumpLoginPage(
  WidgetTester tester, {
  required Widget child,
  required AuthRepository repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

Future<void> _pumpLoginRouter(
  WidgetTester tester, {
  required AuthRepository repository,
  required GoRouter router,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('email mode submits email and password through password login', (
    tester,
  ) async {
    final repository = _EmailLoginCaptureRepository();
    await _pumpLoginPage(
      tester,
      repository: repository,
      child: const LoginPage(inviteTicket: 'invite-email-1'),
    );

    await tester.tap(find.byKey(const ValueKey('login_email_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.enterText(find.byType(TextFormField).at(0), 'doctor@mai.ai');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.pump();

    final button = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('login_primary_button')),
    );
    button.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(repository.lastLoginRequest, isNotNull);
    expect(repository.lastLoginRequest!.phoneNumber, 'doctor@mai.ai');
    expect(repository.lastLoginRequest!.countryCode, '');
    expect(repository.lastLoginRequest!.password, 'secret123');
    expect(repository.lastLoginRequest!.inviteTicket, 'invite-email-1');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('register action carries email mode in router query', (
    tester,
  ) async {
    final repository = _EmailLoginCaptureRepository();
    final router = GoRouter(
      initialLocation: '/login?inviteTicket=invite-email-2',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(
            inviteTicket: state.uri.queryParameters['inviteTicket'],
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => Scaffold(
            body: Text(
              'register:${state.uri.queryParameters['mode']}:${state.uri.queryParameters['inviteTicket']}',
            ),
          ),
        ),
      ],
    );

    await _pumpLoginRouter(tester, repository: repository, router: router);

    await tester.tap(find.byKey(const ValueKey('login_email_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('立即注册'));
    await tester.pumpAndSettle();

    expect(find.text('register:email:invite-email-2'), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
