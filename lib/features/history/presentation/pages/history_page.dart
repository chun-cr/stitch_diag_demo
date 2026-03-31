import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:stitch_diag_demo/core/l10n/formatters.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
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

enum ConstitutionType { balanced, qiDeficiency, dampness }

enum RiskCategory { spleenStomach, qiDeficiency, dampness }

extension ConstitutionTypeL10n on ConstitutionType {
  String label(BuildContext context) {
    switch (this) {
      case ConstitutionType.balanced:
        return context.l10n.constitutionBalanced;
      case ConstitutionType.qiDeficiency:
        return context.l10n.constitutionQiDeficiency;
      case ConstitutionType.dampness:
        return context.l10n.constitutionDampness;
    }
  }
}

extension RiskCategoryL10n on RiskCategory {
  String label(BuildContext context) {
    switch (this) {
      case RiskCategory.spleenStomach:
        return context.l10n.riskSpleenStomach;
      case RiskCategory.qiDeficiency:
        return context.l10n.riskQiDeficiency;
      case RiskCategory.dampness:
        return context.l10n.riskDampness;
    }
  }
}

class DiagnosisRecord {
  final String id;
  final DateTime date;
  final ConstitutionType constitutionType;
  final int score;
  final String faceImageUrl;
  final bool isUnlocked;
  final double healthTrend;
  final Map<RiskCategory, double> riskIndexMap;

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
      constitutionType: ConstitutionType.balanced,
      score: 86,
      faceImageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
      isUnlocked: true,
      healthTrend: 86,
      riskIndexMap: const {
        RiskCategory.spleenStomach: 0.58,
        RiskCategory.qiDeficiency: 0.52,
        RiskCategory.dampness: 0.34,
      },
    ),
    DiagnosisRecord(
      id: 'r002',
      date: DateTime(2025, 3, 12),
      constitutionType: ConstitutionType.qiDeficiency,
      score: 82,
      faceImageUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
      isUnlocked: false,
      healthTrend: 82,
      riskIndexMap: const {
        RiskCategory.spleenStomach: 0.61,
        RiskCategory.qiDeficiency: 0.57,
        RiskCategory.dampness: 0.29,
      },
    ),
    DiagnosisRecord(
      id: 'r003',
      date: DateTime(2025, 3, 10),
      constitutionType: ConstitutionType.balanced,
      score: 88,
      faceImageUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
      isUnlocked: true,
      healthTrend: 88,
      riskIndexMap: const {
        RiskCategory.spleenStomach: 0.54,
        RiskCategory.qiDeficiency: 0.49,
        RiskCategory.dampness: 0.25,
      },
    ),
    DiagnosisRecord(
      id: 'r004',
      date: DateTime(2025, 3, 8),
      constitutionType: ConstitutionType.dampness,
      score: 78,
      faceImageUrl:
          'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=800&q=80',
      isUnlocked: false,
      healthTrend: 78,
      riskIndexMap: const {
        RiskCategory.spleenStomach: 0.68,
        RiskCategory.qiDeficiency: 0.42,
        RiskCategory.dampness: 0.48,
      },
    ),
    DiagnosisRecord(
      id: 'r005',
      date: DateTime(2025, 3, 6),
      constitutionType: ConstitutionType.balanced,
      score: 84,
      faceImageUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80',
      isUnlocked: true,
      healthTrend: 84,
      riskIndexMap: const {
        RiskCategory.spleenStomach: 0.56,
        RiskCategory.qiDeficiency: 0.46,
        RiskCategory.dampness: 0.30,
      },
    ),
    DiagnosisRecord(
      id: 'r006',
      date: DateTime(2025, 3, 4),
      constitutionType: ConstitutionType.qiDeficiency,
      score: 80,
      faceImageUrl:
          'https://images.unsplash.com/photo-1521119989659-a83eee488004?auto=format&fit=crop&w=800&q=80',
      isUnlocked: false,
      healthTrend: 80,
      riskIndexMap: const {
        RiskCategory.spleenStomach: 0.60,
        RiskCategory.qiDeficiency: 0.55,
        RiskCategory.dampness: 0.32,
      },
    ),
  ];
}

class HistoryReportPage extends StatefulWidget {
  final List<DiagnosisRecord> records;

  const HistoryReportPage({super.key, this.records = const []});

