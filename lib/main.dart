import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

// 替换成你的实际包名，例如：
// import 'package:your_app_name/core/router/app_router.dart';
// import 'package:your_app_name/core/theme/app_theme.dart';
//
// 临时直接引用（正式时删掉，改用上面的包名 import）
import 'core/l10n/l10n.dart';
import 'core/l10n/locale_controller.dart';
import 'core/di/injector.dart';
import 'core/network/auth_session_store.dart';
import 'core/platform/app_identity.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 锁定竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppIdentity.initialize();
  initInjector();
  setPreviewAuthenticated(await getIt<AuthSessionStore>().hasSession());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    initInjector();
    final locale = ref.watch(localeControllerProvider).asData?.value;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F6FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A8FE8),
          brightness: Brightness.light,
        ),
        // 全局去掉 AppBar 阴影
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F2540)),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2540),
          ),
        ),
        // 输入框全局样式
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F9FF),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x264A8FE8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x264A8FE8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A8FE8), width: 1.5),
          ),
        ),
        // 主按钮全局样式
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
