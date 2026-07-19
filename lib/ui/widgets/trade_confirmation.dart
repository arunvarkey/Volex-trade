import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';
import '../design_system/vx_colors.dart';

/// Modern Trade Confirmation Dialog
/// Shows order preview with risk checks before execution
class TradeConfirmationDialog extends StatelessWidget {
  final String symbol;
  final OrderSide side;
  final OrderType type;
  final double quantity;
  final double? limitPrice;
  final double currentPrice;

  const TradeConfirmationDialog({
    super.key,
    required this.symbol,
    required this.side,
    required this.type,
    required this.quantity,
    this.limitPrice,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final executionManager = context.read<ExecutionManager>();
    final orderValue = quantity * (limitPrice ?? currentPrice);
    final isBuy = side == OrderSide.buy;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: VxColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBuy
                ? Colors.green.withValues(alpha: 0.3)
                : VxColors.neonRed.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isBuy
                      ? [
                          Colors.green.withValues(alpha: 0.2),
                          Colors.green.withValues(alpha: 0.05)
                        ]
                      : [
                          VxColors.neonRed.withValues(alpha: 0.2),
                          VxColors.neonRed.withValues(alpha: 0.05)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBuy ? Colors.green : VxColors.neonRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isBuy ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONFIRM ${side.name.toUpperCase()}',
                          style: TextStyle(
                            color: isBuy ? Colors.green : VxColors.neonRed,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${type.name.toUpperCase()} ORDER',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Order Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow('Symbol', symbol),
                  const SizedBox(height: 12),
                  _buildDetailRow('Quantity', quantity.toStringAsFixed(8)),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Price',
                    type == OrderType.market
                        ? '\$${currentPrice.toStringAsFixed(2)} (Market)'
                        : '\$${limitPrice!.toStringAsFixed(2)} (Limit)',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Total Value',
                    '\$${orderValue.toStringAsFixed(2)}',
                    highlight: true,
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Available Balance',
                      '\$${executionManager.balance.toStringAsFixed(2)}'),
                  _buildDetailRow(
                    'After Order',
                    '\$${(executionManager.balance - (isBuy ? orderValue : 0)).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),

            // Risk Warning (if needed)
            if (orderValue > executionManager.balance * 0.2)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Large position: ${((orderValue / executionManager.balance) * 100).toStringAsFixed(1)}% of balance',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isBuy ? Colors.green : VxColors.neonRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isBuy ? Icons.check_circle : Icons.sell,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CONFIRM ${side.name.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? VxColors.neonCyan : Colors.white,
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Order Status Overlay - Shows "Executing..." with spinner
class OrderExecutingOverlay extends StatelessWidget {
  const OrderExecutingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: VxColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: VxColors.neonCyan.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: VxColors.neonCyan,
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'EXECUTING ORDER...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Success/Error Toast Notification
void showTradeNotification(
  BuildContext context, {
  required bool success,
  required String message,
  Order? order,
}) {
  final snackBar = SnackBar(
    content: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: success ? Colors.green : VxColors.neonRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  success ? 'Order Executed' : 'Order Failed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (order != null && success) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${order.quantity} @ \$${order.filledPrice?.toStringAsFixed(2) ?? order.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    backgroundColor: VxColors.surface,
    duration: const Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: success
            ? Colors.green.withValues(alpha: 0.3)
            : VxColors.neonRed.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    margin: const EdgeInsets.all(16),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
