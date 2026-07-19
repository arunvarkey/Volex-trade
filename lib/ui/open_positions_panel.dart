import 'dart:ui';
import 'package:flutter/material.dart';
import '../engine/chart_controller.dart';
import '../engine/execution_manager.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'package:volex_terminal/domain/order.dart';

class OpenPositionsPanel extends StatelessWidget {
  final ExecutionManager executionManager;
  final ChartController controller;

  const OpenPositionsPanel(
      {super.key, required this.executionManager, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 350, // Above OrderLogPanel
      right: 20,
      width: 280,
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: VxColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    border: Border(
                        bottom:
                            BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: VxColors.neonGreen, size: 14),
                      const SizedBox(width: 8),
                      VxText.monoBold("ACTIVE_POSITIONS",
                          color: VxColors.neonGreen, fontSize: 11),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: AnimatedBuilder(
                    animation: executionManager,
                    builder: (context, _) {
                      final activePositions = executionManager.orders
                          .where(
                              (o) => o.isOpen && o.status == OrderStatus.filled)
                          .toList();

                      if (activePositions.isEmpty) {
                        return Center(
                            child: VxText.body("NO_ACTIVE_POSITIONS",
                                color: Colors.white10, fontSize: 10));
                      }

                      return ListView.builder(
                        itemCount: activePositions.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final order = activePositions[index];
                          final pnl = order.unrealizedPnl ?? 0.0;
                          final pnlColor =
                              pnl >= 0 ? VxColors.neonGreen : VxColors.neonRed;
                          final sideColor =
                              order.direction == OrderDirection.long
                                  ? VxColors.neonCyan
                                  : VxColors.warning;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Colors.white10))),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    VxText.monoBold(
                                        order.direction == OrderDirection.long
                                            ? "LONG"
                                            : "SHORT",
                                        color: sideColor,
                                        fontSize: 10),
                                    VxText.mono(
                                        order.entryPrice.toStringAsFixed(2),
                                        color: Colors.white24,
                                        fontSize: 9),
                                  ],
                                ),
                                const Spacer(),
                                VxText.monoBold(
                                    (pnl > 0 ? "+" : "") +
                                        pnl.toStringAsFixed(2),
                                    color: pnlColor,
                                    fontSize: 11),
                                const SizedBox(width: 12),
                                // Close Button
                                GestureDetector(
                                  onTap: () {
                                    if (controller.allCandles.isNotEmpty) {
                                      final currentPrice =
                                          controller.allCandles.last.close;
                                      executionManager.closeOrder(
                                          order.id, currentPrice);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: VxColors.neonRed.withValues(alpha: 0.1),
                                      border: Border.all(
                                          color: VxColors.neonRed
                                              .withValues(alpha: 0.3)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: VxText.monoBold("CLOSE",
                                        color: VxColors.neonRed, fontSize: 8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
