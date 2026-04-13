import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/profile_page.dart';
import 'package:stitch_diag_demo/main.dart';

class _LogoutCapturingRepository implements AuthRepository {
  String? lastRefreshToken;

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    lastRefreshToken = refreshToken;
  }
}

void main() {
  testWidgets('logout from profile returns to login page', (tester) async {
    final repository = _LogoutCapturingRepository();
    SharedPreferences.setMockInitialValues({
      'auth_access_token': 'token',
      'auth_refresh_token': 'refresh',
      'auth_token_type': 'Bearer',
      'auth_expires_in': 3600,
      'auth_scope': 'mobile',
    });
    setPreviewAuthenticated(true);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump(const Duration(milliseconds: 1500));

    final preferences = await SharedPreferences.getInstance();

    expect(repository.lastRefreshToken, 'refresh');
    expect(isPreviewAuthenticated, isFalse);
    expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.login);
    expect(preferences.getString('auth_access_token'), isNull);
    expect(preferences.getString('auth_refresh_token'), isNull);
    expect(preferences.getString('auth_token_type'), isNull);
    expect(preferences.getInt('auth_expires_in'), isNull);
    expect(preferences.getString('auth_scope'), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
