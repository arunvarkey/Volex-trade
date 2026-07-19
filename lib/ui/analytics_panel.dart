import 'package:flutter/material.dart';
import '../engine/analytics/analytics_engine.dart';
import '../engine/analytics/trade_stats.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';

class AnalyticsPanel extends StatelessWidget {
  final AnalyticsEngine analyticsEngine;

  const AnalyticsPanel({super.key, required this.analyticsEngine});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 64,
      right: 16,
      width: 280,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(VxSpacing.md),
        decoration: BoxDecoration(
          color: VxColors.surface.withValues(alpha: 0.85),
          border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: StreamBuilder<TradeStats>(
          stream: analyticsEngine.statsStream,
          initialData: analyticsEngine.currentStats,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? TradeStats.empty();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined,
                        color: VxColors.neonCyan, size: 14),
                    const SizedBox(width: 8),
                    VxText.monoBold("PERFORMANCE_CORE",
                        color: VxColors.neonCyan, fontSize: 11),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                _buildRow(
                    "Win Rate", "${(stats.winRate * 100).toStringAsFixed(1)}%"),
                _buildRow("Expectancy", stats.expectancy.toStringAsFixed(2)),
                _buildRow(
                    "Profit Factor", stats.profitFactor.toStringAsFixed(2)),
                _buildRow("Max Drawdown", stats.maxDrawdown.toStringAsFixed(2)),
                _buildRow("Total Trades", "${stats.totalTrades}"),
                const SizedBox(height: 16),
                VxText.mono("EQUITY_CURVE", color: Colors.white24, fontSize: 9),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _EquityCurvePainter(stats.equityCurve),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VxText.body(label, color: Colors.white60, fontSize: 11),
          VxText.monoBold(value, color: VxColors.neonCyan, fontSize: 11),
        ],
      ),
    );
  }
}

class _EquityCurvePainter extends CustomPainter {
  final List<double> curve;

  _EquityCurvePainter(this.curve);

  @override
  void paint(Canvas canvas, Size size) {
    if (curve.isEmpty) return;

    final strokePaint = Paint()
      ..color = VxColors.neonCyan
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    double minVal = curve.reduce((curr, next) => curr < next ? curr : next);
    double maxVal = curve.reduce((curr, next) => curr > next ? curr : next);

    if (minVal == maxVal) {
      maxVal = minVal + 1;
      minVal = minVal - 1;
    }

    final range = maxVal - minVal;
    final widthStep =
        size.width / (curve.length - 1 > 0 ? curve.length - 1 : 1);

    for (int i = 0; i < curve.length; i++) {
      final x = i * widthStep;
      final normalizedY = (curve[i] - minVal) / range;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, strokePaint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        VxColors.neonCyan.withValues(alpha: 0.2),
        VxColors.neonCyan.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _EquityCurvePainter oldDelegate) {
    return oldDelegate.curve != curve;
  }
}
