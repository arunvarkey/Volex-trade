import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/guidance_banner.dart';

import '../data/prediction_data.dart';
import '../models/prediction_models.dart';
import '../services/prediction_portfolio_service.dart';
import 'widgets/prediction_widgets.dart';

/// The "Buzz & Predictions" hub — Kalshi-style event markets driven by a
/// mentions/buzz feed, all traded with virtual money.
class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final PredictionPortfolioService _portfolio =
      PredictionPortfolioService.instance;
  MarketCategory? _filter;

  @override
  void initState() {
    super.initState();
    _portfolio.ensureLoaded();
  }

  List<EventMarket> get _visibleMarkets {
    if (_filter == null) return PredictionData.markets;
    return PredictionData.markets
        .where((m) => m.category == _filter)
        .toList();
  }

  void _openMarket(EventMarket market) {
    context.push('/predictions/market', extra: market);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'BUZZ & PREDICTIONS',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            color: Colors.white,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _portfolio,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              const GuidanceBanner(
                id: 'predict_intro',
                text:
                    'Predict real-world events with virtual money. Pick Yes or No, '
                    'set how many contracts, and see your payout if you\'re right.',
              ),
              _BalanceHeader(portfolio: _portfolio),
              const SizedBox(height: 22),
              const _SectionLabel(icon: Icons.local_fire_department_rounded,
                  text: 'TRENDING MENTIONS', accent: VxColors.neonYellow),
              const SizedBox(height: 10),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PredictionData.buzz.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final buzz = PredictionData.buzz[i];
                    return BuzzCard(
                      buzz: buzz,
                      onTap: () {
                        final id = buzz.marketId;
                        if (id == null) return;
                        final market = PredictionData.marketById(id);
                        if (market != null) _openMarket(market);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              const _SectionLabel(icon: Icons.insights_rounded,
                  text: 'EVENT MARKETS', accent: VxColors.neonCyan),
              const SizedBox(height: 10),
              _CategoryFilter(
                selected: _filter,
                onChanged: (c) => setState(() => _filter = c),
              ),
              const SizedBox(height: 12),
              for (final market in _visibleMarkets) ...[
                MarketRow(
                  market: market,
                  onTap: () => _openMarket(market),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              Text(
                'Simulated event markets for risk-free practice. Outcomes are '
                'hypothetical and this is not financial advice or a real market.',
                textAlign: TextAlign.center,
                style: VxTypography.caption.copyWith(fontSize: 10.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final PredictionPortfolioService portfolio;
  const _BalanceHeader({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final pnl = portfolio.totalPnl;
    final bool up = pnl >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VxColors.surfaceBright, VxColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Virtual Balance',
                    style: VxTypography.caption.copyWith(fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  '\$${portfolio.balance.toStringAsFixed(2)}',
                  style: VxTypography.h2.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  'Net worth \$${portfolio.netWorth.toStringAsFixed(2)}',
                  style: VxTypography.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (up ? VxColors.neonGreen : VxColors.neonRed)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('OPEN P/L',
                    style: VxTypography.caption.copyWith(fontSize: 9)),
                const SizedBox(height: 2),
                Text(
                  '${up ? '+' : '-'}\$${pnl.abs().toStringAsFixed(2)}',
                  style: VxTypography.price.copyWith(
                    color: up ? VxColors.neonGreen : VxColors.neonRed,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;
  const _SectionLabel(
      {required this.icon, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 6),
        Text(
          text,
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final MarketCategory? selected;
  final ValueChanged<MarketCategory?> onChanged;
  const _CategoryFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _chip(context, label: 'All', active: selected == null,
          onTap: () => onChanged(null)),
    ];
    for (final c in MarketCategory.values) {
      chips.add(const SizedBox(width: 8));
      chips.add(_chip(
        context,
        label: '${c.emoji} ${c.label}',
        active: selected == c,
        onTap: () => onChanged(c),
      ));
    }
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips,
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String label,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? VxColors.neonCyan.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? VxColors.neonCyan.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: VxTypography.bodySmall.copyWith(
              fontSize: 12,
              color: active ? VxColors.neonCyan : Colors.white60,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
