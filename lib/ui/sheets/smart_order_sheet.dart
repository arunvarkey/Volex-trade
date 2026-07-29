import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';

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
                  VxText.heading3("Trade ${widget.symbol}"),
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

              // Visual Slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _isBuy ? VxColors.success : VxColors.danger,
                  thumbColor: VxColors.textPrimary,
                  overlayColor: (_isBuy ? VxColors.success : VxColors.danger)
                      .withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: (double.tryParse(_amountController.text) ?? 0.0)
                      .clamp(0.0, 10.0),
                  min: 0,
                  max: 10.0,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _amountController.text = val.toStringAsFixed(3);
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

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

  Future<void> _handleTrade() async {
    final qty = double.tryParse(_amountController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid Quantity")));
      return;
    }

    try {
      final manager = context.read<ExecutionManager>();
      await manager.placeOrderWithGuard(
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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
