import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../vx_colors.dart';
import 'chart_models.dart';

class VxBarChart extends StatelessWidget {
  final TradeDistribution data;

  const VxBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: [data.longWins, data.longLosses, data.shortWins, data.shortLosses]
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Colors.white54, fontSize: 10);
                switch (value.toInt()) {
                  case 0:
                    return const Text('LW', style: style);
                  case 1:
                    return const Text('LL', style: style);
                  case 2:
                    return const Text('SW', style: style);
                  case 3:
                    return const Text('SL', style: style);
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildGroup(0, data.longWins.toDouble(), VxColors.neonGreen),
          _buildGroup(
              1, data.longLosses.toDouble(), VxColors.neonRed.withOpacity(0.5)),
          _buildGroup(2, data.shortWins.toDouble(), VxColors.neonCyan),
          _buildGroup(3, data.shortLosses.toDouble(),
              VxColors.neonPurple.withOpacity(0.5)),
        ],
      ),
    );
  }

  BarChartGroupData _buildGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}
