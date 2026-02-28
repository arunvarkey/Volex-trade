// lib/engine/backtest/indicator_library.dart
import 'package:volex_terminal/domain/candle_model.dart';
import 'dart:math' as math;

class IndicatorLibrary {
  // SMA (Simple Moving Average)
  static double calculateSMA(List<Candle> candles, int period,
      {int atIndex = -1}) {
    if (atIndex == -1) atIndex = candles.length - 1;
    if (atIndex < period - 1) return candles[atIndex].close;

    double sum = 0;
    for (int i = atIndex - period + 1; i <= atIndex; i++) {
      sum += candles[i].close;
    }
    return sum / period;
  }

  // EMA (Exponential Moving Average)
  static double calculateEMA(List<Candle> candles, int period,
      {int atIndex = -1}) {
    if (atIndex == -1) atIndex = candles.length - 1;
    if (atIndex < period - 1) return candles[atIndex].close;

    final multiplier = 2.0 / (period + 1);

    // For backtesting, we ideally want an efficient way to get EMA at any index.
    // Sequential calculation is best.
    double ema = calculateSMA(candles, period, atIndex: period - 1);
    for (int i = period; i <= atIndex; i++) {
      ema = (candles[i].close - ema) * multiplier + ema;
    }
    return ema;
  }

  // RSI (Relative Strength Index)
  static double calculateRSI(List<Candle> candles, int period,
      {int atIndex = -1}) {
    if (atIndex == -1) atIndex = candles.length - 1;
    if (atIndex < period) return 50.0;

    double gains = 0;
    double losses = 0;

    for (int i = atIndex - period + 1; i <= atIndex; i++) {
      final change = candles[i].close - candles[i - 1].close;
      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }

    final avgGain = gains / period;
    final avgLoss = losses / period;

    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  // Bollinger Bands
  static BollingerBands calculateBollingerBands(
    List<Candle> candles,
    int period,
    double stdDevMultiplier, {
    int atIndex = -1,
  }) {
    if (atIndex == -1) atIndex = candles.length - 1;
    if (atIndex < period - 1) {
      final price = candles[atIndex].close;
      return BollingerBands(middle: price, upper: price, lower: price);
    }

    final sma = calculateSMA(candles, period, atIndex: atIndex);

    double sumSquaredDiffs = 0;
    for (int i = atIndex - period + 1; i <= atIndex; i++) {
      final diff = candles[i].close - sma;
      sumSquaredDiffs += diff * diff;
    }

    final stdDev = math.sqrt(sumSquaredDiffs / period);

    return BollingerBands(
      middle: sma,
      upper: sma + (stdDev * stdDevMultiplier),
      lower: sma - (stdDev * stdDevMultiplier),
    );
  }

  // MACD (Moving Average Convergence Divergence)
  static MACD calculateMACD(
    List<Candle> candles, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
    int atIndex = -1,
  }) {
    if (atIndex == -1) atIndex = candles.length - 1;

    final fastEMA = calculateEMA(candles, fastPeriod, atIndex: atIndex);
    final slowEMA = calculateEMA(candles, slowPeriod, atIndex: atIndex);
    final macdLine = fastEMA - slowEMA;

    // Signal line is EMA of MACD line.
    // For now, returning simplified version to avoid complexity of stateful calculation in static context.
    // Future improvement: Implement lookback for signal line.

    return MACD(
      macdLine: macdLine,
      signalLine: 0,
      histogram: macdLine,
    );
  }
}

class BollingerBands {
  final double upper;
  final double middle;
  final double lower;

  const BollingerBands({
    required this.upper,
    required this.middle,
    required this.lower,
  });
}

class MACD {
  final double macdLine;
  final double signalLine;
  final double histogram;

  const MACD({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}
