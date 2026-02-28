import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../vx_colors.dart';
import 'chart_models.dart';
import 'chart_theme.dart';

class VxLineChart extends StatelessWidget {
  final List<dynamic> points; // List<EquityPoint> or List<PricePoint>
  final AnalyticsData? data; // Optional full analytics context
  final bool isProMode;
  final bool showGrid;
  final bool showDrawdown;
  final bool showVolatilityBands;

  const VxLineChart({
    super.key,
    required this.points,
    this.data,
    this.isProMode = false,
    this.showGrid = false,
    this.showDrawdown = false,
    this.showVolatilityBands = false,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text("No data available"));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Colors.white10, strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              const FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: _buildRegimeBands().cast<VerticalLine>(),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'RobotoMono',
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (points.length / 5).clamp(1.0, 1000.0), // ~5 ticks
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }

                DateTime? ts;
                final p = points[index];
                if (p is EquityPoint) {
                  ts = p.timestamp;
                } else if (p is PricePoint) {
                  ts = p.timestamp;
                }

                if (ts == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormat('MM/dd').format(ts),
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'RobotoMono'),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _buildMainLine(),
          if (showDrawdown && isProMode) _buildDrawdownLine(),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => VxColors.surface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(2),
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<dynamic> _buildRegimeBands() {
    if (!isProMode || points.isEmpty || points.first is! EquityPoint) return [];

    List<dynamic> lines = [];
    final equityPoints = points.cast<EquityPoint>();

    for (int i = 0; i < equityPoints.length; i++) {
      final regime = equityPoints[i].regime;
      if (regime == null) continue;

      Color bandColor = Colors.transparent;
      switch (regime) {
        case MarketRegime.bull:
          bandColor = VxColors.neonGreen.withOpacity(0.05);
          break;
        case MarketRegime.bear:
          bandColor = VxColors.neonRed.withOpacity(0.05);
          break;
        case MarketRegime.volatile:
          bandColor = VxColors.neonPurple.withOpacity(0.05);
          break;
        case MarketRegime.trending:
          bandColor = VxColors.neonCyan.withOpacity(0.05);
          break;
        case MarketRegime.sideways:
          bandColor = Colors.transparent;
          break;
      }

      if (bandColor != Colors.transparent) {
        lines.add(VerticalLine(
          x: i.toDouble(),
          color: bandColor,
          strokeWidth: 20,
        ));
      }
    }
    return lines;
  }

  LineChartBarData _buildMainLine() {
    return LineChartBarData(
      spots: points.asMap().entries.map((e) {
        final point = points[e.key];
        double val = 0;
        if (point is EquityPoint) {
          val = point.equity;
        } else if (point is PricePoint) {
          val = point.price;
        } else if (point is FlSpot) {
          val = point.y;
        }
        return FlSpot(e.key.toDouble(), val);
      }).toList(),
      isCurved: true,
      color: ChartTheme.cyberpunk.lineColor,
      barWidth: ChartTheme.cyberpunk.strokeWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, barData) {
          // Show dot only on the very last point ("Live Pulse")
          if (spot.x.toInt() == points.length - 1) return true;

          if (!isProMode) return false;
          // Robust check for points length
          if (spot.x.toInt() >= points.length) return false;
          final point = points[spot.x.toInt()];
          return point is EquityPoint && point.marker != null;
        },
        getDotPainter: (spot, percent, barData, index) {
          // Live Pulse Dot
          if (spot.x.toInt() == points.length - 1) {
            return FlDotCirclePainter(
              color: ChartTheme.cyberpunk.lineColor,
              strokeColor: ChartTheme.cyberpunk.lineColor.withOpacity(0.3),
              strokeWidth: 4,
              radius: 4,
            );
          }

          final point = points[spot.x.toInt()];
          if (point is EquityPoint && point.marker != null) {
            final type = point.marker!.type;
            return FlDotCirclePainter(
              color: type == TradeMarkerType.buy
                  ? VxColors.neonGreen
                  : (type == TradeMarkerType.sell
                      ? VxColors.neonRed
                      : Colors.white),
              strokeColor: VxColors.background,
              strokeWidth: 2,
              radius: 6,
            );
          }
          return FlDotCirclePainter(radius: 0);
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: ChartTheme.cyberpunk.gradientColors,
        ),
      ),
    );
  }

  LineChartBarData _buildDrawdownLine() {
    return LineChartBarData(
      spots: points.whereType<EquityPoint>().toList().asMap().entries.map((e) {
        return FlSpot(
            e.key.toDouble(), e.value.equity * (1 - e.value.drawdown));
      }).toList(),
      isCurved: true,
      color: VxColors.neonRed.withOpacity(0.3),
      barWidth: 1,
      dashArray: [5, 5],
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: VxColors.neonRed.withOpacity(0.05),
      ),
    );
  }
}
