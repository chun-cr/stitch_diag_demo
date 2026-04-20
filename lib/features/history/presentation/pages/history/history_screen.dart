import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_record.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_style.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_widgets.dart';

class HistoryReportScreen extends StatefulWidget {
  const HistoryReportScreen({super.key, required this.records});

  final List<DiagnosisRecord> records;

  @override
  State<HistoryReportScreen> createState() => _HistoryReportScreenState();
}

class _HistoryReportScreenState extends State<HistoryReportScreen> {
  static const Map<RiskCategory, Color> _riskColors = <RiskCategory, Color>{
    RiskCategory.spleenStomach: historyEarth,
    RiskCategory.qiDeficiency: Color(0xFF5C8768),
    RiskCategory.dampness: Color(0xFF8A5C7C),
  };

  List<DiagnosisRecord> _records = const <DiagnosisRecord>[];
  Map<RiskCategory, bool> _riskVisible = const <RiskCategory, bool>{};
  Set<int> _xAxisLabelIndexes = const <int>{};
  int? _trendTouchedIndex;
  int? _riskTouchedIndex;

  @override
  void initState() {
    super.initState();
    _applyRecords(widget.records);
  }

  @override
  void didUpdateWidget(covariant HistoryReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _applyRecords(widget.records);
    }
  }

  void _applyRecords(List<DiagnosisRecord> records) {
    _records = records.toList()
      ..sort((left, right) => left.date.compareTo(right.date));
    final keys = <RiskCategory>{
      for (final record in _records) ...record.riskIndexMap.keys,
    };
    _riskVisible = <RiskCategory, bool>{for (final key in keys) key: true};
    _xAxisLabelIndexes = _buildSparseLabelIndexes(_records.length);
    _trendTouchedIndex = null;
    _riskTouchedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: historyPageBg,
      appBar: AppBar(
        backgroundColor: historyPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.historyReportTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: historyTextPrimary,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: historyTextPrimary,
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final visibleRecords = _records.reversed.toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              _buildTrendChart(context),
              const SizedBox(height: 24),
              _buildRiskChart(context),
              const SizedBox(height: 24),
              HistorySectionTitle(title: context.l10n.historyPastReports),
              const SizedBox(height: 12),
              if (_records.isEmpty) _buildEmptyState(context),
            ]),
          ),
        ),
        if (visibleRecords.isNotEmpty)
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
                (context, index) => HistoryRecordCard(
                  record: visibleRecords[index],
                  onUnlock: () => _showUnlockMessage(context),
                ),
                childCount: visibleRecords.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showUnlockMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonFeatureInDevelopment)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final message = Localizations.localeOf(context).languageCode == 'zh'
        ? '暂无历史报告'
        : 'No report history yet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: historyCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 28,
            color: historyTextHint,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: historyTextHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final trendSpots = <FlSpot>[
      for (var index = 0; index < _records.length; index++)
        FlSpot(index.toDouble(), _records[index].healthTrend),
    ];

    return HistoryChartSectionCard(
      title: context.l10n.historyHealthTrend,
      child: SizedBox(
        height: 236,
        child: LineChart(
          LineChartData(
            minX: _chartMinX,
            maxX: _chartMaxX,
            minY: _trendMinY,
            maxY: _trendMaxY,
            lineTouchData: _buildTouchData(
              onTouchIndexChanged: (value) {
                if (_trendTouchedIndex == value) {
                  return;
                }
                setState(() => _trendTouchedIndex = value);
              },
              valueFormatter: (value) =>
                  context.l10n.scoreWithUnit(value.toInt()),
              lineNameResolver: (_) => context.l10n.historyHealthIndex,
            ),
            showingTooltipIndicators: _buildTrendTooltipIndicators(trendSpots),
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
                spots: trendSpots,
                isCurved: true,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [historyPrimaryGreen, historyPrimaryGreenLight],
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
                      historyPrimaryGreenLight.withValues(alpha: 0.18),
                      historyPrimaryGreen.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) =>
                      spot.x.toInt() == _records.length - 1,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 3,
                        color: historyCardBg,
                        strokeWidth: 1.7,
                        strokeColor: historyPrimaryGreen,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskChart(BuildContext context) {
    final categories = _riskVisible.keys.toList(growable: false);
    final lineBarsData = categories
        .map((category) {
          final isActive = _riskVisible[category] ?? false;
          final color = _riskColors[category] ?? historyPrimaryGreen;
          final lineColor = color.withValues(alpha: isActive ? 0.94 : 0.16);
          return LineChartBarData(
            spots: [
              for (var index = 0; index < _records.length; index++)
                FlSpot(
                  index.toDouble(),
                  _records[index].riskIndexMap[category] ?? 0,
                ),
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
                  color.withValues(alpha: isActive ? 0.14 : 0.03),
                  color.withValues(alpha: isActive ? 0.02 : 0),
                ],
              ),
            ),
            dotData: const FlDotData(show: false),
          );
        })
        .toList(growable: false);

    return HistoryChartSectionCard(
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
                    if (_riskTouchedIndex == value) {
                      return;
                    }
                    setState(() => _riskTouchedIndex = value);
                  },
                  valueFormatter: (value) =>
                      context.l10n.percentValue((value * 100).round()),
                  lineNameResolver: (bar) =>
                      _riskCategoryForBar(bar).label(context),
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
            children: categories
                .map((category) {
                  final isActive = _riskVisible[category] ?? false;
                  final color = _riskColors[category] ?? historyPrimaryGreen;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() {
                      _riskVisible[category] = !isActive;
                    }),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? historyTextPrimary : historyTextHint,
                        letterSpacing: 0.2,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 6,
                        ),
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
                            Text(category.label(context)),
                          ],
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
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
                  color: historyTextHint,
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

            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 8,
              child: Transform.rotate(
                angle: _shouldRotateBottomLabels ? -math.pi / 4 : 0,
                alignment: Alignment.topRight,
                child: Text(
                  _dateLabel(_records[index].date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: historyTextHint,
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
            .toList(growable: false);
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
        getTooltipColor: (_) => historyPageBg.withValues(alpha: 0.98),
        getTooltipItems: (touchedSpots) => touchedSpots
            .asMap()
            .entries
            .map((entry) {
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
            })
            .toList(growable: false),
      ),
      distanceCalculator: (offset, spotOffset) {
        final dx = (offset.dx - spotOffset.dx).abs();
        final dy = (offset.dy - spotOffset.dy).abs() * 0.35;
        return dx + dy;
      },
    );
  }

  List<ShowingTooltipIndicators> _buildTrendTooltipIndicators(
    List<FlSpot> trendSpots,
  ) {
    final index = _trendTouchedIndex;
    if (index == null || index < 0 || index >= trendSpots.length) {
      return const <ShowingTooltipIndicators>[];
    }

    final barData = LineChartBarData(
      spots: trendSpots,
      gradient: const LinearGradient(
        colors: [historyPrimaryGreen, historyPrimaryGreenLight],
      ),
    );

    return <ShowingTooltipIndicators>[
      ShowingTooltipIndicators(<LineBarSpot>[
        LineBarSpot(barData, 0, barData.spots[index]),
      ]),
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
      return const <ShowingTooltipIndicators>[];
    }

    final touchedSpots = <LineBarSpot>[];
    for (var lineIndex = 0; lineIndex < lineBarsData.length; lineIndex++) {
      final barData = lineBarsData[lineIndex];
      if (!_isRiskSeriesActive(barData) || index >= barData.spots.length) {
        continue;
      }
      touchedSpots.add(LineBarSpot(barData, lineIndex, barData.spots[index]));
    }

    if (touchedSpots.isEmpty) {
      return const <ShowingTooltipIndicators>[];
    }

    return <ShowingTooltipIndicators>[ShowingTooltipIndicators(touchedSpots)];
  }

  double get _chartMinX => _records.isEmpty ? 0 : -0.5;

  double get _chartMaxX => _records.length <= 1 ? 0.5 : _records.length - 0.5;

  bool get _shouldRotateBottomLabels => _records.length > 12;

  double get _bottomTitlesReservedSize => _shouldRotateBottomLabels ? 44 : 32;

  double get _trendHorizontalInterval {
    final range = _trendMaxY - _trendMinY;
    if (range <= 20) {
      return 5;
    }
    return 10;
  }

  double get _trendMinY => 40;

  double get _trendMaxY {
    if (_records.isEmpty) {
      return 100;
    }

    final values = _records
        .map((record) => record.healthTrend)
        .toList(growable: false);
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
    return barData.gradient?.colors.last ??
        barData.color ??
        historyPrimaryGreen;
  }

  RiskCategory _riskCategoryForBar(LineChartBarData barData) {
    final color = _lineColorOf(barData);
    return _riskColors.entries
        .firstWhere(
          (entry) => _sameRgb(entry.value, color),
          orElse: () =>
              const MapEntry(RiskCategory.qiDeficiency, historyPrimaryGreen),
        )
        .key;
  }

  bool _isRiskSeriesActive(LineChartBarData barData) {
    final category = _riskCategoryForBar(barData);
    return _riskVisible[category] ?? true;
  }

  bool _sameRgb(Color left, Color right) {
    return left.r == right.r && left.g == right.g && left.b == right.b;
  }

  Set<int> _buildSparseLabelIndexes(int length) {
    if (length <= 0) {
      return const <int>{};
    }
    if (length == 1) {
      return const <int>{0};
    }
    return <int>{0, length ~/ 2, length - 1};
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month.$day';
  }
}
