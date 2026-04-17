import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/report/presentation/models/report_product_data.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report_checkout_page.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_page.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report_product_detail_page.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

import 'report_test_data.dart';

Future<GoRouter> _pumpReportRouter(
  WidgetTester tester, {
  String initialLocation = AppRoutes.report,
  Widget Function(BuildContext context, GoRouterState state)? reportBuilder,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.report,
        builder: (context, state) =>
            reportBuilder?.call(context, state) ?? const ReportPage(),
      ),
      GoRoute(
        path: AppRoutes.reportAnalysis,
        builder: (context, state) =>
            reportBuilder?.call(context, state) ?? const ReportPage(),
      ),
      GoRoute(
        path: AppRoutes.reportProductDetail,
        builder: (context, state) {
          final product = state.extra;
          if (product is! ReportProductData) {
            return const SizedBox.shrink();
          }
          return ReportProductDetailPage(product: product);
        },
      ),
      GoRoute(
        path: AppRoutes.reportCheckout,
        builder: (context, state) {
          final args = state.extra;
          if (args is! ReportCheckoutArgs) {
            return const SizedBox.shrink();
          }
          return ReportCheckoutPage(args: args);
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
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
  );
  await tester.pump(const Duration(milliseconds: 900));
  return router;
}

void main() {
  testWidgets('report page boots safely without reportId', (tester) async {
    final router = await _pumpReportRouter(tester);

    expect(find.byType(ReportPage), findsOneWidget);
    expect(find.byKey(const ValueKey('report_mode_demo')), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report page resolves live data when reportId loader succeeds', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async =>
            buildReportViewData(summary: 'Recovered live summary'),
      ),
    );

    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);
    expect(find.text('Recovered live summary'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 250));

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report page shows retry state when live loader fails first', (
    tester,
  ) async {
    var attempts = 0;
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async {
          attempts++;
          if (attempts == 1) {
            throw Exception('temporary failure');
          }
          return buildReportViewData(summary: 'Retry success summary');
        },
      ),
    );

    expect(find.byKey(const ValueKey('report_error')), findsOneWidget);
    expect(find.byKey(const ValueKey('report_retry_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report_retry_button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('report_loading')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);
    expect(find.text('Retry success summary'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 250));

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('switching to advice tab reveals product actions', (
    tester,
  ) async {
    final router = await _pumpReportRouter(tester);
    final l10n = lookupAppLocalizations(const Locale('zh'));

    await tester.tap(find.text(l10n.reportTabAdvice));
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportAdviceProductDetailButton), findsWidgets);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'product detail and checkout routes still work from report page',
    (tester) async {
      final router = await _pumpReportRouter(tester);
      final l10n = lookupAppLocalizations(const Locale('zh'));

      await tester.tap(find.text(l10n.reportTabAdvice));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reportAdviceProductDetailButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(ReportProductDetailPage), findsOneWidget);

      await tester.tap(find.text(l10n.reportProductDetailCheckoutButton));
      await tester.pumpAndSettle();

      expect(find.byType(ReportCheckoutPage), findsOneWidget);

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
