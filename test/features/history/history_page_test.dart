import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_page.dart';
import 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

Future<GoRouter> _pumpHistoryRouter(
  WidgetTester tester, {
  required List<DiagnosisRecord> records,
  String initialLocation = AppRoutes.history,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => HistoryReportPage(records: records),
      ),
      GoRoute(
        path: AppRoutes.reportAnalysis,
        builder: (context, state) {
          final reportId = state.uri.queryParameters['reportId'] ?? 'missing';
          return Scaffold(body: Center(child: Text('report:$reportId')));
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
  await tester.pumpAndSettle();
  return router;
}

Future<void> _pumpHistoryPage(
  WidgetTester tester, {
  List<DiagnosisRecord> records = const <DiagnosisRecord>[],
  Future<List<DiagnosisRecord>> Function()? loadHistoryRecords,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HistoryReportPage(
        records: records,
        loadHistoryRecords: loadHistoryRecords,
      ),
    ),
  );
}

Future<void> _tearDownHistoryPage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.binding.setSurfaceSize(null);
}

DiagnosisRecord _buildRecord({
  required String id,
  required String constitutionLabel,
  required DateTime date,
  required bool isUnlocked,
  int score = 82,
  List<DiagnosisRiskIndex> riskIndices = const <DiagnosisRiskIndex>[
    DiagnosisRiskIndex(name: '脾胃', value: 0.55),
    DiagnosisRiskIndex(name: '气虚', value: 0.38),
  ],
}) {
  return DiagnosisRecord(
    id: id,
    date: date,
    constitutionType: ConstitutionType.balanced,
    constitutionLabel: constitutionLabel,
    score: score,
    faceImageUrl: '',
    isUnlocked: isUnlocked,
    healthTrend: score.toDouble(),
    riskIndices: riskIndices,
    rawSummary: DiagnosisReportSummary(
      id: id,
      testTime: date.toIso8601String(),
      healthScore: score.toDouble(),
      physiqueName: constitutionLabel,
      imageUrl: '',
      faceImageUrl: '',
      lockedStatus: isUnlocked ? '1' : '0',
      deepPredicts: const DiagnosisDeepPredicts(
        categoryProbabilities: <DiagnosisNamedProbability>[],
        predictions: <DiagnosisNamedProbability>[],
        diseases: <DiagnosisDisease>[],
        raw: <String, dynamic>{},
      ),
      raw: const <String, dynamic>{},
    ),
  );
}

void main() {
  testWidgets('history page renders provided records without loading state', (
    tester,
  ) async {
    final router = await _pumpHistoryRouter(
      tester,
      records: [
        _buildRecord(
          id: 'record-1',
          constitutionLabel: 'Balanced',
          date: DateTime(2026, 4, 10),
          isUnlocked: true,
          score: 86,
        ),
        _buildRecord(
          id: 'record-2',
          constitutionLabel: 'Qi Deficiency',
          date: DateTime(2026, 4, 12),
          isUnlocked: false,
          score: 74,
        ),
      ],
    );
    final l10n = lookupAppLocalizations(const Locale('zh'));

    expect(find.byType(HistoryReportPage), findsOneWidget);
    expect(find.text(l10n.historyHealthTrend), findsOneWidget);
    expect(find.text(l10n.historyRiskTrend), findsOneWidget);
    expect(find.text(l10n.historyPastReports), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Qi Deficiency'), findsOneWidget);
    expect(find.text('脾胃'), findsOneWidget);
    expect(find.text('气虚'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    router.dispose();
    await _tearDownHistoryPage(tester);
  });

  testWidgets('tapping unlocked history record navigates to report analysis', (
    tester,
  ) async {
    final router = await _pumpHistoryRouter(
      tester,
      records: [
        _buildRecord(
          id: 'record-42',
          constitutionLabel: 'Balanced',
          date: DateTime(2026, 4, 10),
          isUnlocked: true,
        ),
      ],
    );

    await tester.tap(find.text('Balanced'));
    await tester.pumpAndSettle();

    expect(find.text('report:record-42'), findsOneWidget);

    router.dispose();
    await _tearDownHistoryPage(tester);
  });

  testWidgets(
    'locked history record shows unlock action instead of navigating',
    (tester) async {
      final router = await _pumpHistoryRouter(
        tester,
        records: [
          _buildRecord(
            id: 'record-99',
            constitutionLabel: 'Dampness',
            date: DateTime(2026, 4, 11),
            isUnlocked: false,
          ),
        ],
      );
      final l10n = lookupAppLocalizations(const Locale('zh'));

      expect(find.text(l10n.actionUnlockNow), findsOneWidget);

      await tester.tap(find.text(l10n.actionUnlockNow));
      await tester.pumpAndSettle();

      expect(find.text(l10n.commonFeatureInDevelopment), findsOneWidget);
      expect(find.text('report:record-99'), findsNothing);

      router.dispose();
      await _tearDownHistoryPage(tester);
    },
  );

  testWidgets('history page loads records through injected loader', (
    tester,
  ) async {
    final completer = Completer<List<DiagnosisRecord>>();

    await _pumpHistoryPage(tester, loadHistoryRecords: () => completer.future);

    expect(find.byKey(const ValueKey('history_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete(<DiagnosisRecord>[
      _buildRecord(
        id: 'record-remote',
        constitutionLabel: 'Balanced',
        date: DateTime(2026, 4, 13),
        isUnlocked: true,
      ),
    ]);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('history_records_loaded')),
      findsOneWidget,
    );
    expect(find.text('Balanced'), findsOneWidget);

    await _tearDownHistoryPage(tester);
  });

  testWidgets('history page retries after loader failure', (tester) async {
    var attempts = 0;

    await _pumpHistoryPage(
      tester,
      loadHistoryRecords: () {
        attempts += 1;
        if (attempts == 1) {
          return Future<List<DiagnosisRecord>>.error(StateError('load failed'));
        }
        return Future<List<DiagnosisRecord>>.value(<DiagnosisRecord>[
          _buildRecord(
            id: 'record-retry',
            constitutionLabel: 'Qi Deficiency',
            date: DateTime(2026, 4, 14),
            isUnlocked: true,
          ),
        ]);
      },
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('history_error')), findsOneWidget);
    expect(find.byKey(const ValueKey('history_retry_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('history_retry_button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('history_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(
      find.byKey(const ValueKey('history_records_loaded')),
      findsOneWidget,
    );
    expect(find.text('Qi Deficiency'), findsOneWidget);

    await _tearDownHistoryPage(tester);
  });

  testWidgets('history page shows empty state when loader returns no records', (
    tester,
  ) async {
    await _pumpHistoryPage(
      tester,
      loadHistoryRecords: () async => <DiagnosisRecord>[],
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('history_records_loaded')),
      findsOneWidget,
    );
    expect(find.text('暂无历史报告'), findsOneWidget);

    await _tearDownHistoryPage(tester);
  });
}
