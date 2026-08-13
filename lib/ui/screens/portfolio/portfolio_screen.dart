import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../engine/execution_manager.dart';
import '../../../domain/order.dart';
import '../../../domain/position.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_coin_icon.dart';
import '../../design_system/vx_typography.dart';
import '../../widgets/vx_holographic_card.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final executionManager = context.watch<ExecutionManager>();

    return Scaffold(
      backgroundColor: VxColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, executionManager),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildEquityCard(executionManager),
                const SizedBox(height: 24),
                _buildPerformanceSection(executionManager),
                const SizedBox(height: 24),
                _buildActivePositionsHeader(),
                const SizedBox(height: 12),
                _buildPositionsList(executionManager),
                const SizedBox(height: 24),
                _buildRecentOrdersHeader(),
                const SizedBox(height: 12),
                _buildOrdersList(executionManager, context),
                const SizedBox(height: 100), // Space for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ExecutionManager em) {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      elevation: 0,
      backgroundColor: VxColors.background,
      centerTitle: true,
      title: Text(
        'Portfolio',
        style: VxTypography.caption.copyWith(
          letterSpacing: 4.0,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => em.syncLiveBalance(),
          icon: const Icon(Icons.refresh, color: VxColors.neonCyan, size: 20),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEquityCard(ExecutionManager em) {
    final balance = em.balance;
    final pnl = em.totalPnL;
    final pnlPercent = balance > 0 ? (pnl / (balance - pnl)) * 100 : 0.0;
    final isLoss = pnl < 0;

    return VxHolographicCard(
      padding: const EdgeInsets.all(24),
      hasGlow: !isLoss,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Simulated Balance',
                style: VxTypography.caption.copyWith(
                  color: Colors.white38,
                  letterSpacing: 2.0,
                  fontSize: 10,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (em.isLiveMode ? VxColors.neonRed : VxColors.neonCyan)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        (em.isLiveMode ? VxColors.neonRed : VxColors.neonCyan)
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  em.isLiveMode ? 'LIVE' : 'PAPER',
                  style: VxTypography.caption.copyWith(
                    color: em.isLiveMode ? VxColors.neonRed : VxColors.neonCyan,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: VxTypography.hero.copyWith(
              fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isLoss ? Icons.trending_down : Icons.trending_up,
                color: isLoss ? VxColors.neonRed : VxColors.neonGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${isLoss ? '' : '+'}${pnl.toStringAsFixed(2)} (${pnlPercent.toStringAsFixed(2)}%)',
                style: VxTypography.body.copyWith(
                  color: isLoss ? VxColors.neonRed : VxColors.neonGreen,
                  fontWeight: FontWeight.w700,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(ExecutionManager em) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: VxTypography.caption.copyWith(letterSpacing: 2.0),
        ),
        const SizedBox(height: 16),
        VxHolographicCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _buildEquityCurve(em),
                        isCurved: true,
                        color: VxColors.neonCyan,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              VxColors.neonCyan.withValues(alpha: 0.15),
                              VxColors.neonCyan.withValues(alpha: 0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Trades',
                      '${em.orders.where((o) => o.status == OrderStatus.closed).length}'),
                  _buildStatColumn(
                      'Win Rate',
                      em.closedOrders.isEmpty
                          ? '—'
                          : '${((em.closedOrders.where((o) => (o.realizedPnl ?? 0) > 0).length / em.closedOrders.length) * 100).toStringAsFixed(0)}%'),
                  _buildStatColumn(
                      'Best Trade',
                      em.closedOrders.isEmpty
                          ? '—'
                          : '\$${em.closedOrders.map((o) => o.realizedPnl ?? 0.0).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<FlSpot> _buildEquityCurve(ExecutionManager em) {
    final closedPositions = em.positions
        .where((p) => !p.isOpen && p.realizedPnL != null)
        .toList()
      ..sort((a, b) => a.openedAt.compareTo(b.openedAt));

    if (closedPositions.isEmpty) {
      final startBalance =
          em.isLiveMode ? (em.balance - em.totalPnL) : 100000.0;
      return [FlSpot(0, startBalance), FlSpot(1, startBalance)];
    }

    List<FlSpot> spots = [];
    double runningBalance =
        em.isLiveMode ? (em.balance - em.totalPnL) : 100000.0;
    spots.add(FlSpot(0, runningBalance));

    for (int i = 0; i < closedPositions.length; i++) {
      runningBalance += closedPositions[i].realizedPnL ?? 0.0;
      spots.add(FlSpot((i + 1).toDouble(), runningBalance));
    }

    return spots;
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: VxTypography.price.copyWith(fontSize: 16)),
        const SizedBox(height: 4),
        Text(label,
            style: VxTypography.caption
                .copyWith(color: VxColors.textTertiary, fontSize: 11)),
      ],
    );
  }

  Widget _buildActivePositionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Open Positions',
          style: VxTypography.caption.copyWith(letterSpacing: 2.0),
        ),
      ],
    );
  }

  Widget _buildPositionsList(ExecutionManager em) {
    final positions = em.openPositions;
    if (positions.isEmpty) {
      return VxHolographicCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No open positions',
            style: VxTypography.caption.copyWith(color: Colors.white12),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: positions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildPositionCard(context, positions[index]),
    );
  }

  Widget _buildPositionCard(BuildContext context, Position pos) {
    return InkWell(
      onTap: () => context.push('/chart?symbol=${pos.symbol}'),
      borderRadius: BorderRadius.circular(12),
      child: VxHolographicCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        child: Row(
          children: [
            VxCoinIcon(pos.symbol, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pos.symbol,
                    style:
                        VxTypography.body.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${pos.quantity} Q / \$${pos.entryPrice.toStringAsFixed(2)}',
                    style: VxTypography.caption.copyWith(color: Colors.white38),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'P&L',
                  style: VxTypography.caption
                      .copyWith(fontSize: 8, color: Colors.white38),
                ),
                Text(
                  '${(pos.unrealizedPnl ?? 0.0) >= 0 ? '+' : ''}\$${(pos.unrealizedPnl ?? 0.0).toStringAsFixed(2)}',
                  style: VxTypography.price.copyWith(
                    color: (pos.unrealizedPnl ?? 0.0) >= 0
                        ? VxColors.neonGreen
                        : VxColors.neonRed,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Close position',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18, color: Colors.white38),
              onPressed: () => _closePosition(context, pos),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closePosition(BuildContext context, Position pos) async {
    final em = context.read<ExecutionManager>();
    final messenger = ScaffoldMessenger.of(context);
    final pnl = pos.unrealizedPnl ?? 0.0;
    try {
      await em.closeOrder(pos.id);
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: pnl >= 0 ? VxColors.neonGreen : VxColors.neonRed,
        content: Text(
          'Closed ${pos.symbol} · ${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not close: $e')));
    }
  }

  Widget _buildRecentOrdersHeader() {
    return Text(
      'Recent Trades',
      style: VxTypography.caption.copyWith(letterSpacing: 2.0),
    );
  }

  Widget _buildOrdersList(ExecutionManager em, BuildContext context) {
    final orders = em.orders.reversed.take(5).toList();
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('No orders yet', style: TextStyle(color: Colors.white24)),
        ),
      );
    }

    return Column(
      children: orders.map((o) => _buildOrderTile(o, context)).toList(),
    );
  }

  Widget _buildOrderTile(Order order, BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final timeStr = DateFormat('HH:mm:ss').format(order.timestamp);

    return InkWell(
      onTap: () => context.push('/chart?symbol=${order.symbol}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  isBuy ? 'BUY' : 'SELL',
                  style: VxTypography.caption.copyWith(
                    color: isBuy ? VxColors.neonGreen : VxColors.neonRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.symbol,
                      style: VxTypography.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      timeStr,
                      style: VxTypography.caption
                          .copyWith(color: Colors.white24, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '\$${order.filledPrice?.toStringAsFixed(2) ?? order.price.toStringAsFixed(2)}',
              style: VxTypography.price.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
