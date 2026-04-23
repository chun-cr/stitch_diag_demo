import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_record.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_loading_view.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_style.dart';
import 'package:stitch_diag_demo/features/report/data/sources/report_remote_source.dart';
import 'package:stitch_diag_demo/features/scan/data/models/scan_session.dart';

class HistoryEntryResolver extends StatefulWidget {
  const HistoryEntryResolver({
    super.key,
    required this.initialRecords,
    required this.loadHistoryRecords,
    required this.buildHistoryScreen,
  });

  final List<DiagnosisRecord> initialRecords;
  final Future<List<DiagnosisRecord>> Function()? loadHistoryRecords;
  final Widget Function(Key key, List<DiagnosisRecord> records)
  buildHistoryScreen;

  @override
  State<HistoryEntryResolver> createState() => _HistoryEntryResolverState();
}

class _HistoryEntryResolverState extends State<HistoryEntryResolver> {
  Future<List<DiagnosisRecord>>? _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _createRecordsFuture();
  }

  @override
  void didUpdateWidget(covariant HistoryEntryResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRecords != widget.initialRecords ||
        oldWidget.loadHistoryRecords != widget.loadHistoryRecords) {
      _recordsFuture = _createRecordsFuture();
    }
  }

  Future<List<DiagnosisRecord>>? _createRecordsFuture() {
    if (widget.initialRecords.isNotEmpty) {
      return null;
    }
    return _loadHistoryRecords();
  }

  Future<List<DiagnosisRecord>> _loadHistoryRecords() async {
    final loader = widget.loadHistoryRecords ?? _defaultLoadHistoryRecords;
    return loader();
  }

  Future<List<DiagnosisRecord>> _defaultLoadHistoryRecords() async {
    final summaries = await ReportRemoteSource(
      getIt<DioClient>(),
    ).getAllReports(source: ScanSession.reportSource, resolveFaceImages: true);
    return summaries.map(DiagnosisRecord.fromSummary).toList();
  }

  void _retry() {
    setState(() {
      _recordsFuture = _createRecordsFuture();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialRecords.isNotEmpty) {
      return widget.buildHistoryScreen(
        const ValueKey('history_records_provided'),
        widget.initialRecords,
      );
    }

    return FutureBuilder<List<DiagnosisRecord>>(
      future: _recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const HistoryLoadingView();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: historyPageBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  key: const ValueKey('history_error'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 44,
                      color: Color(0xFFC06A3A),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('history_retry_button'),
                      onPressed: _retry,
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return widget.buildHistoryScreen(
          const ValueKey('history_records_loaded'),
          snapshot.requireData,
        );
      },
    );
  }
}
