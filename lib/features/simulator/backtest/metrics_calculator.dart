// lib/engine/backtest/metrics_calculator.dart
import 'models/trade_marker.dart';
import 'models/backtest_metrics.dart';
import 'dart:math' as math;

class MetricsCalculator {
  static BacktestMetrics calculate({
    required List<TradeMarker> trades,
    required List<double> equityCurve,
    required double initialEquity,
  }) {
    if (trades.isEmpty || equityCurve.isEmpty) {
      return const BacktestMetrics(
        totalReturnPercent: 0,
        maxDrawdownPercent: 0,
        sharpeRatio: 0,
        winRate: 0,
        profitFactor: 0,
        avgWinPercent: 0,
        avgLossPercent: 0,
        totalTrades: 0,
        winningTrades: 0,
        losingTrades: 0,
        avgTradeDuration: Duration.zero,
        grade: 'F',
      );
    }

    final totalReturnPercent =
        ((equityCurve.last - initialEquity) / initialEquity) * 100;

    // Drawdown
    double maxDrawdown = 0;
    double peak = initialEquity;
    for (final equity in equityCurve) {
      if (equity > peak) peak = equity;
      final drawdown = ((peak - equity) / peak) * 100;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }

    // Trade stats
    final closedTrades = trades
        .where((t) =>
            t.type == TradeType.exit ||
            t.type == TradeType.stopLoss ||
            t.type == TradeType.takeProfit)
        .toList();
    final wins = closedTrades.where((t) => (t.pnlPercent ?? 0) > 0).toList();
    final losses = closedTrades.where((t) => (t.pnlPercent ?? 0) <= 0).toList();

    final winRate =
        closedTrades.isEmpty ? 0.0 : (wins.length / closedTrades.length) * 100;

    double grossProfit = wins.fold(0.0, (sum, t) => sum + (t.pnl ?? 0));
    double grossLoss = losses.fold(0.0, (sum, t) => sum + (t.pnl ?? 0).abs());
    final profitFactor = grossLoss == 0
        ? (grossProfit > 0 ? 99.0 : 0.0)
        : grossProfit / grossLoss;

    final avgWin = wins.isEmpty
        ? 0.0
        : wins.fold(0.0, (sum, t) => sum + (t.pnlPercent ?? 0)) / wins.length;
    final avgLoss = losses.isEmpty
        ? 0.0
        : losses.fold(0.0, (sum, t) => sum + (t.pnlPercent ?? 0)) /
            losses.length;

    // Sharpe Ratio (Simplified periodic return approach)
    // In a real implementation, we'd use daily/hourly returns.
    // This is a placeholder for the consolidated engine.
    double sharpe = 0;
    if (equityCurve.length > 1) {
      final returns = <double>[];
      for (int i = 1; i < equityCurve.length; i++) {
        returns.add((equityCurve[i] - equityCurve[i - 1]) / equityCurve[i - 1]);
      }
      final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
      final variance = returns.fold(0.0, (a, b) => a + math.pow(b - mean, 2)) /
          returns.length;
      final stdDev = math.sqrt(variance);
      sharpe = stdDev == 0
          ? 0
          : (mean / stdDev) * math.sqrt(252); // Annualized (assuming daily)
    }

    // Duration
    Duration totalDuration = Duration.zero;
    int pairCount = 0;

    for (int i = 0; i < trades.length - 1; i++) {
      if (trades[i].type == TradeType.entry) {
        for (int j = i + 1; j < trades.length; j++) {
          if (trades[j].type != TradeType.entry) {
            totalDuration +=
                trades[j].timestamp.difference(trades[i].timestamp);
            pairCount++;
            break;
          }
        }
      }
    }

    final avgDuration = pairCount == 0
        ? Duration.zero
        : Duration(milliseconds: totalDuration.inMilliseconds ~/ pairCount);

    final grade = _calculateGrade(totalReturnPercent, maxDrawdown, winRate);

    return BacktestMetrics(
      totalReturnPercent: totalReturnPercent,
      maxDrawdownPercent: maxDrawdown,
      sharpeRatio: sharpe,
      winRate: winRate,
      profitFactor: profitFactor,
      avgWinPercent: avgWin,
      avgLossPercent: avgLoss,
      totalTrades: closedTrades.length,
      winningTrades: wins.length,
      losingTrades: losses.length,
      avgTradeDuration: avgDuration,
      grade: grade,
    );
  }

  static String _calculateGrade(double ret, double dd, double wr) {
    if (ret > 20 && dd < 10 && wr > 60) return 'A';
    if (ret > 10 && dd < 15 && wr > 50) return 'B';
    if (ret > 0 && dd < 25) return 'C';
    if (ret > -10) return 'D';
    return 'F';
  }
}
