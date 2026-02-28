import 'dart:math' as math;
import 'package:volex_terminal/domain/candle_model.dart';

/// Extended technical indicator calculations
class TechnicalIndicators {
  /// Simple Moving Average
  static List<double?> sma(List<Candle> candles, int period) {
    final result = List<double?>.filled(candles.length, null);

    for (int i = period - 1; i < candles.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j].close;
      }
      result[i] = sum / period;
    }

    return result;
  }

  /// Exponential Moving Average
  static List<double?> ema(List<Candle> candles, int period) {
    if (candles.length < period) {
      return List<double?>.filled(candles.length, null);
    }

    final result = List<double?>.filled(candles.length, null);
    final multiplier = 2.0 / (period + 1);

    // Start with SMA for first value
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += candles[i].close;
    }
    result[period - 1] = sum / period;

    // Calculate EMA for remaining values
    for (int i = period; i < candles.length; i++) {
      final ema =
          (candles[i].close - result[i - 1]!) * multiplier + result[i - 1]!;
      result[i] = ema;
    }

    return result;
  }

  /// Relative Strength Index
  static List<double?> rsi(List<Candle> candles, int period) {
    if (candles.length < period + 1) {
      return List<double?>.filled(candles.length, null);
    }

    final result = List<double?>.filled(candles.length, null);
    final gains = <double>[];
    final losses = <double>[];

    // Calculate price changes
    for (int i = 1; i < candles.length; i++) {
      final change = candles[i].close - candles[i - 1].close;
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    // Calculate first average gain/loss
    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    // Calculate RSI
    for (int i = period; i < candles.length; i++) {
      if (avgLoss == 0) {
        result[i] = 100;
      } else {
        final rs = avgGain / avgLoss;
        result[i] = 100 - (100 / (1 + rs));
      }

      // Smooth the averages for next iteration
      if (i < candles.length - 1) {
        avgGain = (avgGain * (period - 1) + gains[i]) / period;
        avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
      }
    }

    return result;
  }

  /// Bollinger Bands
  static Map<String, List<double?>> bollingerBands(
    List<Candle> candles,
    int period,
    double stdDevMultiplier,
  ) {
    final middle = sma(candles, period);
    final upper = List<double?>.filled(candles.length, null);
    final lower = List<double?>.filled(candles.length, null);

    for (int i = period - 1; i < candles.length; i++) {
      if (middle[i] == null) continue;

      // Calculate standard deviation
      double sumSquaredDiff = 0;
      for (int j = 0; j < period; j++) {
        final diff = candles[i - j].close - middle[i]!;
        sumSquaredDiff += diff * diff;
      }
      final stdDev = math.sqrt(sumSquaredDiff / period);

      upper[i] = middle[i]! + (stdDev * stdDevMultiplier);
      lower[i] = middle[i]! - (stdDev * stdDevMultiplier);
    }

    return {
      'upper': upper,
      'middle': middle,
      'lower': lower,
    };
  }

  /// MACD (Moving Average Convergence Divergence)
  static Map<String, List<double?>> macd(
    List<Candle> candles,
    int fastPeriod,
    int slowPeriod,
    int signalPeriod,
  ) {
    final fastEMA = ema(candles, fastPeriod);
    final slowEMA = ema(candles, slowPeriod);

    // Calculate MACD line
    final macdLine = List<double?>.filled(candles.length, null);
    for (int i = 0; i < candles.length; i++) {
      if (fastEMA[i] != null && slowEMA[i] != null) {
        macdLine[i] = fastEMA[i]! - slowEMA[i]!;
      }
    }

    // Calculate signal line (EMA of MACD)
    final signalLine = _emaOfValues(macdLine, signalPeriod);

    // Calculate histogram
    final histogram = List<double?>.filled(candles.length, null);
    for (int i = 0; i < candles.length; i++) {
      if (macdLine[i] != null && signalLine[i] != null) {
        histogram[i] = macdLine[i]! - signalLine[i]!;
      }
    }

    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': histogram,
    };
  }

  /// Helper: Calculate EMA of a value series
  static List<double?> _emaOfValues(List<double?> values, int period) {
    final result = List<double?>.filled(values.length, null);
    final multiplier = 2.0 / (period + 1);

    // Find first valid starting point
    int startIndex = -1;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != null) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1 || values.length - startIndex < period) {
      return result;
    }

    // Calculate initial SMA
    double sum = 0;
    int count = 0;
    for (int i = startIndex; i < values.length && count < period; i++) {
      if (values[i] != null) {
        sum += values[i]!;
        count++;
      }
    }

    if (count == period) {
      result[startIndex + period - 1] = sum / period;

      // Calculate EMA for remaining values
      for (int i = startIndex + period; i < values.length; i++) {
        if (values[i] != null && result[i - 1] != null) {
          result[i] =
              (values[i]! - result[i - 1]!) * multiplier + result[i - 1]!;
        }
      }
    }

    return result;
  }

  /// Average True Range (for volatility)
  static List<double?> atr(List<Candle> candles, int period) {
    if (candles.length < period + 1) {
      return List<double?>.filled(candles.length, null);
    }

    final result = List<double?>.filled(candles.length, null);
    final trueRanges = <double>[];

    // Calculate True Range for each candle
    for (int i = 1; i < candles.length; i++) {
      final high = candles[i].high;
      final low = candles[i].low;
      final prevClose = candles[i - 1].close;

      final tr = math.max(
        high - low,
        math.max(
          (high - prevClose).abs(),
          (low - prevClose).abs(),
        ),
      );
      trueRanges.add(tr);
    }

    // Calculate first ATR (simple average)
    double atrValue = trueRanges.take(period).reduce((a, b) => a + b) / period;
    result[period] = atrValue;

    // Calculate subsequent ATRs (smoothed)
    for (int i = period + 1; i < candles.length; i++) {
      atrValue = ((atrValue * (period - 1)) + trueRanges[i - 1]) / period;
      result[i] = atrValue;
    }

    return result;
  }
}
