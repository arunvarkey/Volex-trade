import 'package:flutter/material.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import '../data/prediction_data.dart';
import '../models/prediction_models.dart';
import '../services/prediction_portfolio_service.dart';
import 'widgets/prediction_widgets.dart';
import 'package:volex_terminal/ui/widgets/glossary_sheet.dart';

/// Detail + simulated trading for a single event market.
class EventMarketDetailScreen extends StatefulWidget {
  final EventMarket market;
  const EventMarketDetailScreen({super.key, required this.market});

  @override
  State<EventMarketDetailScreen> createState() =>
      _EventMarketDetailScreenState();
}

class _EventMarketDetailScreenState extends State<EventMarketDetailScreen> {
  final PredictionPortfolioService _portfolio =
      PredictionPortfolioService.instance;

  ContractSide _side = ContractSide.yes;
  int _contracts = 10;

  @override
  void initState() {
    super.initState();
    _portfolio.ensureLoaded();
  }

  EventMarket get market => widget.market;

  int get _priceCents => market.priceFor(_side);
  double get _cost => _contracts * _priceCents / 100.0;
  double get _payout => _contracts * 1.0; // each contract pays $1 if it wins
  double get _profitIfWin => _payout - _cost;

  List<MentionBuzz> get _relatedMentions =>
      PredictionData.buzz.where((b) => b.marketId == market.id).toList();

