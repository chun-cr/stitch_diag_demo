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
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_target.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

class _SuccessfulSendCodeRepository extends AuthRepositoryAdapter {
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
    required VerificationCodeTarget target,
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
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return VerificationCodeSendEntity(
      channel: 'PHONE',
      maskedReceiver: '+861****8000',
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
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

class _FailingSendCodeRepository extends AuthRepositoryAdapter {
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
    required VerificationCodeTarget target,
  }) async => VerificationCodeChallengeEntity(
    challengeId: 'challenge-1',
    captchaRequired: false,
    captchaProvider: null,
    captchaPayload: null,
    expireAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  Future<VerificationCodeSendEntity> sendCode({required String challengeId}) {
    throw DioException(
      requestOptions: RequestOptions(path: '/send-code'),
      response: Response(
        requestOptions: RequestOptions(path: '/send-code'),
        statusCode: 400,
        data: {'message': 'too-many-requests'},
      ),
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
    required VerificationCodeScene scene,
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
  required AuthRepository repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
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
}

void main() {
  testWidgets('send code success enters countdown and shows success toast', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    await _pumpLoginPage(tester, repository: _SuccessfulSendCodeRepository());

    await tester.enterText(find.byType(TextFormField).first, '13800138000');
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('send_code_loading')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(l10n.authCodeSent), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_countdown')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('email send code success shows spam-folder toast copy', (
    tester,
  ) async {
    await _pumpLoginPage(tester, repository: _SuccessfulSendCodeRepository());

    await tester.tap(find.byKey(const ValueKey('login_email_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(
      find.byType(TextFormField).first,
      'doctor@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('验证码已发送，如未收到请检查垃圾邮件箱。'), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_countdown')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('send code failure shows backend message', (tester) async {
    await _pumpLoginPage(tester, repository: _FailingSendCodeRepository());

    await tester.enterText(find.byType(TextFormField).first, '13800138000');
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('too-many-requests'), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_button')), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('switching login mode clears field state and resets countdown', (
    tester,
  ) async {
    await _pumpLoginPage(tester, repository: _SuccessfulSendCodeRepository());

    await tester.enterText(find.byType(TextFormField).first, '13800138000');
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextFormField).at(1), '1234');

    final switchToPassword = tester.widget<TextButton>(
      find.byKey(const ValueKey('switch_to_password_login')),
    );
    switchToPassword.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('password_field')), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'abcdef');
    final switchToCode = tester.widget<TextButton>(
      find.byKey(const ValueKey('switch_to_code_login')),
    );
    switchToCode.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final phoneField = find.byType(TextFormField).first;
    expect(
      tester.widget<TextFormField>(phoneField).controller?.text,
      '13800138000',
    );
    expect(find.byKey(const ValueKey('code_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_button')), findsWidgets);
    expect(find.text('1234'), findsNothing);

    final switchBackToPassword = tester.widget<TextButton>(
      find.byKey(const ValueKey('switch_to_password_login')),
    );
    switchBackToPassword.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('abcdef'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('changing phone or country code resets code countdown state', (
    tester,
  ) async {
    await _pumpLoginPage(tester, repository: _SuccessfulSendCodeRepository());

    await tester.enterText(find.byType(TextFormField).first, '13800138000');
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('send_code_countdown')), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '13800138001');
    await tester.pump();

    expect(find.byKey(const ValueKey('send_code_button')), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('country_code_menu_trigger')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(
      find.byKey(const ValueKey('country_code_picker_item_+44')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const ValueKey('send_code_button')), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('forgot password shows guidance dialog', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    await _pumpLoginPage(tester, repository: _SuccessfulSendCodeRepository());

    final switchToPassword = tester.widget<TextButton>(
      find.byKey(const ValueKey('switch_to_password_login')),
    );
    switchToPassword.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(l10n.authForgotPassword));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l10n.authForgotPasswordTip), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextButton), findsWidgets);

    await tester.tap(find.byType(TextButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l10n.authForgotPasswordTip), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
