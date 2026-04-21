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
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 250));

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report hero reflects shared backend summary fields', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          testTime: '2026-04-17 10:30',
          source: 'scan-booth',
          primaryConstitution: '气虚体质',
          therapySummary: '疏肝解郁，少食生冷，多做舒展运动。',
          faceAge: 23,
          imageUrl: 'https://example.com/tongue.png',
          faceImageUrl: 'https://example.com/face.png',
          handImageUrl: 'https://example.com/hand.png',
          analysisFindingSymptoms: const ['舌边齿痕', '舌苔白'],
          constitutionScores: const [
            {
              'id': 'constitution-primary',
              'name': '气虚体质',
              'score': 82,
              'solutions': '疏肝解郁，少食生冷，多做舒展运动。',
            },
            {
              'id': 'constitution-secondary',
              'name': '阳虚体质',
              'score': 67,
              'solutions': '',
            },
            {
              'id': 'constitution-third',
              'name': '痰湿体质',
              'score': 58,
              'solutions': '',
            },
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('report_hero_primary_constitution')),
      findsOneWidget,
    );
    expect(find.text('气虚体质'), findsWidgets);
    expect(find.text('阳虚体质'), findsOneWidget);
    expect(find.text('痰湿体质'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_hero_view_images_button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('report_hero_age_badge')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_hero_tongue_line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report_hero_therapy_line')),
      findsOneWidget,
    );
    expect(find.textContaining('2026.04.17'), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('hero grows to fit long therapy content on handset', (
    tester,
  ) async {
    final longTherapy = List.filled(4, '疏肝理气，规律作息，减少生冷甜腻，晚间泡脚并做舒展运动。').join();
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 1400),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'long-hero',
        loadReportViewData: (_) async => buildReportViewData(
          primaryConstitution: '气虚体质',
          faceAge: 23,
          therapySummary: longTherapy,
          analysisFindingSymptoms: const [
            '舌边齿痕',
            '舌苔白',
            '舌体偏胖',
            '津液稍少',
            '舌尖偏红',
          ],
          constitutionScores: const [
            {
              'id': 'constitution-primary',
              'name': '气虚体质',
              'score': 82,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-1',
              'name': '阳虚体质',
              'score': 74,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-2',
              'name': '痰湿体质',
              'score': 68,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-3',
              'name': '湿热体质',
              'score': 63,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-4',
              'name': '血瘀体质',
              'score': 57,
              'solutions': '',
            },
          ],
        ),
      ),
    );

    final therapyLine = find.byKey(const ValueKey('report_hero_therapy_line'));
    final tabBar = find.byType(TabBar);

    expect(therapyLine, findsOneWidget);
    expect(
      tester.getBottomLeft(therapyLine).dy,
      lessThan(tester.getTopLeft(tabBar).dy),
    );
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('hero stays tight to short content on handset', (tester) async {
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 844),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'short-hero',
        loadReportViewData: (_) async => buildReportViewData(
          primaryConstitution: '平和体质',
          therapySummary: '疏肝解郁，规律作息。',
          analysisFindingSymptoms: const ['舌边齿痕', '舌苔白'],
          constitutionScores: const [
            {
              'id': 'constitution-primary',
              'name': '平和体质',
              'score': 78,
              'solutions': '疏肝解郁，规律作息。',
            },
            {
              'id': 'constitution-secondary',
              'name': '阳虚体质',
              'score': 64,
              'solutions': '',
            },
          ],
        ),
      ),
    );

    final disclaimer = find.text('注：拍摄角度、光线均有可能影响分析结果。');
    final tabBar = find.byType(TabBar);

    expect(disclaimer, findsOneWidget);
    expect(
      tester.getTopLeft(tabBar).dy - tester.getBottomLeft(disclaimer).dy,
      lessThan(48),
    );
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tongue analysis keeps only the small heading in overview', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'tongue-report',
        loadReportViewData: (_) async => buildReportViewData(
          analysisFindings: const [
            {
              'type': 'tongue_isIndentation',
              'typeDesc': '齿痕',
              'symptoms': [
                {
                  'id': 'indentation-1',
                  'name': '齿痕',
                  'describe': '多见于脾虚湿盛，运化乏力。',
                },
              ],
            },
            {
              'type': 'moss_color',
              'typeDesc': '舌苔颜色',
              'symptoms': [
                {'id': 'moss-1', 'name': '舌苔白'},
              ],
            },
            {'type': 'tongue_isCrack', 'typeDesc': '舌裂', 'symptoms': []},
          ],
          categoryProbabilities: const [],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('report_overview_tongue_analysis_section')),
      findsOneWidget,
    );
    expect(find.text('舌象解析'), findsOneWidget);
    expect(find.text('辨证摘要'), findsNothing);
    expect(find.text('齿痕'), findsWidgets);
    expect(find.text('舌苔颜色'), findsOneWidget);
    expect(find.text('病理解析'), findsNWidgets(2));

    await tester.tap(find.byType(Tab).at(3));
    await tester.pumpAndSettle();

    expect(find.text('舌象解析'), findsNothing);
    expect(find.text('病理解析'), findsNothing);
    expect(find.text('检测结果'), findsNothing);

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
    expect(find.text('Yang deficiency'), findsWidgets);
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
            {'name': '神志精神及情绪', 'prob': 0.89},
            {'name': '作息睡眠', 'prob': 0.69},
            {'name': '两性泌尿生殖', 'prob': 0.67},
            {'name': '消化道', 'prob': 0.41},
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
    expect(tester.takeException(), isNull);
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