  Future<void> _placeTrade() async {
    final result = await _portfolio.buy(market, _side, _contracts);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.ok ? VxColors.surfaceBright : VxColors.neonRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _closePosition(ContractSide side) async {
    final result = await _portfolio.close(market, side);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: VxColors.surfaceBright,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setContracts(int v) {
    setState(() => _contracts = v.clamp(1, 1000));
  }

  @override
  Widget build(BuildContext context) {
    final cat = categoryColor(market.category);
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${market.category.emoji} ${market.category.label.toUpperCase()}',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: cat,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _portfolio,
        builder: (context, _) {
          final yesPos = _portfolio.positionFor(market.id, ContractSide.yes);
          final noPos = _portfolio.positionFor(market.id, ContractSide.no);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              Text(market.question,
                  style: VxTypography.h2.copyWith(fontSize: 22, height: 1.3)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Vol \$${_compactMoney(market.volume)}',
                      style: VxTypography.caption.copyWith(fontSize: 11)),
                  const SizedBox(width: 12),
                  Text('Closes ${market.closesLabel}',
                      style: VxTypography.caption.copyWith(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VxColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ProbabilityBar(yesPrice: market.yesPrice),
              ),
              const SizedBox(height: 18),
              Text(market.context,
                  style: VxTypography.body
                      .copyWith(fontSize: 14.5, height: 1.5)),
              const SizedBox(height: 24),

              if (yesPos != null || noPos != null) ...[
                _sectionLabel('YOUR POSITION'),
                const SizedBox(height: 8),
                if (yesPos != null)
                  _PositionTile(
                    position: yesPos,
                    market: market,
                    onClose: () => _closePosition(ContractSide.yes),
                  ),
                if (noPos != null)
                  _PositionTile(
                    position: noPos,
                    market: market,
                    onClose: () => _closePosition(ContractSide.no),
                  ),
                const SizedBox(height: 22),
              ],

              _sectionLabel('PLACE A TRADE'),
              const SizedBox(height: 10),
              _buildTradePanel(),

              if (_relatedMentions.isNotEmpty) ...[
                const SizedBox(height: 26),
                _sectionLabel('WHAT PEOPLE ARE SAYING'),
                const SizedBox(height: 10),
                for (final m in _relatedMentions) ...[
                  _MentionTile(buzz: m),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTradePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Side toggle
          Row(
            children: [
              Expanded(
                child: _sideButton(
                  label: 'YES',
                  price: market.yesPrice,
                  color: VxColors.neonGreen,
                  selected: _side == ContractSide.yes,
                  onTap: () => setState(() => _side = ContractSide.yes),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _sideButton(
                  label: 'NO',
                  price: market.noPrice,
                  color: VxColors.neonRed,
                  selected: _side == ContractSide.no,
                  onTap: () => setState(() => _side = ContractSide.no),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contracts stepper
          Row(
            children: [
              InfoLabel(
                text: 'Contracts',
                termId: 'contract',
                style: VxTypography.bodySmall.copyWith(fontSize: 13),
              ),
              const Spacer(),
              _stepBtn(Icons.remove, () => _setContracts(_contracts - 1)),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text('$_contracts',
                    style: VxTypography.price.copyWith(fontSize: 18)),
              ),
              _stepBtn(Icons.add, () => _setContracts(_contracts + 1)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final preset in const [10, 25, 50, 100]) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setContracts(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _contracts == preset
                            ? VxColors.primary.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _contracts == preset
                              ? VxColors.primary
                              : Colors.white.withValues(alpha: 0.08),
                          width: _contracts == preset ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text('$preset',
                            style: VxTypography.caption.copyWith(
                              fontSize: 12,
                              color: _contracts == preset
                                  ? VxColors.primary
                                  : Colors.white70,
                              fontWeight: _contracts == preset
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          _summaryRow('Cost', '\$${_cost.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _summaryRow('Payout if correct', '\$${_payout.toStringAsFixed(2)}',
              color: VxColors.neonGreen),
          const SizedBox(height: 4),
          Text(
            '$_contracts contracts × \$1 each. You lose the '
            '\$${_cost.toStringAsFixed(2)} if the answer goes the other way.',
            style: VxTypography.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 6),
          _summaryRow('Profit if correct',
              '+\$${_profitIfWin.toStringAsFixed(2)}',
              color: VxColors.neonGreen),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeTrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: _side == ContractSide.yes
                    ? VxColors.neonGreen
                    : VxColors.neonRed,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'BUY ${_side.name.toUpperCase()}  •  \$${_cost.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideButton({
    required String label,
    required int price,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: VxTypography.body.copyWith(
                    fontWeight: FontWeight.w900,
                    color: selected ? color : Colors.white70)),
            const SizedBox(height: 2),
            Text('$price¢',
                style: VxTypography.caption
                    .copyWith(fontSize: 12, color: color)),
            // A winning contract pays exactly $1, so the price in cents is
            // the market's own estimate of the odds. Showing the price alone
            // hides the most useful thing on the screen: whether you think
            // the crowd has the probability wrong.
            Text('≈$price% likely',
                style: VxTypography.caption.copyWith(
                    fontSize: 9,
                    color: (selected ? color : Colors.white70)
                        .withValues(alpha: 0.75))),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: VxTypography.bodySmall.copyWith(fontSize: 13)),
        Text(value,
            style: VxTypography.price
                .copyWith(fontSize: 14, color: color ?? Colors.white)),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: VxTypography.caption.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        fontSize: 11,
        color: Colors.white70,
      ),
    );
  }

  static String _compactMoney(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}

class _PositionTile extends StatelessWidget {
  final PredictionPosition position;
  final EventMarket market;
  final VoidCallback onClose;
  const _PositionTile({
    required this.position,
    required this.market,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final pnl = position.pnl(market);
    final bool up = pnl >= 0;
    final sideColor = position.side == ContractSide.yes
        ? VxColors.neonGreen
        : VxColors.neonRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VxColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sideColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${position.contracts} × ${position.side.name.toUpperCase()} @ ${position.avgPriceCents}¢',
                style: VxTypography.body
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Value \$${position.currentValue(market).toStringAsFixed(2)}  •  '
                '${up ? '+' : '-'}\$${pnl.abs().toStringAsFixed(2)}',
                style: VxTypography.caption.copyWith(
                    fontSize: 11,
                    color: up ? VxColors.neonGreen : VxColors.neonRed),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(foregroundColor: VxColors.neonCyan),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}

class _MentionTile extends StatelessWidget {
  final MentionBuzz buzz;
  const _MentionTile({required this.buzz});

  @override
  Widget build(BuildContext context) {
    final color = buzz.bullish ? VxColors.neonGreen : VxColors.neonRed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VxColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(buzz.avatarEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(buzz.author,
                        style: VxTypography.bodySmall.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(width: 6),
                    Icon(
                      buzz.bullish
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('"${buzz.quote}"',
                    style: VxTypography.bodySmall
                        .copyWith(fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
