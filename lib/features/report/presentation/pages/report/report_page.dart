import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/l10n/seasonal_context.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/core/widgets/app_toast.dart';
import 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';
import 'package:stitch_diag_demo/features/report/data/sources/report_remote_source.dart';
import 'package:stitch_diag_demo/features/report/application/report_unlock_service.dart';
import 'package:stitch_diag_demo/features/report/presentation/models/report_project_data.dart';
import 'package:stitch_diag_demo/features/report/presentation/models/report_product_data.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_entry_resolver.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_view_data.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

export 'report_view_data.dart';
export 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';

part 'report_screen.dart';
part 'report_widgets.dart';
part 'report_painters.dart';
part 'tabs/overview_tab.dart';
part 'tabs/constitution_tab.dart';
part 'tabs/therapy_tab.dart';
part 'tabs/advice_tab.dart';

typedef ReportAddSymptomAction =
    Future<void> Function({
      required String reportId,
      required String symptomId,
      required String symptomName,
      required String recommendType,
    });

typedef ReportDeleteSymptomAction =
    Future<void> Function({
      required String reportId,
      required String symptomId,
      required String recommendType,
    });

typedef ReportShareQrCodeLoader =
    Future<DiagnosisReportShareQrCode> Function(String reportId);

// 症状勾选目前只保留在本地页面状态里。
// 在确认可用的 api/v1 持久化接口前，这里不把勾选结果写回后端，避免产生伪保存语义。
Future<void> _noopAddReportSymptom({
  required String reportId,
  required String symptomId,
  required String symptomName,
  required String recommendType,
}) async {}

Future<void> _noopDeleteReportSymptom({
  required String reportId,
  required String symptomId,
  required String recommendType,
}) async {}

class ReportPage extends StatelessWidget {
  const ReportPage({
    super.key,
    this.reportId,
    this.loadReportViewData,
    this.loadConsultNavigate,
    this.addReportSymptom,
    this.deleteReportSymptom,
    this.loadReportShareQrCode,
  });

  final String? reportId;
  final Future<ReportViewData> Function(String reportId)? loadReportViewData;
  final Future<DiagnosisMaNavigate?> Function(ReportViewData viewData)?
  loadConsultNavigate;
  final ReportAddSymptomAction? addReportSymptom;
  final ReportDeleteSymptomAction? deleteReportSymptom;
  final ReportShareQrCodeLoader? loadReportShareQrCode;

  @override
  Widget build(BuildContext context) {
    return ReportEntryResolver(
      reportId: reportId,
      loadReportViewData: loadReportViewData,
      loadConsultNavigate: loadConsultNavigate,
      buildReportScreen: (key, viewData) => _ReportScreen(
        key: key,
        viewData: viewData,
        loadReportShareQrCode:
            loadReportShareQrCode ??
            (reportId) => ReportRemoteSource(
              getIt<DioClient>(),
            ).getReportShareQrCode(reportId),
        addReportSymptom: addReportSymptom ?? _noopAddReportSymptom,
        deleteReportSymptom: deleteReportSymptom ?? _noopDeleteReportSymptom,
      ),
    );
  }
}
