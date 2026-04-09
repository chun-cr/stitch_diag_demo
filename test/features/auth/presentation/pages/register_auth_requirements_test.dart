import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_send_entity.dart';
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
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/register/password',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/register/password',
        ),
        data: {'message': '该手机号已注册'},
        statusCode: 409,
      ),
    );
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
  }) async => VerificationCodeChallengeEntity(
    challengeId: 'challenge-1',
    captchaRequired: false,
    captchaProvider: null,
    captchaPayload: null,
    expireAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async => VerificationCodeSendEntity(
    channel: 'PHONE',
    maskedReceiver: '+861****8000',
    expireAt: DateTime.now().add(const Duration(minutes: 5)),
    resendAt: DateTime.now().add(const Duration(seconds: 60)),
  );

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
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/verification-code/authenticate',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/verification-code/authenticate',
        ),
        data: {'message': '验证码错误'},
        statusCode: 400,
      ),
    );
  }
}

class _CapturingRegisterAuthRepository implements AuthRepository {
  VerificationCodeScene? lastScene;
  String? lastCountryCode;
  String? lastPhoneNumber;
  String? lastChallengeId;
  String? lastVerificationCode;
  int createChallengeCallCount = 0;
  int sendCodeCallCount = 0;

  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
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
  }) async {
    createChallengeCallCount++;
    lastScene = scene;
    lastCountryCode = countryCode;
    lastPhoneNumber = phoneNumber;
    return VerificationCodeChallengeEntity(
      challengeId: 'challenge-1',
      captchaRequired: false,
      captchaProvider: null,
      captchaPayload: null,
      channel: 'PHONE',
      maskedReceiver: '+441****8000',
      expireAt: DateTime.now().add(const Duration(minutes: 10)),
      resendAt: DateTime.now().add(const Duration(seconds: 60)),
    );
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async {
    sendCodeCallCount++;
    lastChallengeId = challengeId;
    return VerificationCodeSendEntity(
      channel: 'PHONE',
      maskedReceiver: '+441****8000',
      expireAt: DateTime.now().add(const Duration(minutes: 5)),
      resendAt: DateTime.now().add(const Duration(seconds: 60)),
    );
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
    lastChallengeId = challengeId;
    lastVerificationCode = verificationCode;
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/verification-code/authenticate',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/verification-code/authenticate',
        ),
        data: {'message': 'capture'},
        statusCode: 400,
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
        if (repository != null)
          authRepositoryProvider.overrideWithValue(repository),
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
    expect(find.text('验证码'), findsOneWidget);
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
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('创建账号'));
    await tester.pump();

    expect(find.text('请输入正确的手机号'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'register page requires verification code on account creation page',
    (tester) async {
      await _pumpRegisterPage(tester);

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.enterText(find.byType(TextFormField).at(1), '12');
      await tester.tap(find.text('创建账号'));
      await tester.pump();

      expect(find.text('请输入验证码'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'register page uses register challenge response for initial send',
    (tester) async {
      final repository = _CapturingRegisterAuthRepository();
      await _pumpRegisterPage(tester, repository: repository);

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.createChallengeCallCount, 1);
      expect(repository.sendCodeCallCount, 0);
      expect(repository.lastScene, VerificationCodeScene.register);
      expect(repository.lastCountryCode, '+86');
      expect(repository.lastPhoneNumber, '13800138000');
      expect(find.text('验证码已发送，请注意查收'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('register_send_code_countdown')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('register page submits the selected country code', (
    tester,
  ) async {
    final repository = _CapturingRegisterAuthRepository();
    await _pumpRegisterPage(tester, repository: repository);

    await tester.tap(
      find.byKey(const ValueKey('register_country_code_menu_trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('+44').last);
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('register_terms_row')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('register_create_account_button')),
    );
    await tester.pump();

    expect(repository.lastScene, VerificationCodeScene.register);
    expect(repository.lastCountryCode, '+44');
    expect(repository.lastPhoneNumber, '13800138000');
    expect(repository.lastChallengeId, 'challenge-1');
    expect(repository.lastVerificationCode, '123456');

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
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('register_terms_row')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('register_create_account_button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('验证码错误'), findsOneWidget);
    expect(find.byType(RegisterPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
