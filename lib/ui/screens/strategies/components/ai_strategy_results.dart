import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/widgets/glossary_sheet.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';

class AIStrategyResults extends StatelessWidget {
  final GeneratedStrategy strategy;
  final BacktestResult? backtestResult;
  final VoidCallback onRunBacktest;
  final VoidCallback onDeploy;
  final bool isBacktesting;
  final VoidCallback? onReset;

  const AIStrategyResults({
    super.key,
    required this.strategy,
    required this.onRunBacktest,
    required this.onDeploy,
    this.backtestResult,
    this.isBacktesting = false,
    this.onReset,
  });

  // ... (build methods)

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuccessHeader(),
          const SizedBox(height: 24),
          _buildStrategyInfo(),
          const SizedBox(height: 32),
          _buildConditionsSection(
            'ENTRY CONDITIONS',
            strategy.entryConditions,
            VxColors.neonGreen,
          ),
          const SizedBox(height: 24),
          _buildConditionsSection(
            'EXIT CONDITIONS',
            strategy.exitConditions,
            VxColors.neonRed,
          ),
          const SizedBox(height: 24),
          if (backtestResult != null) ...[
            _buildBacktestResults(backtestResult!),
            const SizedBox(height: 32),
          ] else ...[
            _buildBacktestPlaceholder(),
            const SizedBox(height: 32),
          ],
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VxColors.neonGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VxColors.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: VxColors.neonGreen, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Strategy Generated!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: VxColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: VxColors.warning),
                      ),
                      child: Text(
                        'CONFIDENCE ${(strategy.confidenceScore * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: VxColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Review and backtest before deploying.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strategy.name,
          style: const TextStyle(
            color: VxColors.neonCyan,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strategy.description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: VxColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10)),
          child: Text(
            strategy.educationalExplanation,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontStyle: FontStyle.italic),
          ),
        )
      ],
    );
  }

  static const Map<String, String> _indicatorTerms = {
    'RSI': 'rsi',
    'MACD': 'macd',
    'SMA': 'sma',
    'EMA': 'ema',
    'BOLLINGER_BANDS': 'bollinger_bands',
    'VOLUME': 'volume',
  };

  Widget _buildConditionsSection(
    String title,
    List<StrategyCondition> conditions,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (conditions.isEmpty)
          const Text('None',
              style: TextStyle(color: Colors.white30, fontSize: 14)),
        ...conditions.map((condition) {
          final rest =
              ' ${condition.comparator} ${condition.value}${condition.params.isNotEmpty ? ' (${condition.params})' : ''}';
          final termId = _indicatorTerms[condition.indicator.toUpperCase()];
          const valueStyle = TextStyle(color: Colors.white, fontSize: 14);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                if (termId != null)
                  InfoLabel(
                    text: condition.indicator,
                    termId: termId,
                    style: valueStyle.copyWith(fontWeight: FontWeight.w600),
                  )
                else
                  Text(condition.indicator, style: valueStyle),
                Expanded(child: Text(rest, style: valueStyle)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBacktestPlaceholder() {
    return Center(
      child: isBacktesting
          ? const CircularProgressIndicator(color: VxColors.neonCyan)
          : OutlinedButton.icon(
              icon: const Icon(Icons.play_arrow, color: VxColors.neonCyan),
              label: const Text('RUN BACKTEST (BTC-USD 1H)'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: VxColors.neonCyan,
                  side: const BorderSide(color: VxColors.neonCyan)),
              onPressed: onRunBacktest,
            ),
    );
  }

  Widget _buildBacktestResults(BacktestResult results) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: VxColors.neonCyan, size: 24),
              SizedBox(width: 12),
              Text(
                'BACKTEST RESULTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Win Rate',
                  '${((results.metrics.winningTrades / (results.metrics.totalTrades == 0 ? 1 : results.metrics.totalTrades)) * 100).toStringAsFixed(1)}%',
                  VxColors.neonGreen,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Total Return',
                  '${results.totalReturnPercent >= 0 ? '+' : ''}${results.totalReturnPercent.toStringAsFixed(1)}%',
                  results.totalReturnPercent >= 0
                      ? VxColors.positive
                      : VxColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Max Drawdown',
                  '-${results.metrics.maxDrawdownPercent.toStringAsFixed(1)}%',
                  VxColors.neonRed,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Profit Factor',
                  results.metrics.profitFactor.toStringAsFixed(2),
                  VxColors.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total Trades: ${results.metrics.totalTrades}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    const terms = {
      'Win Rate': 'win_rate',
      'Total Return': 'total_return',
      'Max Drawdown': 'max_drawdown',
      'Profit Factor': 'profit_factor',
    };
    const labelStyle = TextStyle(
      color: Colors.white54,
      fontSize: 10,
      letterSpacing: 1,
    );
    final id = terms[label];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        id != null
            ? InfoLabel(
                text: label.toUpperCase(), termId: id, style: labelStyle)
            : Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onDeploy,
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonCyan,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_add_outlined, size: 20),
                SizedBox(width: 8),
                Text('SAVE STRATEGY'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
