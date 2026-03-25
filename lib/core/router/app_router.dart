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
import 'package:stitch_diag_demo/features/report/presentation/pages/report_page.dart';

// ─── 路由路径常量 ─────────────────────────────────────────────────
class AppRoutes {
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const scan = '/scan';
  static const scanFace = '/scan/face';
  static const scanTongue = '/scan/tongue';
  static const scanPalm = '/scan/palm';
  static const report = '/report';
  static const reportAnalysis = '/report/analysis';
  static const history = '/history';
  static const profile = '/profile';
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
    final isAuthRoute = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register;

    if (!isPreviewAuthenticated && !isAuthRoute) {
      return AppRoutes.login;
    }

    if (isPreviewAuthenticated && isAuthRoute) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.scan,
      builder: (context, state) => const ScanGuidePage(),
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
      path: AppRoutes.history,
      builder: (context, state) => const _Placeholder(label: '历史记录'),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(label)),
        body: Center(child: Text('$label 页面开发中')),
      );
}
