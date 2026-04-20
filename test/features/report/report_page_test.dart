import 'dart:async';

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
  Size surfaceSize = const Size(1280, 2400),
  Widget Function(BuildContext context, GoRouterState state)? reportBuilder,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(surfaceSize);

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
        loadReportViewData: (_) async => buildReportViewData(
          summary: 'Recovered live summary',
          categoryProbabilities: const [
            {'name': '神志精神及情绪', 'prob': 0.89},
            {'name': '作息睡眠', 'prob': 0.69},
            {'name': '两性泌尿生殖', 'prob': 0.67},
            {'name': '消化道', 'prob': 0.41},
          ],
        ),
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

  testWidgets('constitution detail table reflects live constitution ranking', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          constitutionScores: const [
            {'id': 'balanced', 'name': 'Balanced', 'score': 40},
            {'id': 'qi', 'name': 'Qi deficiency', 'score': 35},
            {'id': 'yang', 'name': 'Yang deficiency', 'score': 20},
          ],
          tzpdResults: const [
            {'id': 'qi', 'score': 30},
            {'id': 'yang', 'score': 15},
          ],
          categoryProbabilities: const [],
        ),
      ),
    );

    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();

    final qiLabel = find.text('Qi deficiency').last;
    final balancedLabel = find.text('Balanced').last;
    final yangLabel = find.text('Yang deficiency').last;

    expect(find.text('Qi deficiency'), findsWidgets);
    expect(find.text('Balanced'), findsWidgets);
    expect(find.text('Yang deficiency'), findsOneWidget);
    expect(
      tester.getTopLeft(qiLabel).dy,
      lessThan(tester.getTopLeft(balancedLabel).dy),
    );
    expect(
      tester.getTopLeft(balancedLabel).dy,
      lessThan(tester.getTopLeft(yangLabel).dy),
    );

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('risk section hides when there is no risk data', (tester) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async =>
            buildReportViewData(categoryProbabilities: const []),
      ),
    );

    expect(find.text('风险指数'), findsNothing);
    expect(
      find.byKey(const ValueKey('report_risk_consult_button')),
      findsNothing,
    );

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('health radar hides when both symptom sources are empty', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async =>
            buildReportViewData(relativeSyms: const [], predictions: const []),
      ),
    );

    expect(find.text('健康雷达'), findsNothing);
    expect(
      find.byKey(const ValueKey('report_health_radar_mode_switch')),
      findsNothing,
    );

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'health radar shows empty classic state then switches to ai deep data',
    (tester) async {
      final router = await _pumpReportRouter(
        tester,
        reportBuilder: (context, state) => ReportPage(
          reportId: 'live-report',
          loadReportViewData: (_) async => buildReportViewData(
            relativeSyms: const [],
            predictions: const [
              {'id': 'deep-1', 'name': '声音无力', 'prob': 0.63},
            ],
          ),
        ),
      );

      expect(find.text('健康雷达'), findsOneWidget);
      expect(find.text('暂无数据'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('report_health_radar_mode_switch')),
      );
      await tester.pumpAndSettle();

      expect(find.text('声音无力'), findsOneWidget);
      expect(find.text('暂无数据'), findsNothing);

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'health radar taps persist classic and ai deep symptoms with miniapp recommend types',
    (tester) async {
      final calls = <String>[];
      final router = await _pumpReportRouter(
        tester,
        reportBuilder: (context, state) => ReportPage(
          reportId: 'live-report',
          loadReportViewData: (_) async => buildReportViewData(
            relativeSyms: const [
              {'id': 'classic-1', 'name': '饭后胃胀痛'},
            ],
            predictions: const [
              {'id': 'deep-1', 'name': '声音无力', 'prob': 0.63},
            ],
          ),
          addReportSymptom:
              ({
                required reportId,
                required symptomId,
                required symptomName,
                required recommendType,
              }) async {
                calls.add('add:$recommendType:$symptomId:$symptomName');
              },
          deleteReportSymptom:
              ({
                required reportId,
                required symptomId,
                required recommendType,
              }) async {
                calls.add('delete:$recommendType:$symptomId');
              },
        ),
      );

      await tester.tap(find.text('饭后胃胀痛'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('饭后胃胀痛'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('report_health_radar_mode_switch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('声音无力'));
      await tester.pumpAndSettle();

      expect(
        calls,
        equals([
          'add:2:classic-1:饭后胃胀痛',
          'delete:2:classic-1',
          'add:1:deep-1:声音无力',
        ]),
      );

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('risk cards fit on handset viewport without overflow', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 844),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          summary: 'Recovered live summary',
          categoryProbabilities: const [
            {'name': '绁炲織绮剧鍙婃儏缁?', 'prob': 0.89},
            {'name': '浣滄伅鐫＄湢', 'prob': 0.69},
            {'name': '涓ゆ€ф硨灏跨敓娈?', 'prob': 0.67},
            {'name': '娑堝寲閬?', 'prob': 0.41},
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('consult cta appears after sidecar navigate loads', (
    tester,
  ) async {
    final consultCompleter = Completer<DiagnosisMaNavigate?>();
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          summary: 'Recovered live summary',
          categoryProbabilities: const [
            {'name': '消化道', 'prob': 0.41},
            {'name': '神志精神及情绪', 'prob': 0.89},
            {'name': '作息睡眠', 'prob': 0.69},
            {'name': '两性泌尿生殖', 'prob': 0.67},
            {'name': '睡眠失调', 'prob': 0.58},
          ],
        ),
        loadConsultNavigate: (_) => consultCompleter.future,
      ),
    );

    expect(find.text('风险指数'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_risk_consult_button')),
      findsNothing,
    );

    consultCompleter.complete(
      const DiagnosisMaNavigate(
        type: 'QR',
        appId: '',
        path: '',
        imageUrl: '',
        imageTitle: '专家解读',
        title: '专家解读',
        raw: <String, dynamic>{},
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('report_risk_consult_button')),
      findsOneWidget,
    );
    expect(find.text('睡眠失调'), findsNothing);

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
