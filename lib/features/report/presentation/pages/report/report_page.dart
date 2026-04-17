import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/l10n/seasonal_context.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/report/application/report_unlock_service.dart';
import 'package:stitch_diag_demo/features/report/presentation/models/report_product_data.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_entry_resolver.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_view_data.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

export 'report_view_data.dart';

part 'report_screen.dart';
part 'report_widgets.dart';
part 'report_painters.dart';
part 'tabs/overview_tab.dart';
part 'tabs/constitution_tab.dart';
part 'tabs/therapy_tab.dart';
part 'tabs/advice_tab.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key, this.reportId, this.loadReportViewData});

  final String? reportId;
  final Future<ReportViewData> Function(String reportId)? loadReportViewData;

  @override
  Widget build(BuildContext context) {
    return ReportEntryResolver(
      reportId: reportId,
      loadReportViewData: loadReportViewData,
      buildReportScreen: (key, viewData) =>
          _ReportScreen(key: key, viewData: viewData),
    );
  }
}
