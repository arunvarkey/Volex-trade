import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/order.dart'; // For OrderStatus
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import '../design_system/vx_spacing.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This returned a bare Column. It is registered as a full route pushed on
    // top of the shell, so with no Scaffold it had no background, no safe-area
    // inset — content ran under the status bar — and no way back other than
    // the Android hardware button, which leaves iOS users stuck on it.
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Activity'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // 1. Analytics Header
        const _AnalyticsSummaryCard(),

        const SizedBox(height: VxSpacing.md),

        // 2. Logs Header
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: VxSpacing.screenMargin),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VxText.subtitle("Activity Log", color: Colors.white54),
              const Icon(Icons.filter_list, color: Colors.white24, size: 16),
            ],
          ),
        ),

        const SizedBox(height: VxSpacing.sm),

        // 3. Log Stream
        const Expanded(child: _ActivityLogList()),
      ],
    );
  }
}

class _AnalyticsSummaryCard extends StatelessWidget {
  const _AnalyticsSummaryCard();

  @override
  Widget build(BuildContext context) {
    final exec = context.watch<ExecutionManager>();

    // Win Rate Calculation
    final closedTrades = exec.positions.where((p) => !p.isOpen).toList();
    final winners = closedTrades.where((p) => (p.realizedPnL ?? 0) > 0).length;
    final winRate =
        closedTrades.isEmpty ? 0.0 : (winners / closedTrades.length) * 100;

    final todayPnL = exec.todayPnL;
    final tradeCount =
        exec.orders.where((o) => o.status == OrderStatus.filled).length;

    return Container(
      margin: const EdgeInsets.all(VxSpacing.screenMargin),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("WIN RATE", "${winRate.toStringAsFixed(1)}%",
              winRate >= 50 ? VxColors.neonGreen : VxColors.neonRed),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildStat(
              "PNL (24H)",
              "${todayPnL >= 0 ? '+' : ''}\$${todayPnL.toStringAsFixed(0)}",
              todayPnL >= 0 ? VxColors.neonGreen : VxColors.neonRed),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildStat("TRADES", tradeCount.toString(), Colors.white),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        VxText.caption(label, color: Colors.white38),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: VxTypography.monoFamily,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _ActivityLogList extends StatelessWidget {
  const _ActivityLogList();

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<StrategyEngine>();
    final execManager = context.watch<ExecutionManager>();

    // Combine Strategy Logs with Execution Orders
    final logs = [...engine.logHistory];

    // Add filled orders as "logs"
    for (final order in execManager.orders) {
      // Only add recent ones or all? V1: All currently in memory
      if (order.status == OrderStatus.filled) {
        logs.add(StrategyLog(
          timestamp: order.timestamp,
          strategyId: 'manual',
          strategyName: 'Manual Trade',
          action: order.direction == OrderDirection.long ? 'BUY' : 'SELL',
          // "Executed 0.5 @ 104532.1" -- a bare float with no currency and
          // no indication of which side the trade took. The direction is
          // already the row's colour and icon, but the line a user reads
          // should say it too.
          message: order.direction == OrderDirection.long
              ? "Bought ${order.quantity} at "
                  "\$${order.entryPrice.toStringAsFixed(2)}"
              : "Sold ${order.quantity} at "
                  "\$${order.entryPrice.toStringAsFixed(2)}",
          symbol: order.symbol,
        ));
      }
    }

    // Sort by time descending
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (logs.isEmpty) {
      return Center(
        child: VxText.body("No recent activity", color: Colors.white10),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: VxSpacing.screenMargin),
      itemCount: logs.length + 1, // +1 for padding bottom
      itemBuilder: (context, index) {
        if (index == logs.length) {
          return const SizedBox(height: 80); // FAB Padding
        }

        final log = logs[index];
        final type = log.action;

        Color color = Colors.white54;
        IconData icon = Icons.info_outline;

        if (type == 'ERROR') {
          color = VxColors.neonRed;
          icon = Icons.error_outline;
        }
        if (type == 'SELL') {
          color = VxColors.neonRed;
          icon = Icons.arrow_downward;
        }
        if (type == 'BUY') {
          color = VxColors.neonGreen;
          icon = Icons.arrow_upward;
        }
        if (type == 'TAKE PROFIT') {
          color = VxColors.neonGreen;
          icon = Icons.attach_money;
        }

        final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);

        return InkWell(
          onTap: log.symbol != null
              ? () => context.push('/chart?symbol=${log.symbol}')
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                  left: BorderSide(color: color.withValues(alpha: 0.5), width: 3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          VxText.bodyBold(log.message, color: Colors.white70),
                          VxText.mono(timeStr,
                              color: Colors.white24, fontSize: 10),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...[
                          Text(
                            '${log.symbol} • ',
                            style: VxTypography.caption.copyWith(
                              color: VxColors.neonCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                          VxText.caption(log.strategyName,
                              color: VxColors.neonCyan.withValues(alpha: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
