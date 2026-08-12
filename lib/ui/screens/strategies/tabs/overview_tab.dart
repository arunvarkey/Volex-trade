import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_card.dart';
import 'package:volex_terminal/ui/design_system/vx_health_score.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';
import 'package:volex_terminal/ui/design_system/charts/vx_line_chart.dart';
import 'package:volex_terminal/ui/design_system/charts/mock_analytics_data.dart';

import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/engine/terminal_settings_provider.dart';

class OverviewTab extends StatelessWidget {
  final String strategyId;
  const OverviewTab({super.key, required this.strategyId});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<TerminalSettingsProvider>();
    // Mock performance series
    final performanceSeries = MockAnalyticsData.generateEquityPoints(30);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VxSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Section (Health + Key Stats)
          Row(
            children: [
              const VxHealthScore(score: 94, size: 80),
              const SizedBox(width: VxSpacing.lg),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroMetric("NET PNL", "+\$4,250", VxColors.neonGreen),
                    _buildHeroMetric("WIN RATE", "68%", VxColors.neonGreen),
                    _buildHeroMetric("SHARPE", "2.4", VxColors.neonCyan),
                  ],
                ),
              ),
            ],
          ),

          if (strategyId == 'ghost_trend_v1') ...[
            const SizedBox(height: VxSpacing.lg),
            _buildGhostMetrics(context),
          ],

          const SizedBox(height: VxSpacing.lg),

          // 2. Performance Chart
          VxCard(
            title: VxText.subtitle("PERFORMANCE (30D)", color: Colors.white),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: VxLineChart(
                points: performanceSeries,
                showGrid: true,
              ),
            ),
          ),

          const SizedBox(height: VxSpacing.lg),

          // 3. Current Positions / Risk State
          VxCard(
            title: VxText.subtitle("ACTIVE POSITIONS", color: Colors.white),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No open positions",
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
          ),

          if (settings.isProMode) ...[
            const SizedBox(height: VxSpacing.lg),
            // 4. Execution Diagnostics (Pro Only)
            VxCard(
              title: VxText.subtitle("EXECUTION DIAGNOSTICS",
                  color: VxColors.neonCyan),
              description: "Real-time engine performance and fill metrics.",
              child: Column(
                children: [
                  _buildDiagnosticRow(
                      "Engine Latency", "12ms", VxColors.neonGreen),
                  _buildDiagnosticRow(
                      "Avg. Slippage", "0.4 bps", Colors.white70),
                  _buildDiagnosticRow(
                      "Fill Quality", "99.2%", VxColors.neonGreen),
                  _buildDiagnosticRow("Queue Time", "4ms", Colors.white70),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDiagnosticRow("Last Rejection", "None", Colors.white38),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VxText.body(label, color: Colors.white54),
          VxText.monoBold(value, color: valueColor),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VxText.caption(label),
        const SizedBox(height: 4),
        VxText.monoBold(value, fontSize: 24, color: color),
      ],
    );
  }

  Widget _buildGhostMetrics(BuildContext context) {
    final controller = context.watch<ChartController>();
    final ghost = controller.ghost;

    if (ghost == null) {
      return VxCard(
        title:
            VxText.subtitle("GHOST AI PREDICTION", color: VxColors.neonCyan),
        child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
                child: Text("Waiting for sufficient market data...",
                    style: TextStyle(color: Colors.white38)))),
      );
    }

    final isUptrend = ghost.slope > 0;
    final color = isUptrend ? VxColors.neonGreen : VxColors.neonRed;

    return VxCard(
      title: VxText.subtitle("GHOST AI METRICS", color: VxColors.neonCyan),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(isUptrend ? Icons.trending_up : Icons.trending_down,
                    color: color, size: 32),
                const SizedBox(height: 4),
                VxText.caption("DIRECTION"),
              ],
            ),
            _buildHeroMetric("SLOPE", ghost.slope.toStringAsFixed(4), color),
            _buildHeroMetric(
                "CONFIDENCE",
                "${(ghost.confidence * 100).toStringAsFixed(1)}%",
                VxColors.neonCyan),
          ],
        ),
      ),
    );
  }
}
