import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';

class OrderLogPanel extends StatelessWidget {
  final ExecutionManager executionManager;

  const OrderLogPanel({super.key, required this.executionManager});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      right: 20,
      width: 280,
      height: 220,
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
                      const Icon(Icons.receipt_long_outlined,
                          color: VxColors.neonCyan, size: 14),
                      const SizedBox(width: 8),
                      VxText.monoBold("ORDER_LEDGER",
                          color: VxColors.neonCyan, fontSize: 11),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: AnimatedBuilder(
                    animation: executionManager,
                    builder: (context, _) {
                      if (executionManager.orders.isEmpty) {
                        return Center(
                            child: VxText.body("NO_EXECUTIONS",
                                color: Colors.white10, fontSize: 10));
                      }

                      final orders = executionManager.orders.reversed.toList();

                      return ListView.builder(
                        itemCount: orders.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final timeStr =
                              DateFormat('HH:mm:ss').format(order.timestamp);
                          final color = order.side == OrderSide.buy
                              ? Colors.green
                              : VxColors.neonRed;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Colors.white10))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                VxText.mono(timeStr,
                                    color: Colors.white24, fontSize: 9),
                                VxText.mono(
                                    order.type.name
                                        .toUpperCase()
                                        .substring(0, 4),
                                    color: Colors.white60,
                                    fontSize: 10),
                                VxText.monoBold(order.price.toStringAsFixed(2),
                                    color: color, fontSize: 11),
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
