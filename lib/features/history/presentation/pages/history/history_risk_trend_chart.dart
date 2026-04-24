import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_record.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_style.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HistoryRiskTrendChart extends StatefulWidget {
  const HistoryRiskTrendChart({super.key, required this.records});

  final List<DiagnosisRecord> records;

  @override
  State<HistoryRiskTrendChart> createState() => _HistoryRiskTrendChartState();
}

class _HistoryRiskTrendChartState extends State<HistoryRiskTrendChart> {
  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  static const bool _enableEmbeddedECharts = bool.fromEnvironment(
    'ENABLE_HISTORY_ECHARTS',
    defaultValue: false,
  );
  static const List<Color> _seriesPalette = <Color>[
    historyEarth,
    Color(0xFF5C8768),
    Color(0xFF8A5C7C),
    Color(0xFF4C7EA8),
    Color(0xFFB46B4D),
    Color(0xFF6A63A8),
  ];

  WebViewController? _controller;
  List<DiagnosisRecord> _records = const <DiagnosisRecord>[];
  List<_RiskTrendSeries> _series = const <_RiskTrendSeries>[];
  Map<String, bool> _visible = const <String, bool>{};
  int? _touchedIndex;
  bool _chartLoadFailed = false;

  bool get _supportsEmbeddedECharts {
    if (!_enableEmbeddedECharts ||
        kIsWeb ||
        _isFlutterTest ||
        WebViewPlatform.instance == null) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia => false,
      TargetPlatform.linux => false,
      TargetPlatform.windows => false,
    };
  }

  @override
  void initState() {
    super.initState();
    _applyRecords();
    if (_supportsEmbeddedECharts) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _chartLoadFailed = true;
              });
            },
          ),
        );
      _reloadECharts();
    }
  }

  @override
  void didUpdateWidget(covariant HistoryRiskTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _applyRecords();
      _reloadECharts();
    }
  }

  void _applyRecords() {
    _records = widget.records.toList()
      ..sort((left, right) => left.date.compareTo(right.date));
    final nextSeries = _buildRiskTrendSeries(_records);
    final previousVisibility = _visible;
    _series = nextSeries;
    _visible = <String, bool>{
      for (final series in nextSeries)
        series.name: previousVisibility[series.name] ?? true,
    };
    _touchedIndex = null;
    _chartLoadFailed = false;
  }

  void _reloadECharts() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    controller.loadHtmlString(_buildChartHtml());
  }

  @override
  Widget build(BuildContext context) {
    if (_series.isEmpty) {
      return SizedBox(
        height: 236,
        child: Center(
          child: Text(
            _emptyLabel(context),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: historyTextHint,
            ),
          ),
        ),
      );
    }

    if (_supportsEmbeddedECharts && !_chartLoadFailed && _controller != null) {
      return SizedBox(
        height: 268,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: WebViewWidget(controller: _controller!),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 236,
          child: LineChart(
            LineChartData(
              minX: _chartMinX,
              maxX: _chartMaxX,
              minY: 0,
              maxY: 100,
              lineTouchData: _buildTouchData(context),
              showingTooltipIndicators: _buildTooltipIndicators(),
              gridData: _buildGridData(),
              borderData: _buildBorderData(),
              titlesData: _buildTitlesData(),
              lineBarsData: _visibleLineBarsData,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: _series
              .map((series) {
                final isActive = _visible[series.name] ?? true;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() {
                    _visible = <String, bool>{
                      ..._visible,
                      series.name: !isActive,
                    };
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
                              color: series.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(series.name),
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  List<_RiskTrendSeries> _buildRiskTrendSeries(List<DiagnosisRecord> records) {
    final valuesByName = <String, List<double?>>{};

    for (var index = 0; index < records.length; index++) {
      for (final values in valuesByName.values) {
        values.add(null);
      }

      for (final riskIndex in records[index].riskIndices) {
        final normalizedName = riskIndex.name.trim();
        if (normalizedName.isEmpty) {
          continue;
        }
        final values = valuesByName.putIfAbsent(
          normalizedName,
          () => List<double?>.filled(index + 1, null, growable: true),
        );
        values[index] = (riskIndex.value * 100).clamp(0, 100).toDouble();
      }
    }

    var colorIndex = 0;
    return valuesByName.entries
        .map(
          (entry) => _RiskTrendSeries(
            name: entry.key,
            values: List<double?>.unmodifiable(entry.value),
            color: _seriesPalette[colorIndex++ % _seriesPalette.length],
          ),
        )
        .toList(growable: false);
  }

  List<_RiskTrendSeries> get _visibleSeries => _series
      .where((series) => _visible[series.name] ?? true)
      .toList(growable: false);

  List<LineChartBarData> get _visibleLineBarsData => _visibleSeries
      .map(
        (series) => LineChartBarData(
          spots: [
            for (var index = 0; index < series.values.length; index++)
              series.values[index] == null
                  ? FlSpot.nullSpot
                  : FlSpot(index.toDouble(), series.values[index]!),
          ],
          isCurved: true,
          color: series.color,
          barWidth: 1.8,
          isStrokeCapRound: true,
          curveSmoothness: 0.2,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) =>
                spot != FlSpot.nullSpot &&
                spot.x.toInt() == _records.length - 1,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 3,
                  color: historyCardBg,
                  strokeWidth: 1.8,
                  strokeColor: series.color,
                ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      )
      .toList(growable: false);

  LineTouchData _buildTouchData(BuildContext context) {
    final lineBarsData = _visibleLineBarsData;
    return LineTouchData(
      enabled: lineBarsData.isNotEmpty,
      handleBuiltInTouches: false,
      touchSpotThreshold: 24,
      touchCallback: (event, response) {
        if (event is FlTapUpEvent ||
            event is FlPanEndEvent ||
            event is FlLongPressEnd) {
          setState(() {
            _touchedIndex = null;
          });
          return;
        }

        final spots = response?.lineBarSpots;
        if (spots == null || spots.isEmpty) {
          return;
        }

        setState(() {
          _touchedIndex = spots.first.x.toInt();
        });
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
            .map((item) {
              final itemDate = _dateLabel(_records[item.x.toInt()].date);
              final itemColor = _lineColorOf(item.bar);
              final itemSeries = _visibleSeries[item.barIndex];
              final itemTitle = item.barIndex == 0 ? '$itemDate\n' : '';
              return LineTooltipItem(
                '$itemTitle${itemSeries.name}  ${context.l10n.percentValue(item.y.round())}',
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

  List<ShowingTooltipIndicators> _buildTooltipIndicators() {
    final index = _touchedIndex;
    final lineBarsData = _visibleLineBarsData;
    if (index == null ||
        index < 0 ||
        index >= _records.length ||
        lineBarsData.isEmpty) {
      return const <ShowingTooltipIndicators>[];
    }

    final touchedSpots = <LineBarSpot>[];
    for (var lineIndex = 0; lineIndex < lineBarsData.length; lineIndex++) {
      final barData = lineBarsData[lineIndex];
      if (index >= barData.spots.length) {
        continue;
      }
      final spot = barData.spots[index];
      if (spot == FlSpot.nullSpot) {
        continue;
      }
      touchedSpots.add(LineBarSpot(barData, lineIndex, spot));
    }

    if (touchedSpots.isEmpty) {
      return const <ShowingTooltipIndicators>[];
    }

    return <ShowingTooltipIndicators>[ShowingTooltipIndicators(touchedSpots)];
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 25,
          getTitlesWidget: (value, meta) {
            if (value < meta.min || value > meta.max) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${value.round()}%',
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
          reservedSize: _shouldRotateBottomLabels ? 44 : 32,
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

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 25,
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

  double get _chartMinX => _records.isEmpty ? 0 : -0.5;

  double get _chartMaxX => _records.length <= 1 ? 0.5 : _records.length - 0.5;

  bool get _shouldRotateBottomLabels => _records.length > 12;

  Set<int> get _xAxisLabelIndexes => _buildSparseLabelIndexes(_records.length);

  Set<int> _buildSparseLabelIndexes(int length) {
    if (length <= 0) {
      return const <int>{};
    }
    if (length == 1) {
      return const <int>{0};
    }
    return <int>{0, length ~/ 2, length - 1};
  }

  Color _lineColorOf(LineChartBarData barData) {
    return barData.gradient?.colors.last ??
        barData.color ??
        historyPrimaryGreen;
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month.$day';
  }

  String _emptyLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'zh'
        ? '暂无风险指数趋势'
        : 'No risk trend yet';
  }

  String _buildChartHtml() {
    final labels = _records
        .map((record) => _dateLabel(record.date))
        .toList(growable: false);
    final option = <String, dynamic>{
      'backgroundColor': 'transparent',
      'animationDuration': 300,
      'color': _series
          .map((series) => _colorToHex(series.color))
          .toList(growable: false),
      'legend': <String, dynamic>{
        'type': 'scroll',
        'top': 0,
        'left': 0,
        'icon': 'circle',
        'itemWidth': 10,
        'itemHeight': 10,
        'textStyle': <String, dynamic>{
          'color': '#5A534D',
          'fontSize': 11,
          'fontWeight': 600,
        },
      },
      'grid': <String, dynamic>{
        'left': 36,
        'right': 12,
        'top': _series.length > 3 ? 56 : 42,
        'bottom': 28,
      },
      'tooltip': <String, dynamic>{
        'trigger': 'axis',
        'backgroundColor': 'rgba(255,248,240,0.98)',
        'borderColor': 'rgba(30,24,16,0.08)',
        'borderWidth': 1,
        'textStyle': <String, dynamic>{
          'color': '#1E1810',
          'fontSize': 11,
          'fontWeight': 600,
        },
        'axisPointer': <String, dynamic>{
          'type': 'line',
          'lineStyle': <String, dynamic>{
            'color': 'rgba(30,24,16,0.15)',
            'type': 'dashed',
          },
        },
      },
      'xAxis': <String, dynamic>{
        'type': 'category',
        'boundaryGap': false,
        'data': labels,
        'axisTick': <String, dynamic>{'show': false},
        'axisLine': <String, dynamic>{
          'lineStyle': <String, dynamic>{'color': 'rgba(30,24,16,0.12)'},
        },
        'axisLabel': <String, dynamic>{
          'color': '#8A8178',
          'fontSize': 10,
          'hideOverlap': true,
        },
      },
      'yAxis': <String, dynamic>{
        'type': 'value',
        'min': 0,
        'max': 100,
        'interval': 25,
        'splitLine': <String, dynamic>{
          'lineStyle': <String, dynamic>{'color': 'rgba(30,24,16,0.07)'},
        },
        'axisLine': <String, dynamic>{'show': false},
        'axisTick': <String, dynamic>{'show': false},
        'axisLabel': <String, dynamic>{
          'color': '#8A8178',
          'fontSize': 10,
          'formatter': '{value}%',
        },
      },
      'series': _series
          .map(
            (series) => <String, dynamic>{
              'name': series.name,
              'type': 'line',
              'smooth': true,
              'showSymbol': false,
              'symbol': 'circle',
              'symbolSize': 6,
              'connectNulls': false,
              'lineStyle': <String, dynamic>{'width': 2},
              'emphasis': <String, dynamic>{'focus': 'series'},
              'data': series.values,
            },
          )
          .toList(growable: false),
    };
    final optionJson = jsonEncode(option);

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      html, body, #chart {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        background: transparent;
      }
      body {
        overflow: hidden;
      }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>
  </head>
  <body>
    <div id="chart"></div>
    <script>
      const option = $optionJson;
      const chart = echarts.init(document.getElementById('chart'), null, { renderer: 'canvas' });
      option.tooltip.formatter = function(params) {
        if (!params || params.length === 0) {
          return '';
        }
        const lines = [params[0].axisValue];
        params.forEach(function(item) {
          const value = item.value == null ? '-' : Math.round(item.value) + '%';
          lines.push(item.marker + item.seriesName + '  ' + value);
        });
        return lines.join('<br/>');
      };
      chart.setOption(option);
      window.addEventListener('resize', function() {
        chart.resize();
      });
    </script>
  </body>
</html>
''';
  }

  String _colorToHex(Color color) {
    final red = color.r.round().toRadixString(16).padLeft(2, '0');
    final green = color.g.round().toRadixString(16).padLeft(2, '0');
    final blue = color.b.round().toRadixString(16).padLeft(2, '0');
    return '#$red$green$blue';
  }
}

class _RiskTrendSeries {
  const _RiskTrendSeries({
    required this.name,
    required this.values,
    required this.color,
  });

  final String name;
  final List<double?> values;
  final Color color;
}
