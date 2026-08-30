import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_typography.dart';
import '../../widgets/vx_holographic_card.dart';
import '../../widgets/feature_intro.dart';
import '../strategies/strategy_detail_view.dart';

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<StrategyEngine>();
    final backtestEngine = context.watch<BacktestEngine>();
    final execution = context.watch<ExecutionManager>();
    final strategies = engine.allStrategies;
    final activeIds = execution.activeStrategyIds;

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Strategy Lab',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FeatureIntro(
              featureId: 'lab',
              icon: Icons.science_outlined,
              what: 'A strategy is a set of rules that decides when to buy and '
                  'sell for you. This screen is where you run one against past '
                  'prices to see how it would have done, and switch it on to '
                  'trade your virtual balance automatically.',
              when: 'Use it when you have a rule you want to check before '
                  'trusting it — for example "buy when the 20-period average '
                  'crosses above the 50-period one".',
              caution: 'A strategy doing well on past prices is evidence, not '
                  'proof. Markets change, and the period you tested is only '
                  'one of the many the strategy will meet.',
            ),
            _buildLabHeader(context),
            const SizedBox(height: 20),

            // Running Strategies
            if (activeIds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Running Strategies',
                  style: VxTypography.caption
                      .copyWith(color: VxColors.neonGreen, fontSize: 10),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: strategies
                      .where((s) => activeIds.contains(s.id))
                      .map((s) => _buildActiveStrategyCard(s, execution))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Your Strategies
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your Strategies',
                style: VxTypography.caption
                    .copyWith(color: Colors.white24, fontSize: 10),
              ),
            ),
            const SizedBox(height: 10),
            strategies.isEmpty
                ? _buildShimmerLibrary()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: strategies.length,
                    itemBuilder: (context, index) {
                      final strategy = strategies[index];
                      return _StrategyCard(
                        strategy: strategy,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => StrategyDetailView(
                                      strategyId: strategy.id,
                                      isBackEnabled: true // Push onto stack
                                      )));
                        },
                      );
                    },
                  ),

            // Recent Backtests (Placeholder for now)
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recent Backtests',
                style: VxTypography.caption
                    .copyWith(color: Colors.white24, fontSize: 10),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            backtestEngine.history.isEmpty
                ? _buildEmptyBacktestHistory()
                : _buildBacktestHistoryList(context, backtestEngine.history),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabHeader(BuildContext context) {
    return VxHolographicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, size: 40, color: VxColors.neonCyan),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategy Lab',
                      style: VxTypography.h2.copyWith(letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Test strategies against real market history.',
                      style: VxTypography.body
                          .copyWith(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _LabActionButton(
                label: "Create with AI",
                icon: Icons.auto_awesome,
                onTap: () {
                  // Navigate to AI Strategy Generator
                  context.push('/ai-strategy');
                },
              ),
              const SizedBox(width: 12),
              _LabActionButton(
                label: "New Backtest",
                icon: Icons.history, // Changed from sync
                color: VxColors.neonCyan,
                onTap: () {
                  // Navigate to Backtest Config
                  context.push('/lab/backtest/config');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildShimmerLibrary() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBacktestHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off, color: Colors.white24, size: 32),
          const SizedBox(height: 12),
          Text(
            "No backtests run recently",
            style: VxTypography.body.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildBacktestHistoryList(
      BuildContext context, List<dynamic> history) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: history.length > 5 ? 5 : history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = history[index];
        final strategyName = result.strategy?.name ?? "Unknown Strategy";
        final pnl = result.totalPnl;
        final isProfit = result.isProfitable;

        return InkWell(
          onTap: () {
            context.push('/lab/backtest/results', extra: result);
          },
          child: VxHolographicCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            child: Row(
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? VxColors.neonGreen : VxColors.neonRed,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strategyName,
                        style: VxTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Return: ${result.totalReturnPercent.toStringAsFixed(2)}%",
                        style: VxTypography.caption.copyWith(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "\$${pnl.toStringAsFixed(2)}",
                  style: VxTypography.price.copyWith(
                    color: isProfit ? VxColors.neonGreen : VxColors.neonRed,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: Colors.white24, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildActiveStrategyCard(Strategy strategy, ExecutionManager execution) {
  // Real P&L for this strategy's positions. This card used to print a
  // hardcoded "+0.00%" in green regardless of what the strategy had actually
  // done, with a comment noting the real value "would" be wired up.
  double pnl = 0;
  for (final p in execution.positions) {
    if (p.strategyId != strategy.id) continue;
    pnl += p.isOpen ? (p.unrealizedPnl ?? 0) : (p.realizedPnL ?? 0);
  }
  final hasPositions =
      execution.positions.any((p) => p.strategyId == strategy.id);
  final up = pnl >= 0;

  return VxHolographicCard(
    width: 160,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(12),
    borderRadius: 12,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sensors, color: VxColors.neonGreen, size: 12),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                strategy.name.toUpperCase(),
                style: VxTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'P&L',
          style: VxTypography.caption
              .copyWith(fontSize: 10, color: Colors.white24),
        ),
        Text(
          hasPositions
              ? '${up ? '+' : ''}\$${pnl.toStringAsFixed(2)}'
              : '—',
          style: VxTypography.price.copyWith(
            color: !hasPositions
                ? Colors.white38
                : (up ? VxColors.neonGreen : VxColors.neonRed),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _StrategyCard extends StatelessWidget {
  final Strategy strategy;
  final VoidCallback onTap;

  const _StrategyCard({required this.strategy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (strategy.validationStatus) {
      case ValidationStatus.verified:
        statusColor = VxColors.neonGreen;
        statusText = "VERIFIED";
        break;
      case ValidationStatus.failed:
        statusColor = VxColors.neonRed;
        statusText = "FAILED";
        break;
      default:
        statusColor = VxColors.neonCyan;
        statusText = "EXPERIMENTAL";
    }

    return GestureDetector(
      onTap: onTap,
      child: VxHolographicCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        child: Row(
          children: [
            Container(
              width: 2,
              height: 32,
              decoration: BoxDecoration(
                color: statusColor,
                boxShadow: [
                  BoxShadow(color: statusColor, blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy.name,
                    style:
                        VxTypography.body.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strategy.id.toUpperCase(),
                    style: VxTypography.caption
                        .copyWith(color: Colors.white24, fontSize: 8),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                statusText,
                style: VxTypography.caption.copyWith(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }
}

class _LabActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _LabActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = VxColors.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(
                label,
                style: VxTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
