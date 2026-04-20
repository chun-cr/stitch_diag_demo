import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_entry_resolver.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_record.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_screen.dart';

export 'history_record.dart';

class HistoryReportPage extends StatelessWidget {
  const HistoryReportPage({
    super.key,
    this.records = const <DiagnosisRecord>[],
    this.loadHistoryRecords,
  });

  final List<DiagnosisRecord> records;
  final Future<List<DiagnosisRecord>> Function()? loadHistoryRecords;

  @override
  Widget build(BuildContext context) {
    return HistoryEntryResolver(
      initialRecords: records,
      loadHistoryRecords: loadHistoryRecords,
      buildHistoryScreen: (key, resolvedRecords) =>
          HistoryReportScreen(key: key, records: resolvedRecords),
    );
  }
}
