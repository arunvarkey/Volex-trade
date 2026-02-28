// lib/engine/backtest/models/backtest_metrics.dart
import 'package:equatable/equatable.dart';

class BacktestMetrics extends Equatable {
  final double totalReturnPercent;
  final double maxDrawdownPercent;
  final double sharpeRatio;
  final double winRate;
  final double profitFactor;
  final double avgWinPercent;
  final double avgLossPercent;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final Duration avgTradeDuration;
  final String grade;

  const BacktestMetrics({
    required this.totalReturnPercent,
    required this.maxDrawdownPercent,
    required this.sharpeRatio,
    required this.winRate,
    required this.profitFactor,
    required this.avgWinPercent,
    required this.avgLossPercent,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.avgTradeDuration,
    required this.grade,
  });

  @override
  List<Object?> get props => [
        totalReturnPercent,
        maxDrawdownPercent,
        sharpeRatio,
        winRate,
        profitFactor,
        avgWinPercent,
        avgLossPercent,
        totalTrades,
        winningTrades,
        losingTrades,
        avgTradeDuration,
        grade,
      ];

  bool get isGoodWinRate => winRate > 50;
  bool get isGoodProfitFactor => profitFactor > 1.5;
  bool get isGoodSharpe => sharpeRatio > 1.5;
}
