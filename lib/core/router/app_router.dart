import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:stitch_diag_demo/features/home/presentation/pages/home_page.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/register_page.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/scan_guide_page.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/face_scan_page.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/tongue_scan_page.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/palm_scan_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/profile_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/settings_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/account_security_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/points_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/set_login_password_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/shipping_address_page.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report_page.dart';
import 'package:stitch_diag_demo/features/report/presentation/models/report_product_data.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report_checkout_page.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report_product_detail_page.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history_page.dart';

// ─── 路由路径常量 ─────────────────────────────────────────────────
class AppRoutes {
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const completeProfile = '/complete-profile';
  static const scan = '/scan';
  static const scanFace = '/scan/face';
  static const scanTongue = '/scan/tongue';
  static const scanPalm = '/scan/palm';
  static const report = '/report';
  static const reportAnalysis = '/report/analysis';
  static const reportProductDetail = '/report/product';
  static const reportCheckout = '/report/checkout';
  static const history = '/history';
  static const profile = '/profile';
  static const profileAddresses = '/profile/addresses';
  static const profilePoints = '/profile/points';
  static const settings = '/profile/settings';
  static const accountSecurity = '/profile/settings/account-security';
  static const setLoginPassword =
      '/profile/settings/account-security/set-login-password';
}

final ValueNotifier<bool> _previewAuthState = ValueNotifier<bool>(false);

bool get isPreviewAuthenticated => _previewAuthState.value;

void setPreviewAuthenticated(bool value) {
  if (_previewAuthState.value == value) {
    return;
  }
  _previewAuthState.value = value;
}

// ─── 路由配置 ─────────────────────────────────────────────────────
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  debugLogDiagnostics: true,
  refreshListenable: _previewAuthState,
  redirect: (context, state) {
    final isEntryAuthRoute =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register;
    final isProfileCompletionRoute =
        state.matchedLocation == AppRoutes.completeProfile;

    if (!isPreviewAuthenticated &&
        !isEntryAuthRoute &&
        !isProfileCompletionRoute) {
      return AppRoutes.login;
    }

    if (isPreviewAuthenticated && isEntryAuthRoute) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const MainShell(),
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 首页从底层轻微放大、淡入显现（拨云见日）
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final scaleAnim = Tween<double>(
            begin: 0.96,
            end: 1.0,
          ).animate(curved);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: scaleAnim, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginPage(
        inviteTicket: state.uri.queryParameters['inviteTicket'],
        initialMode: state.uri.queryParameters['mode'],
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegisterPage(
        inviteTicket: state.uri.queryParameters['inviteTicket'],
        initialMode: state.uri.queryParameters['mode'],
      ),
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      builder: (context, state) => const CompleteProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.scan,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        child: const ScanGuidePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.scanFace,
      builder: (context, state) => const FaceScanPage(),
    ),
    GoRoute(
      path: AppRoutes.scanTongue,
      builder: (context, state) => const TongueScanPage(),
    ),
    GoRoute(
      path: AppRoutes.scanPalm,
      builder: (context, state) => const PalmScanPage(),
    ),
    GoRoute(
      path: AppRoutes.reportAnalysis,
      builder: (context, state) => const ReportPage(),
    ),
    GoRoute(
      path: AppRoutes.report,
      builder: (context, state) => const ReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportProductDetail,
      builder: (context, state) {
        final product = state.extra;
        if (product is! ReportProductData) {
          return const ReportPage();
        }
        return ReportProductDetailPage(product: product);
      },
    ),
    GoRoute(
      path: AppRoutes.reportCheckout,
      builder: (context, state) {
        final args = state.extra;
        if (args is! ReportCheckoutArgs) {
          return const ReportPage();
        }
        return ReportCheckoutPage(args: args);
      },
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryReportPage(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.profileAddresses,
      builder: (context, state) => const ShippingAddressPage(),
    ),
    GoRoute(
      path: AppRoutes.profilePoints,
      builder: (context, state) => const PointsPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.accountSecurity,
      builder: (context, state) => const AccountSecurityPage(),
    ),
    GoRoute(
      path: AppRoutes.setLoginPassword,
      builder: (context, state) => const SetLoginPasswordPage(),
    ),
  ],
);
