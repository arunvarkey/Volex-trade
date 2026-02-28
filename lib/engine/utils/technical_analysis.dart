import 'dart:math' as math;
import '../../domain/candle_model.dart';

class TechnicalAnalysis {
  static double calculateSMA(List<Candle> candles, int period) {
    if (candles.length < period) return 0.0;
    final sum = candles
        .sublist(candles.length - period)
        .map((c) => c.close)
        .reduce((a, b) => a + b);
    return sum / period;
  }

  static double calculateEMA(List<Candle> candles, int period) {
    if (candles.length < period) return 0.0;

    final k = 2 / (period + 1);
    double ema = calculateSMA(candles.sublist(0, period), period);

    for (var i = period; i < candles.length; i++) {
      ema = (candles[i].close * k) + (ema * (1 - k));
    }

    return ema;
  }

  static double calculateStandardDeviation(List<Candle> candles, int period) {
    if (candles.length < period) return 0.0;
    final sma = calculateSMA(candles, period);

    // We need the data points corresponding to that SMA
    final data = candles.take(period).map((c) => c.close);

    final variance =
        data.map((val) => math.pow(val - sma, 2)).reduce((a, b) => a + b) /
            period;
    return math.sqrt(variance);
  }

  static ({double upper, double lower, double middle}) calculateBollingerBands(
      List<Candle> candles, int period, double stdDevMultiplier) {
    final middle = calculateSMA(candles, period);
    final stdDev = calculateStandardDeviation(candles, period);
    return (
      middle: middle,
      upper: middle + (stdDev * stdDevMultiplier),
      lower: middle - (stdDev * stdDevMultiplier)
    );
  }

  static double calculateRSI(List<Candle> candles, int period) {
    if (candles.length < period + 1) return 50.0;

    // Simple RSI implementation (usually requires smoothing, we'll do simple avg for MVP)
    // Actually standard RSI uses Wilder's Smoothing.
    // For MVP we'll use simple average of gains/losses

    double gainSum = 0.0;
    double lossSum = 0.0;

    // Note: candles usually come Newest First in some systems, or Oldest First?
    // In Volex Backtester, we usually pass the full history up to that point.
    // Assuming 'candles' is Chronological (Index 0 is Oldest, Index N is Newest).
    // We need the last N periods.

    // Wait, typical structure passed to SMA is often just the window.
    // Let's assume input is Chronological [Old -> New]
    // We take the LAST 'period' changes.

    if (candles.length < period + 1) return 50.0;

    final subset = candles.sublist(candles.length - period - 1);

    for (int i = 1; i < subset.length; i++) {
      final change = subset[i].close - subset[i - 1].close;
      if (change > 0) {
        gainSum += change;
      } else {
        lossSum += change.abs();
      }
    }

    final avgGain = gainSum / period;
    final avgLoss = lossSum / period;

    if (avgLoss == 0) return 100.0;

    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }
}
