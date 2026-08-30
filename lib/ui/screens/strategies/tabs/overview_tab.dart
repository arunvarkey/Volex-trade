import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_card.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';

import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/engine/execution_manager.dart';

class OverviewTab extends StatelessWidget {
  final String strategyId;
  const OverviewTab({super.key, required this.strategyId});

  @override
  Widget build(BuildContext context) {
    final execution = context.watch<ExecutionManager>();
    final openPositions = execution.openPositions
        .where((p) => p.strategyId == null || p.strategyId == strategyId)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VxSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance is only ever shown from a real backtest result. This
          // screen previously displayed invented figures — a health score of
          // 94, "+$4,250" net PnL, a 68% win rate, a 2.4 Sharpe and a fake
          // 30-day equity curve — presented as this strategy's own record.
          VxCard(
            title: VxText.subtitle("Performance", color: Colors.white),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No performance data yet.\n\n'
                  'Run this strategy through the Backtest Lab to see real '
                  'return, win rate, drawdown and risk-adjusted ratios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.5),
                ),
              ),
            ),
          ),

          if (strategyId == 'ghost_trend_v1') ...[
            const SizedBox(height: VxSpacing.lg),
            _buildGhostMetrics(context),
          ],

          const SizedBox(height: VxSpacing.lg),

          // Current positions — read from the execution engine, not invented.
          VxCard(
            title: VxText.subtitle("Active Positions", color: Colors.white),
            child: openPositions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("No open positions",
                          style: TextStyle(color: Colors.white38)),
                    ),
                  )
                : Column(
                    children: [
                      for (final p in openPositions)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              VxText.body(
                                  '${p.symbol}  ${p.quantity.toStringAsFixed(4)}',
                                  color: Colors.white70),
                              VxText.monoBold(
                                '${(p.unrealizedPnl ?? 0) >= 0 ? '+' : ''}'
                                '\$${(p.unrealizedPnl ?? 0).toStringAsFixed(2)}',
                                color: (p.unrealizedPnl ?? 0) >= 0
                                    ? VxColors.neonGreen
                                    : VxColors.neonRed,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
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
            VxText.subtitle("Trend Line", color: VxColors.neonCyan),
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
      title: VxText.subtitle("Trend Line", color: VxColors.neonCyan),
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
