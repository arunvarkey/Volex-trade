import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';
import 'package:volex_terminal/ui/design_system/charts/vx_candle_chart.dart';
import 'package:volex_terminal/data/market_data_repository.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';
// import 'package:volex_terminal/domain/position.dart';

class TradeSheet extends StatefulWidget {
  final String symbol;

  const TradeSheet({super.key, required this.symbol});

  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  // Trade Config
  final double _tradeQuantity = 0.001;
  bool _isLoading = false;
  late Stream<List<Candle>> _candleStream;

  @override
  void initState() {
    super.initState();
    _candleStream =
        MarketDataRepository().getHistoryStream(widget.symbol, "1m");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: VxColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: VxColors.neonCyan, width: 2)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(VxSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VxText.title(widget.symbol, color: Colors.white),
                    StreamBuilder<Candle>(
                      stream: MarketDataRepository().updatesStream,
                      builder: (context, snapshot) {
                        final price =
                            snapshot.hasData ? snapshot.data!.close : 0.0;
                        return VxText.monoBold("\$${price.toStringAsFixed(2)}",
                            color: VxColors.neonGreen);
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  color: VxColors.neonCyan,
                  tooltip: "Full Analyst View",
                  onPressed: () {
                    context.pop(); // Close sheet
                    context.push(
                        '/chart?symbol=${widget.symbol}'); // Go to full chart
                  },
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10),

          // Chart Area
          Expanded(
            child: StreamBuilder<List<Candle>>(
              stream: _candleStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: VxColors.neonCyan));
                }
                return VxCandleChart(
                  candles: snapshot.data!,
                  showIndicators: false, // Clean view for mobile sheet
                  showVolume: false,
                );
              },
            ),
          ),

          const SizedBox(height: VxSpacing.md),

          // Trading Controls
          Container(
            padding: const EdgeInsets.all(VxSpacing.md),
            decoration: const BoxDecoration(
              color: VxColors.surface,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                // Quantity Selector (Simplified)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VxText.caption("QUANTITY (BTC)"),
                    VxText.monoBold("0.001", color: Colors.white),
                  ],
                ),
                const SizedBox(height: VxSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _TradeActionButton(
                        label: "BUY",
                        color: VxColors.neonGreen,
                        isLoading: _isLoading,
                        onTap: () => _executeOrder(OrderDirection.long),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TradeActionButton(
                        label: "SELL",
                        color: VxColors.neonRed,
                        isLoading: _isLoading,
                        onTap: () => _executeOrder(OrderDirection.short),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                    height: VxSpacing.lg), // Safe area breathing room
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeOrder(OrderDirection direction) async {
    setState(() => _isLoading = true);
    final manager = context.read<ExecutionManager>();

    try {
      final success = await manager.placeMarketOrder(
        symbol: widget.symbol,
        side: direction == OrderDirection.long ? OrderSide.buy : OrderSide.sell,
        quantity: _tradeQuantity,
      );

      if (mounted && success.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${direction == OrderDirection.long ? 'BOUGHT' : 'SOLD'} ${widget.symbol}"),
            backgroundColor: direction == OrderDirection.long
                ? VxColors.neonGreen
                : VxColors.neonRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("$e"),
              backgroundColor: VxColors.neonRed,
              action: SnackBarAction(
                  label: "CONFIG",
                  textColor: Colors.white,
                  onPressed: () => context.push('/config'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _TradeActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _TradeActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: isLoading ? null : onTap,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
