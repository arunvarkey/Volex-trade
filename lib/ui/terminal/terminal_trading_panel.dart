import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/vx_colors.dart';
import '../../engine/execution_manager.dart';

class TerminalTradingPanel extends StatelessWidget {
  final double height;
  final bool isVerySmall;
  final bool isMarketOrder;
  final TextEditingController amountController;
  final Function(bool isBuy, bool isMarket) onTrade;
  final Function(bool isMarket) onToggleOrderType;

  const TerminalTradingPanel({
    super.key,
    required this.height,
    required this.isVerySmall,
    required this.isMarketOrder,
    required this.amountController,
    required this.onTrade,
    required this.onToggleOrderType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: VxColors.surface.withOpacity(0.5),
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isVerySmall ? 6 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'QUICK TRADE',
              style: TextStyle(
                color: Colors.white,
                fontSize: isVerySmall ? 10 : 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),

            // Balance Display (Portfolio Dashboard)
            Consumer<ExecutionManager>(
              builder: (context, manager, _) {
                final balance = manager.balance;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VxColors.deepBlack,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: isVerySmall ? 8 : 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isVerySmall ? 14 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Tabs
            Row(
              children: [
                Expanded(
                  child: _buildOrderTypeTab(
                    'Market',
                    isMarketOrder,
                    isVerySmall,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildOrderTypeTab(
                    'Limit',
                    !isMarketOrder,
                    isVerySmall,
                  ),
                ),
              ],
            ),

            SizedBox(height: isVerySmall ? 8 : 12),

            // Amount
            Text(
              'AMOUNT',
              style: TextStyle(
                color: Colors.white54,
                fontSize: isVerySmall ? 9 : 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: amountController,
              style: TextStyle(
                color: Colors.white,
                fontSize: isVerySmall ? 13 : 14,
              ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.001',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: VxColors.deepBlack,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: isVerySmall ? 8 : 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: isVerySmall ? 8 : 12),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: _buildTradeButton(
                    context,
                    'BUY',
                    Colors.green,
                    true,
                    isVerySmall,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildTradeButton(
                    context,
                    'SELL',
                    VxColors.neonRed,
                    false,
                    isVerySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeTab(String label, bool isSelected, bool isSmall) {
    return InkWell(
      onTap: () => onToggleOrderType(label == 'Market'),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmall ? 5 : 6),
        decoration: BoxDecoration(
          color: isSelected
              ? VxColors.neonCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected
                ? VxColors.neonCyan.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? VxColors.neonCyan : Colors.white54,
            fontSize: isSmall ? 10 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTradeButton(BuildContext context, String label, Color color,
      bool isBuy, bool isSmall) {
    return ElevatedButton(
      onPressed: () {
        final text = amountController.text.trim();
        final value = double.tryParse(text);
        if (value == null || value <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid amount greater than 0'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        onTrade(isBuy, isMarketOrder);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 3,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: isSmall ? 11 : 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
