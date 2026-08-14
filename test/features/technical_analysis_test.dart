import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/engine/utils/technical_analysis.dart';

Candle _c(double close) =>
    Candle(time: 0, open: close, high: close, low: close, close: close, volume: 0);

List<Candle> _candles(List<double> closes) => [for (final v in closes) _c(v)];

void main() {
  group('TechnicalAnalysis.calculateSMA', () {
    test('averages the trailing window', () {
      final c = _candles([1, 2, 3, 4, 10, 20, 30]);
      expect(TechnicalAnalysis.calculateSMA(c, 3), closeTo(20.0, 1e-9));
    });
    test('returns 0 with insufficient history', () {
      expect(TechnicalAnalysis.calculateSMA(_candles([1, 2]), 5), 0.0);
    });
  });

  group('TechnicalAnalysis.calculateEMA', () {
    test('EMA of a constant series is that constant', () {
      final c = _candles(List.filled(20, 7.0));
      expect(TechnicalAnalysis.calculateEMA(c, 5), closeTo(7.0, 1e-9));
    });
    test('returns 0 with insufficient history', () {
      expect(TechnicalAnalysis.calculateEMA(_candles([1, 2]), 5), 0.0);
    });
  });

  group('TechnicalAnalysis.calculateStandardDeviation (window bug fix)', () {
    test('uses the SAME trailing window as the SMA', () {
      // First 4 are flat (stddev 0); the trailing window is [10,20,30].
      final c = _candles([1, 1, 1, 1, 10, 20, 30]);
      final sd = TechnicalAnalysis.calculateStandardDeviation(c, 3);
      // Population stddev of [10,20,30] about mean 20 = sqrt(200/3).
      expect(sd, closeTo(math.sqrt(200 / 3), 1e-9));
      // Regression guard: the old bug used the first window and returned 0.
      expect(sd, greaterThan(1.0));
    });
  });

  group('TechnicalAnalysis.calculateBollingerBands', () {
    test('middle is the SMA and bands are symmetric about it', () {
      final c = _candles([1, 1, 1, 1, 10, 20, 30]);
      final bb = TechnicalAnalysis.calculateBollingerBands(c, 3, 2.0);
      expect(bb.middle, closeTo(20.0, 1e-9));
      final sd = math.sqrt(200 / 3);
      expect(bb.upper, closeTo(20 + 2 * sd, 1e-9));
      expect(bb.lower, closeTo(20 - 2 * sd, 1e-9));
    });
  });

  group('TechnicalAnalysis.calculateRSI (documented simple-average MVP)', () {
    test('neutral 50 before enough history', () {
      expect(TechnicalAnalysis.calculateRSI(_candles([1, 2, 3]), 14), 50.0);
    });
    test('rising-only series is 100', () {
      final c = _candles(List.generate(20, (i) => i.toDouble()));
      expect(TechnicalAnalysis.calculateRSI(c, 14), 100.0);
    });
    test('falling-only series is 0', () {
      final c = _candles(List.generate(20, (i) => (20 - i).toDouble()));
      expect(TechnicalAnalysis.calculateRSI(c, 14), closeTo(0.0, 1e-9));
    });
    test('known simple-average value (period 5)', () {
      // closes 10,11,10,11,10,11 -> changes +1,-1,+1,-1,+1
      // gains 3, losses 2 -> avgGain .6, avgLoss .4, rs 1.5 -> RSI 60.
      final c = _candles([10, 11, 10, 11, 10, 11]);
      expect(TechnicalAnalysis.calculateRSI(c, 5), closeTo(60.0, 1e-9));
    });
    test('always within 0..100', () {
      final c = _candles(List.generate(40, (i) => 50 + 8 * math.sin(i / 3)));
      final rsi = TechnicalAnalysis.calculateRSI(c, 14);
      expect(rsi, inInclusiveRange(0.0, 100.0));
    });
  });
}
