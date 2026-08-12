import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_coin_icon.dart';
import 'package:volex_terminal/ui/widgets/guidance_banner.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/ui/widgets/vx_disclaimer.dart';

class SmartOrderSheet extends StatefulWidget {
  final String symbol;
  final double currentPrice;
  final bool isBuy;

  const SmartOrderSheet({
    super.key,
    required this.symbol,
    required this.currentPrice,
    this.isBuy = true,
  });

  @override
  State<SmartOrderSheet> createState() => _SmartOrderSheetState();
}

class _SmartOrderSheetState extends State<SmartOrderSheet> {
  late bool _isBuy;
  bool _isMarket = true;
  final TextEditingController _amountController =
      TextEditingController(text: '0.1');

  @override
  void initState() {
    super.initState();
    _isBuy = widget.isBuy;
  }

  // Future: Leverage slider, Take Profit, Stop Loss

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<ExecutionManager>().balance;
    final qty = double.tryParse(_amountController.text) ?? 0.0;
    final cost = qty * widget.currentPrice;

    // Glassmorphism wrapper
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: VxColors.surface.withValues(alpha: 0.9), // Slightly transparent
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(top: BorderSide(color: VxColors.neutral800)),
          ),
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      VxCoinIcon(widget.symbol, size: 28),
                      const SizedBox(width: 10),
                      VxText.heading3("Trade ${widget.symbol}"),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: VxColors.neutral500),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Buy/Sell Segment
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: VxColors.neutral900,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(child: _buildSegmentButton("Buy", true)),
                    Expanded(child: _buildSegmentButton("Sell", false)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Order Type
              Row(
                children: [
                  _buildTypeButton("Market", true),
                  const SizedBox(width: 8),
                  _buildTypeButton("Limit", false),
                ],
              ),

              const GuidanceBanner(
                id: 'trade_sheet_intro',
                text:
                    'Market fills instantly at the current price. Limit waits '
                    'until the price reaches the amount you set.',
              ),

              const SizedBox(height: 16),

              // Input
              VxText.caption("Amount"),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: VxTypography.h3.copyWith(color: VxColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: VxColors.neutral900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: widget.symbol.split('USDT')[0],
                  suffixStyle:
                      VxTypography.caption.copyWith(color: VxColors.neutral500),
                ),
                onChanged: (val) => setState(() {}),
              ),

              const SizedBox(height: 10),

              // Order cost vs available balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VxText.caption(
                      'Order value  ≈ \$${cost.toStringAsFixed(2)}'),
                  VxText.caption('Balance  \$${balance.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 12),

              // Quick-size buttons (fraction of what the balance can buy)
              Row(
                children: [
                  Expanded(child: _buildQuickSize('25%', 0.25)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickSize('50%', 0.50)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickSize('75%', 0.75)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickSize('Max', 1.0)),
                ],
              ),

              const SizedBox(height: 12),

              const Center(
                child: VxDisclaimer(text: 'Paper trade — simulated funds.'),
              ),
              const SizedBox(height: 10),

              // Execute Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _handleTrade();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isBuy ? VxColors.success : VxColors.danger,
                    foregroundColor: VxColors.textPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: VxText.bodyBold(
                    _isBuy ? "BUY ${widget.symbol}" : "SELL ${widget.symbol}",
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isBuyBtn) {
    final isSelected = _isBuy == isBuyBtn;
    final color = isBuyBtn ? VxColors.success : VxColors.danger;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isBuy = isBuyBtn);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color)
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: VxText.bodyBold(label,
              color: isSelected ? color : VxColors.neutral500),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isMarketBtn) {
    final isSelected = _isMarket == isMarketBtn;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isMarket = isMarketBtn);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VxColors.neutral800 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? VxColors.neutral600 : VxColors.neutral800),
        ),
        child: VxText.caption(label,
            color: isSelected ? VxColors.textPrimary : VxColors.neutral500),
      ),
    );
  }

  Widget _buildQuickSize(String label, double pct) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        final balance = context.read<ExecutionManager>().balance;
        final affordable =
            widget.currentPrice > 0 ? balance / widget.currentPrice : 0.0;
        setState(() {
          _amountController.text = (affordable * pct).toStringAsFixed(4);
        });
      },
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: VxColors.neutral900,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: VxColors.neutral800),
        ),
        child: VxText.caption(label, color: VxColors.textSecondary),
      ),
    );
  }

  Future<void> _handleTrade() async {
    final messenger = ScaffoldMessenger.of(context);
    final qty = double.tryParse(_amountController.text);
    if (qty == null || qty <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Enter a valid amount")));
      return;
    }

    final base = widget.symbol.replaceAll('USDT', '');
    try {
      final manager = context.read<ExecutionManager>();
      final result = await manager.placeOrderWithGuard(
          context,
          Order(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            symbol: widget.symbol,
            type: _isMarket ? OrderType.market : OrderType.limit,
            side: _isBuy ? OrderSide.buy : OrderSide.sell,
            quantity: qty,
            price: widget.currentPrice, // Simplified for market
            status: OrderStatus.pending,
          ));

      if (!mounted) return;

      // The order can be declined without throwing (e.g. AI Guardian cancel).
      if (result != null && !result.success) {
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? 'Order was not placed'),
        ));
        return;
      }

      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        backgroundColor: _isBuy ? VxColors.success : VxColors.danger,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${_isBuy ? 'Bought' : 'Sold'} ${qty.toStringAsFixed(4)} $base '
          '@ \$${widget.currentPrice.toStringAsFixed(2)}',
        ),
      ));
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text("Order failed: $e")));
      }
    }
  }
}
