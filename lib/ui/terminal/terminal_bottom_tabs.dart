import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/vx_colors.dart';
import '../../engine/execution_manager.dart';
import '../../domain/order.dart';
import '../../domain/symbol_info.dart';

class TerminalBottomTabs extends StatelessWidget {
  final TabController tabController;
  final double currentPrice;

  const TerminalBottomTabs({
    super.key,
    required this.tabController,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VxColors.surface.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: TabBar(
              controller: tabController,
              labelColor: VxColors.neonCyan,
              unselectedLabelColor: Colors.white54,
              indicatorColor: VxColors.neonCyan,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              tabs: const [
                Tab(text: 'OPEN ORDERS'),
                Tab(text: 'POSITIONS'),
                Tab(text: 'HISTORY'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _buildOpenOrdersList(),
                _buildPositionsList(),
                _buildHistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenOrdersList() {
    return Consumer<ExecutionManager>(
      builder: (context, manager, _) {
        final orders = manager.orders
            .where((o) =>
                o.status == OrderStatus.pending || o.status == OrderStatus.open)
            .toList();
        if (orders.isEmpty) {
          return _buildEmptyState(
              'No Open Orders', Icons.receipt_long_outlined);
        }

        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final order = orders[index];
            return ListTile(
              dense: true,
              title: Text(order.symbol,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              subtitle: Text(
                  '${order.side == OrderSide.buy ? "BUY" : "SELL"} ${order.quantity} @ ${order.price}',
                  style: TextStyle(
                      color: order.side == OrderSide.buy
                          ? VxColors.neonGreen
                          : VxColors.neonRed,
                      fontSize: 10)),
              trailing: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () {
                  final symbolInfo = SymbolRegistry.supportedSymbols.firstWhere(
                      (s) => s.symbol == order.symbol,
                      orElse: () => SymbolRegistry.defaultSymbol);
                  manager.cancelOrder(order.id, symbolInfo);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPositionsList() {
    return Consumer<ExecutionManager>(
      builder: (context, manager, _) {
        final positions = manager.orders
            .where((o) => o.status == OrderStatus.filled)
            .toList();
        if (positions.isEmpty) {
          return _buildEmptyState(
              'No Positions', Icons.account_balance_wallet_outlined);
        }

        return ListView.separated(
          itemCount: positions.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final pos = positions[index];
            final pnl = pos.unrealizedPnl ?? 0.0;
            final pnlColor = pnl >= 0 ? VxColors.neonGreen : VxColors.neonRed;

            return ListTile(
              dense: true,
              // The row showed a symbol, a size and a P&L but never which way
              // the position was betting -- so a green number on a falling
              // market was unreadable.
              title: Row(
                children: [
                  Text(pos.symbol,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    pos.side == OrderSide.buy ? 'LONG' : 'SHORT',
                    style: TextStyle(
                      color: pos.side == OrderSide.buy
                          ? VxColors.neonGreen
                          : VxColors.neonRed,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Text(
                      '${pos.quantity} @ ${pos.filledPrice?.toStringAsFixed(2) ?? "-"}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(width: 8),
                  Text('P&L: \$${pnl.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: pnlColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: TextButton(
                child: const Text('CLOSE',
                    style: TextStyle(color: VxColors.neonRed, fontSize: 10)),
                onPressed: () => manager.closeOrder(pos.id, currentPrice),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return Consumer<ExecutionManager>(
      builder: (context, manager, _) {
        final history = manager.closedOrders.reversed.toList();
        if (history.isEmpty) {
          return _buildEmptyState('No trade history yet', Icons.history);
        }
        return ListView.separated(
          itemCount: history.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final order = history[index];
            final isBuy = order.side == OrderSide.buy;
            final px = order.filledPrice ?? order.price;
            final qty = order.filledQuantity ?? order.quantity;
            final color = isBuy ? VxColors.neonGreen : VxColors.neonRed;
            return ListTile(
              dense: true,
              leading: Icon(
                  isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: color),
              title: Text(order.symbol,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              subtitle: Text(
                  '${isBuy ? "BUY" : "SELL"} $qty @ ${px.toStringAsFixed(2)}',
                  style: TextStyle(color: color, fontSize: 10)),
              trailing: Text(_formatTime(order.filledAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
