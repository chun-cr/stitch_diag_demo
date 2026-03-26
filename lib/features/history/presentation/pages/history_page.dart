import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:stitch_diag_demo/core/router/app_router.dart';

const _kPageBg = Color(0xFFF4F1EB);
const _kCardBg = Colors.white;
const _kGold = Color(0xFFE6A020);
const _kTextPrimary = Color(0xFF1E1810);
const _kTextHint = Color(0xFF999999);
const _kGreenStart = Color(0xFFA8D5A2);
const _kGreenEnd = Color(0xFF4CAF50);
const _kPrimaryGreen = Color(0xFF2D6A4F);
const _kPrimaryGreenLight = Color(0xFF7EC8A0);
const _kEarth = Color(0xFF8B6914);
const _kDanger = Color(0xFFE05252);

class DiagnosisRecord {
  final String id;
  final DateTime date;
  final String constitutionType;
  final int score;
  final String faceImageUrl;
  final bool isUnlocked;
  final double healthTrend;
  final Map<String, double> riskIndexMap;

  const DiagnosisRecord({
    required this.id,
    required this.date,
    required this.constitutionType,
    required this.score,
    required this.faceImageUrl,
    required this.isUnlocked,
    required this.healthTrend,
    required this.riskIndexMap,
  });

  static final List<DiagnosisRecord> sampleRecords = [
    DiagnosisRecord(
      id: 'r001',
      date: DateTime(2025, 3, 14),
      constitutionType: '平和质',
      score: 86,
      faceImageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
      isUnlocked: true,
      healthTrend: 86,
      riskIndexMap: const {'脾胃': 0.58, '气虚': 0.52, '湿困': 0.34},
    ),
    DiagnosisRecord(
      id: 'r002',
      date: DateTime(2025, 3, 12),
      constitutionType: '气虚质',
      score: 82,
      faceImageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
      isUnlocked: false,
      healthTrend: 82,
      riskIndexMap: const {'脾胃': 0.61, '气虚': 0.57, '湿困': 0.29},
    ),
    DiagnosisRecord(
      id: 'r003',
      date: DateTime(2025, 3, 10),
      constitutionType: '平和质',
      score: 88,
      faceImageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
      isUnlocked: true,
      healthTrend: 88,
      riskIndexMap: const {'脾胃': 0.54, '气虚': 0.49, '湿困': 0.25},
    ),
    DiagnosisRecord(
      id: 'r004',
      date: DateTime(2025, 3, 8),
      constitutionType: '痰湿质',
      score: 78,
      faceImageUrl: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=800&q=80',
      isUnlocked: false,
      healthTrend: 78,
      riskIndexMap: const {'脾胃': 0.68, '气虚': 0.42, '湿困': 0.48},
    ),
    DiagnosisRecord(
      id: 'r005',
      date: DateTime(2025, 3, 6),
      constitutionType: '平和质',
      score: 84,
      faceImageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80',
      isUnlocked: true,
      healthTrend: 84,
      riskIndexMap: const {'脾胃': 0.56, '气虚': 0.46, '湿困': 0.30},
    ),
    DiagnosisRecord(
      id: 'r006',
      date: DateTime(2025, 3, 4),
      constitutionType: '气虚质',
      score: 80,
      faceImageUrl: 'https://images.unsplash.com/photo-1521119989659-a83eee488004?auto=format&fit=crop&w=800&q=80',
      isUnlocked: false,
      healthTrend: 80,
      riskIndexMap: const {'脾胃': 0.60, '气虚': 0.55, '湿困': 0.32},
    ),
  ];
}

class HistoryReportPage extends StatefulWidget {
  final List<DiagnosisRecord> records;

  const HistoryReportPage({
    super.key,
    this.records = const [],
  });

  @override
  State<HistoryReportPage> createState() => _HistoryReportPageState();
}

class _HistoryReportPageState extends State<HistoryReportPage> {
  late final List<DiagnosisRecord> _records;
  late final Map<String, bool> _riskVisible;

  static const _riskColors = {
    '脾胃': _kEarth,
    '气虚': Color(0xFF5C8768),
    '湿困': Color(0xFF7A6A4F),
  };

