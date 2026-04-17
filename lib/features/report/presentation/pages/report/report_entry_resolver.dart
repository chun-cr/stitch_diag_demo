import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/features/report/data/sources/report_remote_source.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_view_data.dart';

class ReportEntryResolver extends StatefulWidget {
  const ReportEntryResolver({
    super.key,
    required this.reportId,
    required this.loadReportViewData,
    required this.buildReportScreen,
  });

  final String? reportId;
  final Future<ReportViewData> Function(String reportId)? loadReportViewData;
  final Widget Function(Key key, ReportViewData viewData) buildReportScreen;

  @override
  State<ReportEntryResolver> createState() => _ReportEntryResolverState();
}

class _ReportEntryResolverState extends State<ReportEntryResolver> {
  Future<ReportViewData>? _viewDataFuture;

  String? get _normalizedReportId {
    final value = widget.reportId?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _viewDataFuture = _createViewDataFuture();
  }

  @override
  void didUpdateWidget(covariant ReportEntryResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId ||
        oldWidget.loadReportViewData != widget.loadReportViewData) {
      _viewDataFuture = _createViewDataFuture();
    }
  }

  Future<ReportViewData>? _createViewDataFuture() {
    final reportId = _normalizedReportId;
    if (reportId == null) {
      return null;
    }
    return _loadLiveViewData(reportId);
  }

  Future<ReportViewData> _loadLiveViewData(String reportId) async {
    final loader = widget.loadReportViewData ?? _defaultLoadReportViewData;
    return loader(reportId);
  }

  Future<ReportViewData> _defaultLoadReportViewData(String reportId) async {
    final detail = await ReportRemoteSource(
      getIt<DioClient>(),
    ).getReportDetail(reportId);
    return ReportViewData.fromDetail(detail);
  }

  void _retry() {
    setState(() {
      _viewDataFuture = _createViewDataFuture();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportId = _normalizedReportId;
    if (reportId == null) {
      return widget.buildReportScreen(
        const ValueKey('report_mode_demo'),
        ReportViewData.demo(),
      );
    }

    return FutureBuilder<ReportViewData>(
      future: _viewDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F1EB),
            body: Center(
              child: Column(
                key: const ValueKey('report_loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(context.l10n.commonLoading),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F1EB),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  key: const ValueKey('report_error'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 44,
                      color: Color(0xFFC06A3A),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('report_retry_button'),
                      onPressed: _retry,
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return widget.buildReportScreen(
          const ValueKey('report_mode_live'),
          snapshot.requireData,
        );
      },
    );
  }
}
