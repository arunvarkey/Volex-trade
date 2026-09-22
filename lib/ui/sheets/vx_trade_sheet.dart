import 'package:flutter/material.dart';
import '../../core/service_locator.dart';
import '../../engine/execution_manager.dart';
import '../../domain/order.dart';
import '../../domain/candle_model.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import '../design_system/charts/vx_candle_chart.dart';
import '../../services/haptic_service.dart';

/// Trade mode enum
enum TradeMode { buy, sell }

/// Unified Trade Sheet - Draggable Bottom Sheet for Quick Trading
class VxTradeSheet extends StatefulWidget {
  final String symbol;
  final double currentPrice;
  final List<Candle> candles;
  final VoidCallback? onExpand;
  final Function(int)? onNavigateToTab;
  final TradeMode initialMode;
  final double? prefillAmount;

  const VxTradeSheet({
    super.key,
    required this.symbol,
    required this.currentPrice,
    required this.candles,
    this.onExpand,
    this.onNavigateToTab,
    this.initialMode = TradeMode.buy,
    this.prefillAmount,
  });

  @override
  State<VxTradeSheet> createState() => _VxTradeSheetState();

  /// Static method to show the sheet
  static void show(
    BuildContext context, {
    required String symbol,
    required double currentPrice,
    required List<Candle> candles,
    VoidCallback? onExpand,
    Function(int)? onNavigateToTab,
    TradeMode initialMode = TradeMode.buy,
    double? prefillAmount,
  }) {
    HapticService.instance.heavy(); // Use centralized service
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => VxTradeSheet(
        symbol: symbol,
        currentPrice: currentPrice,
        candles: candles,
        onExpand: onExpand,
        onNavigateToTab: onNavigateToTab,
        initialMode: initialMode,
        prefillAmount: prefillAmount,
      ),
    );
  }
}

class _VxTradeSheetState extends State<VxTradeSheet> {
  final TextEditingController _amountController = TextEditingController();
  late bool _isBuyMode;
  double _sliderValue = 0.25; // 25% of portfolio

  @override
  void initState() {
    super.initState();
    _isBuyMode = widget.initialMode == TradeMode.buy;

    // Prefill amount if provided (for closing positions)
    final prefill = widget.prefillAmount;
    if (prefill != null) {
      _sliderValue = 1.0; // 100% when closing position
      _amountController.text = prefill.toStringAsFixed(6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: VxColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: VxColors.neonCyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Chart Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: VxCandleChart(
                candles: widget.candles,
                showVolume: false,
                showIndicators: false, // Simplified in Lite mode
              ),
            ),
          ),

          // Trading Controls
          Expanded(
            flex: 1,
            child: _buildTradingControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Symbol & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.symbol,
                      style: VxTypography.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: VxColors.neonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: VxColors.neonGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        '+2.4%',
                        style: TextStyle(
                          color: VxColors.neonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${widget.currentPrice.toStringAsFixed(2)}',
                  style: VxTypography.body.copyWith(
                    color: Colors.white70,
                    fontFamily: VxTypography.monoFamily, // Theme aligned
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (widget.onExpand != null || widget.onNavigateToTab != null)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onNavigateToTab != null) {
                  // Direct navigation to Analyst tab
                  widget.onNavigateToTab
                      ?.call(2); // Analyst is index 2 in Pro mode
                } else {
                  widget.onExpand?.call();
                }
              },
              icon: const Icon(Icons.open_in_full),
              color: VxColors.neonCyan,
              tooltip: 'Open in Analyst',
            ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  Widget _buildTradingControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Buy/Sell Toggle
            Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    label: 'BUY',
                    isSelected: _isBuyMode,
                    color: VxColors.neonGreen,
                    onTap: () => setState(() => _isBuyMode = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeButton(
                    label: 'SELL',
                    isSelected: !_isBuyMode,
                    color: VxColors.neonRed,
                    onTap: () => setState(() => _isBuyMode = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Amount Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AMOUNT',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${(_sliderValue * 100).toInt()}% of Portfolio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: VxTypography.monoFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor:
                        _isBuyMode ? VxColors.neonGreen : VxColors.neonRed,
                    inactiveTrackColor: Colors.white10,
                    thumbColor:
                        _isBuyMode ? VxColors.neonGreen : VxColors.neonRed,
                    overlayColor:
                        (_isBuyMode ? VxColors.neonGreen : VxColors.neonRed)
                            .withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    onChanged: (val) => setState(() => _sliderValue = val),
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Execute Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _executeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isBuyMode ? VxColors.neonGreen : VxColors.neonRed,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isBuyMode ? Icons.trending_up : Icons.trending_down,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isBuyMode ? 'EXECUTE BUY' : 'EXECUTE SELL',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.white54,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeOrder() async {
    final exec = getIt<ExecutionManager>();
    final side = _isBuyMode ? OrderSide.buy : OrderSide.sell;

    // Calculate quantity based on slider (mocking portfolio size if needed, or using exec balance)
    final balance = exec.balance;
    final totalValueToUse = balance * _sliderValue;
    final quantity = totalValueToUse / widget.currentPrice;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    try {
      final order = Order(
        id: '', // Generated by exec manager
        symbol: widget.symbol,
        side: side,
        type: OrderType.market,
        price: widget.currentPrice,
        quantity: quantity,
        status: OrderStatus.open,
        timestamp: DateTime.now(),
      );

      final result = await exec.placeOrderWithGuard(context, order);

      if (result?.success == true) {
        if (!mounted) return;
        HapticService.instance.successPulse(); // Distinctive success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${side.name.toUpperCase()} executed: ${quantity.toStringAsFixed(4)} ${widget.symbol}'),
            backgroundColor: VxColors.neonGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.message ?? 'Execution failed'),
            backgroundColor: VxColors.neonRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: VxColors.neonRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