  @override
  void initState() {
    super.initState();
    _records = (widget.records.isEmpty
            ? DiagnosisRecord.sampleRecords
            : widget.records)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final keys = <String>{
      for (final record in _records) ...record.riskIndexMap.keys,
    };
    _riskVisible = {for (final key in keys) key: true};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '体质测评报告',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, color: _kTextPrimary),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTrendChart(),
                const SizedBox(height: 24),
                _buildRiskChart(),
                const SizedBox(height: 24),
                const _SectionTitle(title: '过往报告'),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 278,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _HistoryRecordCard(
                  record: _records.reversed.toList()[index],
                  onUnlock: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('解锁功能开发中')),
                  ),
                ),
                childCount: _records.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return _ChartSectionCard(
      title: '健康走势',
      child: SizedBox(
        height: 236,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (_records.length - 1).toDouble(),
            minY: 60,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFEEEEEE),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Color(0xFFEEEEEE)),
                bottom: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            titlesData: _buildTitlesData(),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < _records.length; i++)
                    FlSpot(i.toDouble(), _records[i].healthTrend),
                ],
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [_kPrimaryGreen, _kPrimaryGreenLight],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kPrimaryGreenLight.withValues(alpha: 0.24),
                      _kPrimaryGreen.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 4,
                    color: _kPrimaryGreen,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskChart() {
    final keys = _riskVisible.keys.toList();

    return _ChartSectionCard(
      title: '风险指数走势',
      child: Column(
        children: [
          SizedBox(
            height: 236,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_records.length - 1).toDouble(),
                minY: 0,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFEEEEEE),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Color(0xFFEEEEEE)),
                    bottom: BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                ),
                titlesData: _buildTitlesData(showLeftPercent: true),
                lineBarsData: keys
                    .where((key) => _riskVisible[key] ?? false)
                    .map(
                      (key) => LineChartBarData(
                        spots: [
                          for (var i = 0; i < _records.length; i++)
                            FlSpot(i.toDouble(), _records[i].riskIndexMap[key] ?? 0),
                        ],
                        isCurved: true,
                        color: _riskColors[key],
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 3.5,
                            color: _riskColors[key] ?? _kPrimaryGreen,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: keys.map((key) {
              final active = _riskVisible[key] ?? false;
              final color = _riskColors[key] ?? _kPrimaryGreen;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _riskVisible[key] = !active),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? color : color.withValues(alpha: 0.28),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: active ? color : _kTextHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitlesData({bool showLeftPercent = false}) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
            interval: showLeftPercent ? 0.25 : 10,
            getTitlesWidget: (value, meta) => Text(
            showLeftPercent ? '${(value * 100).round()}%' : value.toInt().toString(),
            style: const TextStyle(fontSize: 10, color: _kTextHint),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= _records.length) return const SizedBox.shrink();
            if (index % 2 != 0) return const SizedBox.shrink();
            final label = _dateLabel(_records[index].date);
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 10,
              child: Transform.rotate(
                angle: -0.55,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: _kTextHint),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2.5,
          height: 16,
          decoration: BoxDecoration(
            color: _kGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _kGold,
          ),
        ),
      ],
    );
  }
}

class _ChartSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  final DiagnosisRecord record;
  final VoidCallback onUnlock;

  const _HistoryRecordCard({required this.record, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: record.isUnlocked ? () => context.push(AppRoutes.reportAnalysis) : null,
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    const Color(0xFFFFF4E7).withValues(alpha: 0.16),
                    BlendMode.softLight,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: record.faceImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF6F1E7),
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: _kTextHint),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF6F1E7),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, color: _kTextHint),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kGreenStart.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              record.constitutionType,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kGreenEnd,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${record.score}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kDanger,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _prettyDate(record.date),
                      style: const TextStyle(fontSize: 12, color: _kTextHint),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          record.isUnlocked ? '已解锁' : '未解锁',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kTextHint.withValues(alpha: 0.9),
                          ),
                        ),
                        const Spacer(),
                        if (!record.isUnlocked)
                          GestureDetector(
                            onTap: onUnlock,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: _kDanger, width: 1),
                              ),
                              child: const Text(
                                '立即解锁',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kDanger,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
