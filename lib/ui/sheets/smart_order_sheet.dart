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
  late final TextEditingController _limitPriceController;

  /// Protective exits are ON by default: the Academy teaches that a trade
  /// without a stop is "an open-ended bet on your ego", so the ticket should
  /// make the good habit the default rather than an afterthought.
  bool _useRiskControls = true;
  final TextEditingController _slPercentController =
      TextEditingController(text: '2');
  final TextEditingController _tpPercentController =
      TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    _isBuy = widget.isBuy;
    _limitPriceController = TextEditingController(
        text: widget.currentPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _limitPriceController.dispose();
    _slPercentController.dispose();
    _tpPercentController.dispose();
    super.dispose();
  }

  /// Price the order will execute at: the live price for market orders, or the
  /// user's chosen limit price otherwise.
  double get _effectivePrice => _isMarket
      ? widget.currentPrice
      : (double.tryParse(_limitPriceController.text) ?? widget.currentPrice);

  /// Stop-loss level, expressed as a % away from entry in the losing
  /// direction (below entry for a long, above for a short). Percent input
  /// means the level can never be set on the wrong side by accident.
  double? get _stopLossPrice {
    if (!_useRiskControls) return null;
    final pct = double.tryParse(_slPercentController.text);
    if (pct == null || pct <= 0) return null;
    final p = _effectivePrice;
    return _isBuy ? p * (1 - pct / 100) : p * (1 + pct / 100);
  }

  /// Take-profit level, a % away from entry in the winning direction.
  double? get _takeProfitPrice {
    if (!_useRiskControls) return null;
    final pct = double.tryParse(_tpPercentController.text);
    if (pct == null || pct <= 0) return null;
    final p = _effectivePrice;
    return _isBuy ? p * (1 + pct / 100) : p * (1 - pct / 100);
  }

  /// Cash at risk if the stop is hit, and the reward if the target is hit.
  ({double risk, double reward, double? rr}) get _riskReward {
    final qty = double.tryParse(_amountController.text) ?? 0.0;
    final entry = _effectivePrice;
    final sl = _stopLossPrice;
    final tp = _takeProfitPrice;
    final risk = sl == null ? 0.0 : (entry - sl).abs() * qty;
    final reward = tp == null ? 0.0 : (tp - entry).abs() * qty;
    return (risk: risk, reward: reward, rr: risk > 0 ? reward / risk : null);
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<ExecutionManager>().balance;
    final qty = double.tryParse(_amountController.text) ?? 0.0;
    final cost = qty * _effectivePrice;
    // The simulator charges a taker fee on every fill, so the affordability
    // check has to include it — otherwise a "Max" buy would overdraw by
    // exactly the fee.
    final fee = ExecutionManager.feeFor(qty, _effectivePrice);
    final insufficient = _isBuy && qty > 0 && (cost + fee) > balance;

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
                    tooltip: 'Close',
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

              // Limit price (only relevant for limit orders)
              if (!_isMarket) ...[
                const SizedBox(height: 12),
                VxText.caption("Limit price"),
                const SizedBox(height: 8),
                TextField(
                  controller: _limitPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: VxTypography.h3.copyWith(color: VxColors.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: VxColors.neutral900,
                    prefixText: "\$ ",
                    prefixStyle: VxTypography.h3
                        .copyWith(color: VxColors.neutral500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ],

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
              // Fees are charged on entry and again on exit, and a trader who
              // cannot see them is being taught that they do not exist.
              if (qty > 0) ...[
                const SizedBox(height: 4),
                VxText.caption(
                  'Fee  ≈ \$${fee.toStringAsFixed(2)} per fill '
                  '(${(ExecutionManager.takerFeeRate * 100).toStringAsFixed(3)}%) '
                  '· round trip ≈ \$${(fee * 2).toStringAsFixed(2)}',
                  color: VxColors.textTertiary,
                ),
              ],
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

              const SizedBox(height: 8),

              // Size from risk, the way the Academy teaches it:
              // position size = (1% of balance) / distance to the stop.
              _buildRiskBasedSize(balance),

              const SizedBox(height: 16),

              _buildRiskControls(),

              const SizedBox(height: 12),

              const Center(
                child: VxDisclaimer(text: 'Paper trade — simulated funds.'),
              ),
              const SizedBox(height: 10),

              // Execute Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: insufficient
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          _handleTrade();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isBuy ? VxColors.success : VxColors.danger,
                    foregroundColor: VxColors.textPrimary,
                    disabledBackgroundColor: VxColors.neutral800,
                    disabledForegroundColor: VxColors.neutral500,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: VxText.bodyBold(
                    insufficient
                        ? "Insufficient balance"
                        : (_isBuy
                            ? "Buy ${widget.symbol.replaceAll('USDT', '')}"
                            : "Sell ${widget.symbol.replaceAll('USDT', '')}"),
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

  /// "Risk 1%" sizing — the position-sizing rule the Academy teaches:
  /// size = (risk budget) / (distance from entry to the stop). Requires a
  /// stop, because without one there is no defined risk to size from.
  Widget _buildRiskBasedSize(double balance) {
    final sl = _stopLossPrice;
    final entry = _effectivePrice;
    final stopDistance = sl == null ? 0.0 : (entry - sl).abs();
    final enabled = stopDistance > 0 && balance > 0;

    void applyRisk(double accountPercent) {
      if (!enabled) return;
      HapticFeedback.selectionClick();
      final riskBudget = balance * (accountPercent / 100);
      setState(() {
        _amountController.text =
            (riskBudget / stopDistance).toStringAsFixed(4);
      });
    }

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Row(
        children: [
          Expanded(
            child: VxText.caption(
              enabled
                  ? 'Size from risk'
                  : 'Set a stop loss to size by risk',
              color: VxColors.textTertiary,
            ),
          ),
          _buildRiskChip('Risk 1%', () => applyRisk(1)),
          const SizedBox(width: 8),
          _buildRiskChip('2%', () => applyRisk(2)),
        ],
      ),
    );
  }

  Widget _buildRiskChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: VxColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: VxColors.primary.withValues(alpha: 0.35)),
        ),
        child: VxText.caption(label, color: VxColors.primary),
      ),
    );
  }

  /// Stop-loss / take-profit inputs plus the risk:reward read-out. Percent
  /// inputs keep the levels on the correct side of entry automatically, and
  /// the cash figures teach what the percentages actually cost.
  Widget _buildRiskControls() {
    final rr = _riskReward;
    final sl = _stopLossPrice;
    final tp = _takeProfitPrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: VxColors.neutral900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.neutral800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: VxText.caption('Stop loss & take profit',
                    color: VxColors.textSecondary),
              ),
              Switch(
                value: _useRiskControls,
                activeThumbColor: VxColors.primary,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _useRiskControls = v);
                },
              ),
            ],
          ),
          if (_useRiskControls) ...[
            Row(
              children: [
                Expanded(
                  child: _buildPercentField(
                    controller: _slPercentController,
                    label: 'Stop loss',
                    level: sl,
                    color: VxColors.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPercentField(
                    controller: _tpPercentController,
                    label: 'Take profit',
                    level: tp,
                    color: VxColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VxText.caption('Risk \$${rr.risk.toStringAsFixed(2)}',
                    color: VxColors.danger),
                VxText.caption('Reward \$${rr.reward.toStringAsFixed(2)}',
                    color: VxColors.success),
                VxText.caption(
                  rr.rr == null
                      ? 'R:R —'
                      : 'R:R 1:${rr.rr!.toStringAsFixed(2)}',
                  color: VxColors.textSecondary,
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: VxText.caption(
                'No stop set — the trade has no planned exit if it moves '
                'against you.',
                color: VxColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPercentField({
    required TextEditingController controller,
    required String label,
    required double? level,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VxText.caption(label, color: color),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: VxTypography.body.copyWith(color: VxColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: VxColors.surface,
            suffixText: '%',
            suffixStyle:
                VxTypography.caption.copyWith(color: VxColors.neutral500),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        VxText.caption(
          level == null ? '—' : '\$${level.toStringAsFixed(2)}',
          color: VxColors.textTertiary,
        ),
      ],
    );
  }

  Widget _buildQuickSize(String label, double pct) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        final balance = context.read<ExecutionManager>().balance;
        // Leave room for the fee, so Max is actually affordable rather than
        // one fee short.
        final unitCost =
            _effectivePrice * (1 + ExecutionManager.takerFeeRate);
        final affordable = unitCost > 0 ? balance / unitCost : 0.0;
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
    final price = _effectivePrice;
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
            price: price,
            stopLossPrice: _stopLossPrice,
            takeProfitPrice: _takeProfitPrice,
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
          '${_isMarket ? (_isBuy ? 'Bought' : 'Sold') : 'Limit order placed:'} '
          '${qty.toStringAsFixed(4)} $base @ \$${price.toStringAsFixed(2)}',
        ),
      ));
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text("Order failed: $e")));
      }
    }
  }
}
