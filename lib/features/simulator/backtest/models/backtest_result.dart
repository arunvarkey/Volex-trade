// lib/engine/backtest/models/backtest_result.dart
import 'package:volex_terminal/domain/candle_model.dart';
import 'trade_marker.dart';
import 'backtest_metrics.dart';

class BacktestResult {
  final List<Candle> candles;
  final List<TradeMarker> trades;
  final List<double> equityCurve;
  final BacktestMetrics metrics;
  final double initialEquity;
  final double finalEquity;
  final String? error;
  final dynamic strategy; // context

  BacktestResult({
    required this.candles,
    required this.trades,
    required this.equityCurve,
    required this.metrics,
    required this.initialEquity,
    required this.finalEquity,
    this.error,
    this.strategy,
  });

  factory BacktestResult.error(String message) {
    return BacktestResult(
      candles: [],
      trades: [],
      equityCurve: [],
      metrics: const BacktestMetrics(
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
      ),
      initialEquity: 0,
      finalEquity: 0,
      error: message,
    );
  }

  bool get isSuccess => error == null;
  bool get isProfitable => finalEquity > initialEquity;
  double get totalPnl => finalEquity - initialEquity;
  double get totalReturnPercent => initialEquity == 0
      ? 0
      : ((finalEquity - initialEquity) / initialEquity) * 100;
}
