// lib/features/simulator/backtesting/screens/backtest_results_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import '../../../../core/glossary.dart';
import '../../../../ui/design_system/vx_colors.dart';
import '../../../../ui/widgets/guidance_banner.dart';
import '../../../../ui/widgets/glossary_sheet.dart';
import '../models/backtest_result.dart';
import '../models/trade_marker.dart';

class BacktestResultsScreen extends StatelessWidget {
  final BacktestResult result;

  const BacktestResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Backtest Results',
          style: TextStyle(
            color: VxColors.neonCyan,
            letterSpacing: 0.3,
            fontSize: 16,
          ),
        ),
        actions: [
          // Grade badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getGradeColor(result.metrics.grade).withValues(alpha: 0.2),
              border: Border.all(color: _getGradeColor(result.metrics.grade)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Grade ${result.metrics.grade}',
              style: TextStyle(
                color: _getGradeColor(result.metrics.grade),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GuidanceBanner(
              id: 'backtest_results_intro',
              text:
                  'A backtest replays real history to show how your strategy '
                  'would have done. Win rate and return are the headline numbers; '
                  'max drawdown is the worst dip along the way.',
            ),
            // Overall performance card
            _buildPerformanceCard(),

            const SizedBox(height: 24),

            // Equity curve
            _buildSectionHeader('Equity Curve'),
            const SizedBox(height: 12),
            _buildEquityCurveChart(),

            const SizedBox(height: 24),

            // Key metrics grid
            _buildSectionHeader('Key Metrics'),
            const SizedBox(height: 12),
            _buildMetricsGrid(),

            const SizedBox(height: 24),

            // Trade list
            _buildSectionHeader(
                'Trade History (${result.trades.length} trades)'),
            const SizedBox(height: 12),
            _buildTradeList(),

            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return VxColors.neonGreen;
      case 'B':
        return VxColors.neonCyan;
      case 'C':
        return VxColors.neonPurple;
      case 'D':
        return Colors.orange;
      case 'F':
        return VxColors.neonRed;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPerformanceCard() {
    final isProfit = result.isProfitable;
    final color = isProfit ? VxColors.neonGreen : VxColors.neonRed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                isProfit ? 'Profitable' : 'Unprofitable',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Total Return',
                '${result.totalReturnPercent.toStringAsFixed(2)}%',
                color,
              ),
              Container(width: 1, height: 40, color: Colors.grey[800]),
              _buildStatColumn(
                'Profit/Loss',
                '\$${result.totalPnl.toStringAsFixed(2)}',
                color,
              ),
              Container(width: 1, height: 40, color: Colors.grey[800]),
              _buildStatColumn(
                'Final Equity',
                '\$${result.finalEquity.toStringAsFixed(2)}',
                color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const Map<String, String> _labelTerms = {
    'Win Rate': 'win_rate',
    'Total Return': 'total_return',
    'Max Drawdown': 'max_drawdown',
    'Profit Factor': 'profit_factor',
    'P&L': 'pnl',
  };

  /// A metric label that becomes tappable (with a "?") when we have a plain
  /// English definition for it; otherwise plain text.
  Widget _termLabel(String label, TextStyle style) {
    final id = _labelTerms[label];
    if (id != null && Glossary.has(id)) {
      return InfoLabel(text: label, termId: id, style: style);
    }
    return Text(label, style: style);
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        _termLabel(
          label,
          TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: VxColors.neonCyan,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildEquityCurveChart() {
    if (result.equityCurve.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            Text("No equity data", style: TextStyle(color: Colors.grey[600])),
      );
    }

    final minY = result.equityCurve.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = result.equityCurve.reduce((a, b) => a > b ? a : b) * 1.05;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 5 == 0 ? 1 : (maxY - minY) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[800]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[800]!),
          ),
          minX: 0,
          maxX: result.equityCurve.length.toDouble() - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: result.equityCurve.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color:
                  result.isProfitable ? VxColors.neonGreen : VxColors.neonRed,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (result.isProfitable
                        ? VxColors.neonGreen
                        : VxColors.neonRed)
                    .withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildMetricRow(
              'Win Rate',
              '${result.metrics.winRate.toStringAsFixed(1)}%',
              result.metrics.isGoodWinRate),
          Divider(color: Colors.grey[800]),
          _buildMetricRow(
              'Profit Factor',
              result.metrics.profitFactor.toStringAsFixed(2),
              result.metrics.isGoodProfitFactor),
          Divider(color: Colors.grey[800]),
          _buildMetricRow(
              'Sharpe Ratio',
              result.metrics.sharpeRatio.toStringAsFixed(2),
              result.metrics.isGoodSharpe),
          Divider(color: Colors.grey[800]),
          _buildMetricRow(
              'Max Drawdown',
              '${result.metrics.maxDrawdownPercent.toStringAsFixed(2)}%',
              result.metrics.maxDrawdownPercent < 20),
          Divider(color: Colors.grey[800]),
          _buildMetricRow(
              'Total Trades', '${result.metrics.totalTrades}', true),
          Divider(color: Colors.grey[800]),
          _buildMetricRow('Avg Win',
              '+${result.metrics.avgWinPercent.toStringAsFixed(2)}%', true),
          Divider(color: Colors.grey[800]),
          _buildMetricRow('Avg Loss',
              '${result.metrics.avgLossPercent.toStringAsFixed(2)}%', true),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, bool isGood) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _termLabel(
          label,
          TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isGood ? Icons.check_circle : Icons.warning,
              color: isGood ? VxColors.neonGreen : Colors.orange,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTradeList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: result.trades.length > 10 ? 10 : result.trades.length,
        separatorBuilder: (_, __) =>
            Divider(color: Colors.grey[800], height: 1),
        itemBuilder: (context, index) {
          final trade = result.trades[index];
          return _buildTradeItem(trade);
        },
      ),
    );
  }

  Widget _buildTradeItem(TradeMarker trade) {
    final color = _getTradeColor(trade);
    final icon = _getTradeIcon(trade);

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTradeTypeLabel(trade.type),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _formatTimestamp(trade.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${trade.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (trade.pnl != null)
                Text(
                  '${trade.pnl! >= 0 ? '+' : ''}\$${trade.pnl!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        trade.pnl! >= 0 ? VxColors.neonGreen : VxColors.neonRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTradeColor(TradeMarker trade) {
    switch (trade.type) {
      case TradeType.entry:
        return VxColors.neonCyan;
      case TradeType.exit:
        return trade.pnl != null && trade.pnl! >= 0
            ? VxColors.neonGreen
            : VxColors.neonRed;
      case TradeType.stopLoss:
        return VxColors.neonRed;
      case TradeType.takeProfit:
        return VxColors.neonGreen;
    }
  }

  IconData _getTradeIcon(TradeMarker trade) {
    switch (trade.type) {
      case TradeType.entry:
        return Icons.login;
      case TradeType.exit:
        return Icons.logout;
      case TradeType.stopLoss:
        return Icons.block;
      case TradeType.takeProfit:
        return Icons.check_circle;
    }
  }

  String _getTradeTypeLabel(TradeType type) {
    switch (type) {
      case TradeType.entry:
        return 'ENTRY';
      case TradeType.exit:
        return 'EXIT';
      case TradeType.stopLoss:
        return 'STOP LOSS';
      case TradeType.takeProfit:
        return 'TAKE PROFIT';
    }
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Star Paper Trading (Manual)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.go('/');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Go to Terminal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Deploy Strategy
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _deployStrategy(context),
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Deploy Strategy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonCyan,
              foregroundColor: VxColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Modify strategy
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.edit),
            label: const Text('Modify Strategy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: VxColors.neonCyan,
              side: const BorderSide(color: VxColors.neonCyan),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Share results
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showComingSoon(context, 'Share results'),
            icon: const Icon(Icons.share),
            label: const Text('Share Results'),
            style: OutlinedButton.styleFrom(
              foregroundColor: VxColors.neonCyan,
              side: const BorderSide(color: VxColors.neonCyan),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _deployStrategy(BuildContext context) async {
    final strategy = result.strategy;
    if (strategy == null) {
      _showError(context, "Cannot deploy: Strategy context missing.");
      return;
    }

    try {
      final executionManager = context.read<ExecutionManager>();
      // Check if strategy ID exists or if we need to register it
      if (strategy.id != null) {
        await executionManager.startStrategy(strategy.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Strategy Deployed!"),
            backgroundColor: VxColors.neonGreen,
          ));
          context.go('/lab'); // Return to Lab to see it running
        }
      } else {
        if (context.mounted) {
          _showError(context, "Strategy ID missing.");
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Deployment failed: $e");
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: VxColors.neonRed,
    ));
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        title: const Text(
          'COMING SOON',
          style: TextStyle(color: VxColors.neonCyan, letterSpacing: 1.5),
        ),
        content: Text(
          '$feature will be available in the next update!',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }
}