  @override
  State<HistoryReportPage> createState() => _HistoryReportPageState();
}

class _HistoryReportPageState extends State<HistoryReportPage> {
  late final List<DiagnosisRecord> _records;
  late final Map<RiskCategory, bool> _riskVisible;
  late final Set<int> _xAxisLabelIndexes;
  int? _trendTouchedIndex;
  int? _riskTouchedIndex;

  static const _riskColors = {
    RiskCategory.spleenStomach: _kEarth,
    RiskCategory.qiDeficiency: Color(0xFF5C8768),
    RiskCategory.dampness: Color(0xFF8A5C7C),
  };

  @override
  void initState() {
    super.initState();
    _records =
        (widget.records.isEmpty
                ? DiagnosisRecord.sampleRecords
                : widget.records)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final keys = <RiskCategory>{
      for (final record in _records) ...record.riskIndexMap.keys,
    };
    _riskVisible = {for (final key in keys) key: true};
    _xAxisLabelIndexes = _buildSparseLabelIndexes(_records.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.historyReportTitle,
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
                _SectionTitle(title: context.l10n.historyPastReports),
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
                  onUnlock: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(content: Text(context.l10n.commonFeatureInDevelopment)),
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
    final trendMinY = _trendMinY;
    final trendMaxY = _trendMaxY;

    return _ChartSectionCard(
      title: context.l10n.historyHealthTrend,
      child: SizedBox(
        height: 236,
        child: LineChart(
          LineChartData(
            minX: _chartMinX,
            maxX: _chartMaxX,
            minY: trendMinY,
            maxY: trendMaxY,
            lineTouchData: _buildTouchData(
              onTouchIndexChanged: (value) {
                if (_trendTouchedIndex == value) return;
                setState(() => _trendTouchedIndex = value);
              },
              valueFormatter: (value) => context.l10n.scoreWithUnit(value.toInt()),
              lineNameResolver: (_) => context.l10n.historyHealthIndex,
            ),
            showingTooltipIndicators: _buildTrendTooltipIndicators(),
            gridData: _buildGridData(
              horizontalInterval: _trendHorizontalInterval,
            ),
            borderData: _buildBorderData(),
            titlesData: _buildTitlesData(
              leftInterval: _trendHorizontalInterval,
              leftReservedSize: 38,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < _records.length; i++)
                    FlSpot(i.toDouble(), _records[i].healthTrend),
                ],
                isCurved: true,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_kPrimaryGreen, _kPrimaryGreenLight],
                  stops: [0.08, 0.92],
                ),
                barWidth: 1.7,
                isStrokeCapRound: true,
                curveSmoothness: 0.28,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kPrimaryGreenLight.withValues(alpha: 0.18),
                      _kPrimaryGreen.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) =>
                      spot.x.toInt() == _records.length - 1,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3.0,
                      color: _kCardBg,
                      strokeWidth: 1.7,
                      strokeColor: _kPrimaryGreen,
                    );
                  },
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
    final lineBarsData = keys
        .map((key) {
          final active = _riskVisible[key] ?? false;
          final color = _riskColors[key] ?? _kPrimaryGreen;
          final lineColor = color.withValues(alpha: active ? 0.94 : 0.16);
          return LineChartBarData(
            spots: [
              for (var i = 0; i < _records.length; i++)
                FlSpot(i.toDouble(), _records[i].riskIndexMap[key] ?? 0),
            ],
            isCurved: true,
            color: lineColor,
            barWidth: 1.7,
            isStrokeCapRound: true,
            curveSmoothness: 0.22,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: active ? 0.14 : 0.03),
                  color.withValues(alpha: active ? 0.02 : 0.0),
                ],
              ),
            ),
            dotData: const FlDotData(show: false),
          );
        })
        .toList();

    return _ChartSectionCard(
      title: context.l10n.historyRiskTrend,
      child: Column(
        children: [
          SizedBox(
            height: 236,
            child: LineChart(
              LineChartData(
                minX: _chartMinX,
                maxX: _chartMaxX,
                minY: 0,
                maxY: 1,
                lineTouchData: _buildTouchData(
                  enabled: lineBarsData.isNotEmpty,
                  onTouchIndexChanged: (value) {
                    if (_riskTouchedIndex == value) return;
                    setState(() => _riskTouchedIndex = value);
                  },
                  valueFormatter: (value) => context.l10n.percentValue((value * 100).round()),
                  lineNameResolver: (bar) => _riskCategoryForBar(bar).label(context),
                ),
                showingTooltipIndicators: _buildRiskTooltipIndicators(
                  lineBarsData,
                ),
                gridData: _buildGridData(horizontalInterval: 0.25),
                borderData: _buildBorderData(),
                titlesData: _buildTitlesData(
                  showLeftPercent: true,
                  leftInterval: 0.25,
                  leftReservedSize: 40,
                ),
                lineBarsData: lineBarsData,
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
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? _kTextPrimary : _kTextHint,
                    letterSpacing: 0.2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                          Text(key.label(context)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitlesData({
    bool showLeftPercent = false,
    required double leftInterval,
    required double leftReservedSize,
  }) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: leftReservedSize,
          interval: leftInterval,
          getTitlesWidget: (value, meta) {
            if (value < meta.min || value > meta.max) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                showLeftPercent
                    ? '${(value * 100).round()}%'
                    : value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: _kTextHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _bottomTitlesReservedSize,
          getTitlesWidget: (value, meta) {
            final roundedValue = value.roundToDouble();
            if ((value - roundedValue).abs() > 0.001) {
              return const SizedBox.shrink();
            }
            final index = roundedValue.toInt();
            if (index < 0 || index >= _records.length) {
              return const SizedBox.shrink();
            }
            if (!_xAxisLabelIndexes.contains(index)) {
              return const SizedBox.shrink();
            }
            final label = _dateLabel(_records[index].date);
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 8,
              child: Transform.rotate(
                angle: _shouldRotateBottomLabels ? -math.pi / 4 : 0,
                alignment: Alignment.topRight,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kTextHint,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  FlGridData _buildGridData({required double horizontalInterval}) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: horizontalInterval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: const Color(0xFF1E1810).withValues(alpha: 0.07),
        strokeWidth: 0.8,
      ),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(
          color: const Color(0xFF1E1810).withValues(alpha: 0.12),
          width: 0.9,
        ),
      ),
    );
  }

  LineTouchData _buildTouchData({
    bool enabled = true,
    required ValueChanged<int?> onTouchIndexChanged,
    required String Function(double value) valueFormatter,
    required String Function(LineChartBarData barData) lineNameResolver,
  }) {
    return LineTouchData(
      enabled: enabled,
      handleBuiltInTouches: false,
      touchSpotThreshold: 24,
      touchCallback: (event, response) {
        if (event is FlTapUpEvent ||
            event is FlPanEndEvent ||
            event is FlLongPressEnd) {
          onTouchIndexChanged(null);
          return;
        }

        final spots = response?.lineBarSpots;
        if (spots == null || spots.isEmpty) {
          return;
        }

        onTouchIndexChanged(spots.first.x.toInt());
      },
      getTouchedSpotIndicator: (barData, spotIndexes) {
        final color = _lineColorOf(barData);
        return spotIndexes
            .map(
              (_) => TouchedSpotIndicatorData(
                FlLine(
                  color: color.withValues(alpha: 0.18),
                  strokeWidth: 1,
                  dashArray: [3, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 4.6,
                        color: color,
                        strokeWidth: 2.4,
                        strokeColor: Colors.white,
                      ),
                ),
              ),
            )
            .toList();
      },
      touchTooltipData: LineTouchTooltipData(
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        tooltipMargin: 10,
        tooltipRoundedRadius: 14,
        tooltipBorder: BorderSide(
          color: const Color(0xFF1E1810).withValues(alpha: 0.08),
          width: 0.8,
        ),
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipColor: (_) => _kPageBg.withValues(alpha: 0.98),
        getTooltipItems: (touchedSpots) =>
            touchedSpots.asMap().entries.map((entry) {
              final item = entry.value;
              final itemDate = _dateLabel(_records[item.x.toInt()].date);
              final itemColor = _lineColorOf(item.bar);
              final itemValueText = valueFormatter(item.y);
              final itemLineName = lineNameResolver(item.bar);
              final itemTitle = entry.key == 0 ? '$itemDate\n' : '';
              return LineTooltipItem(
                '$itemTitle$itemLineName  $itemValueText',
                TextStyle(
                  color: itemColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              );
            }).toList(),
      ),
      distanceCalculator: (offset, spotOffset) {
        final dx = (offset.dx - spotOffset.dx).abs();
        final dy = (offset.dy - spotOffset.dy).abs() * 0.35;
        return dx + dy;
      },
    );
  }

  List<ShowingTooltipIndicators> _buildTrendTooltipIndicators() {
    final index = _trendTouchedIndex;
    if (index == null || index < 0 || index >= _records.length) {
      return const [];
    }

    final barData = LineChartBarData(
      spots: [
        for (var i = 0; i < _records.length; i++)
          FlSpot(i.toDouble(), _records[i].healthTrend),
      ],
      gradient: const LinearGradient(
        colors: [_kPrimaryGreen, _kPrimaryGreenLight],
      ),
    );

    return [
      ShowingTooltipIndicators([LineBarSpot(barData, 0, barData.spots[index])]),
    ];
  }

  List<ShowingTooltipIndicators> _buildRiskTooltipIndicators(
    List<LineChartBarData> lineBarsData,
  ) {
    final index = _riskTouchedIndex;
    if (index == null ||
        index < 0 ||
        index >= _records.length ||
        lineBarsData.isEmpty) {
      return const [];
    }

    final touchedSpots = <LineBarSpot>[];
    for (var i = 0; i < lineBarsData.length; i++) {
      final barData = lineBarsData[i];
      if (!_isRiskSeriesActive(barData)) {
        continue;
      }
      if (index >= barData.spots.length) {
        continue;
      }
      touchedSpots.add(LineBarSpot(barData, i, barData.spots[index]));
    }

    if (touchedSpots.isEmpty) {
      return const [];
    }

    return [ShowingTooltipIndicators(touchedSpots)];
  }

  double get _chartMinX => _records.isEmpty ? 0 : -0.5;

  double get _chartMaxX => _records.length <= 1 ? 0.5 : _records.length - 0.5;

  bool get _shouldRotateBottomLabels => _records.length > 12;

  double get _bottomTitlesReservedSize => _shouldRotateBottomLabels ? 44 : 32;

  double get _trendHorizontalInterval {
    final range = _trendMaxY - _trendMinY;
    if (range <= 20) return 5;
    return 10;
  }

  double get _trendMinY {
    return 40;
  }

  double get _trendMaxY {
    final values = _records
        .map((record) => record.healthTrend)
        .toList(growable: false);
    if (values.isEmpty) return 100;

    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final paddedMin = math.max(0, rawMin - 5);
    final paddedMax = math.min(100, rawMax + 5);
    final range = paddedMax - paddedMin;

    if (range >= 12) {
      return paddedMax.toDouble();
    }

    final center = (rawMin + rawMax) / 2;
    return math.min(100, center + 6).toDouble();
  }

  Color _lineColorOf(LineChartBarData barData) {
    return barData.gradient?.colors.last ?? barData.color ?? _kPrimaryGreen;
  }

  RiskCategory _riskCategoryForBar(LineChartBarData barData) {
    final color = _lineColorOf(barData);
    return _riskColors.entries
        .firstWhere(
          (entry) => _sameRgb(entry.value, color),
          orElse: () => const MapEntry(RiskCategory.qiDeficiency, _kPrimaryGreen),
        )
        .key;
  }

  bool _isRiskSeriesActive(LineChartBarData barData) {
    final category = _riskCategoryForBar(barData);
    return _riskVisible[category] ?? true;
  }

  bool _sameRgb(Color a, Color b) {
    return a.r == b.r && a.g == b.g && a.b == b.b;
  }

  Set<int> _buildSparseLabelIndexes(int length) {
    if (length <= 0) return const <int>{};
    if (length == 1) return const <int>{0};
    return <int>{0, length ~/ 2, length - 1};
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month.$day';
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
      onTap: record.isUnlocked
          ? () => context.push(AppRoutes.reportAnalysis)
          : null,
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
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: _kTextHint,
                        ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreenStart.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              record.constitutionType.label(context),
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
                      _prettyDate(context, record.date),
                      style: const TextStyle(fontSize: 12, color: _kTextHint),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          record.isUnlocked
                              ? context.l10n.statusUnlocked
                              : context.l10n.statusLocked,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: _kDanger, width: 1),
                              ),
                              child: Text(
                                context.l10n.actionUnlockNow,
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

  String _prettyDate(BuildContext context, DateTime date) {
    return formatIsoLikeDate(context, date);
  }
}
