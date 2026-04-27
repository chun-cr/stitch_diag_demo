import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_target.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/features/profile/domain/entities/profile_me_entity.dart';
import 'package:stitch_diag_demo/features/profile/domain/entities/profile_points_account_simple_entity.dart';
import 'package:stitch_diag_demo/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:stitch_diag_demo/features/profile/data/stores/profile_address_store.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/profile_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/providers/profile_address_provider.dart';
import 'package:stitch_diag_demo/features/profile/presentation/providers/profile_points_provider.dart';
import 'package:stitch_diag_demo/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:stitch_diag_demo/main.dart';

class _LogoutCapturingRepository extends AuthRepositoryAdapter {
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
    required VerificationCodeTarget target,
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
    required VerificationCodeScene scene,
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
    AuthSessionStore.debugUseMemoryBackend = true;
    addTearDown(() {
      AuthSessionStore.debugUseMemoryBackend = false;
    });
    final repository = _LogoutCapturingRepository();
    SharedPreferences.setMockInitialValues({});
    initInjector();
    await getIt<AuthSessionStore>().saveSession(
      const AuthSessionEntity(
        accessToken: 'token',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
        scope: 'mobile',
      ),
    );
    await ProfileAddressStore().replaceAll(const [
      ProfileShippingAddressEntity(
        id: 'addr-1',
        receiverName: 'Amin',
        receiverMobile: '13812345678',
        provinceCode: '110000',
        provinceName: 'Beijing',
        cityCode: '110100',
        cityName: 'Beijing',
        districtCode: '110101',
        districtName: 'Dongcheng',
        detailAddress: 'No.1',
        isDefault: true,
      ),
    ]);
    setPreviewAuthenticated(true);
    appRouter.go(AppRoutes.home);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          profileMeProvider.overrideWith(
            (ref) async => const ProfileMeEntity(
              nickname: 'Amin',
              realName: 'Zhang San',
              countryCode: '+86',
              phone: '13812345678',
            ),
          ),
          profileAddressesProvider.overrideWith(
            () => _StaticAddressesController(),
          ),
          profileDefaultShippingAddressProvider.overrideWith(
            (ref) async => const ProfileShippingAddressEntity(
              id: 'addr-1',
              receiverName: 'Amin',
              receiverMobile: '13812345678',
              provinceCode: '110000',
              provinceName: 'Beijing',
              cityCode: '110100',
              cityName: 'Beijing',
              districtCode: '110101',
              districtName: 'Dongcheng',
              detailAddress: 'No.1',
              isDefault: true,
            ),
          ),
          profilePointsBalanceProvider.overrideWith(
            (ref) async => const ProfilePointsAccountSimpleEntity(
              id: 'points-1',
              userId: 'user-1',
              availableAmount: 88,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ProfilePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump(const Duration(milliseconds: 1500));

    final preferences = await SharedPreferences.getInstance();

    expect(repository.lastRefreshToken, 'refresh');
    expect(isPreviewAuthenticated, isFalse);
    expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.login);
    expect(await getIt<AuthSessionStore>().authorizationHeader(), isNull);
    expect(await getIt<AuthSessionStore>().refreshToken(), isNull);
    expect(preferences.getString('auth_access_token'), isNull);
    expect(preferences.getString('auth_refresh_token'), isNull);
    expect(preferences.getString('auth_token_type'), isNull);
    expect(preferences.getInt('auth_expires_in'), isNull);
    expect(preferences.getString('auth_scope'), isNull);
    expect(preferences.getString('profile_shipping_addresses'), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('profile page refreshes after switching to a different account', (
    tester,
  ) async {
    AuthSessionStore.debugUseMemoryBackend = true;
    addTearDown(() {
      AuthSessionStore.debugUseMemoryBackend = false;
    });
    SharedPreferences.setMockInitialValues({});
    initInjector();

    ProfileMeEntity currentProfile = const ProfileMeEntity(
      nickname: 'Amin',
      realName: 'Zhang San',
      countryCode: '+86',
      phone: '13812345678',
    );

    await getIt<AuthSessionStore>().saveSession(
      const AuthSessionEntity(
        accessToken: 'token-a',
        refreshToken: 'refresh-a',
        tokenType: 'Bearer',
        expiresIn: 3600,
        scope: 'mobile',
      ),
    );
    setPreviewAuthenticated(true);
    appRouter.go(AppRoutes.home);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _LogoutCapturingRepository(),
          ),
          profileMeProvider.overrideWith((ref) async => currentProfile),
          profileAddressesProvider.overrideWith(
            () => _StaticAddressesController(),
          ),
          profileDefaultShippingAddressProvider.overrideWith(
            (ref) async => const ProfileShippingAddressEntity(
              id: 'addr-1',
              receiverName: 'Amin',
              receiverMobile: '13812345678',
              provinceCode: '110000',
              provinceName: 'Beijing',
              cityCode: '110100',
              cityName: 'Beijing',
              districtCode: '110101',
              districtName: 'Dongcheng',
              detailAddress: 'No.1',
              isDefault: true,
            ),
          ),
          profilePointsBalanceProvider.overrideWith(
            (ref) async => const ProfilePointsAccountSimpleEntity(
              id: 'points-1',
              userId: 'user-1',
              availableAmount: 88,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Amin'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.login);

    currentProfile = const ProfileMeEntity(
      nickname: 'Bora',
      realName: 'Li Si',
      countryCode: '+86',
      phone: '13987654321',
    );
    await getIt<AuthSessionStore>().saveSession(
      const AuthSessionEntity(
        accessToken: 'token-b',
        refreshToken: 'refresh-b',
        tokenType: 'Bearer',
        expiresIn: 3600,
        scope: 'mobile',
      ),
    );
    setPreviewAuthenticated(true);
    appRouter.go(AppRoutes.home);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Bora'), findsOneWidget);
    expect(find.text('Amin'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });
}

class _StaticAddressesController extends ProfileAddressesController {
  @override
  Future<List<ProfileShippingAddressEntity>> build() async {
    return const [
      ProfileShippingAddressEntity(
        id: 'addr-1',
        receiverName: 'Amin',
        receiverMobile: '13812345678',
        provinceCode: '110000',
        provinceName: 'Beijing',
        cityCode: '110100',
        cityName: 'Beijing',
        districtCode: '110101',
        districtName: 'Dongcheng',
        detailAddress: 'No.1',
        isDefault: true,
      ),
    ];
  }
}
