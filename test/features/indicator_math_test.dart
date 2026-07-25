import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/core/chart_math.dart';

void main() {
  group('emaSeries', () {
    test('is null before the seed index, then SMA-seeded and smoothed', () {
      final ema = ChartMath.emaSeries([1, 2, 3, 4, 5], 3);
      // k = 2/(3+1) = 0.5; seed at index 2 = SMA(1,2,3) = 2.
      expect(ema[0], isNull);
      expect(ema[1], isNull);
      expect(ema[2], closeTo(2.0, 1e-9));
      expect(ema[3], closeTo(3.0, 1e-9)); // (4-2)*0.5 + 2
      expect(ema[4], closeTo(4.0, 1e-9)); // (5-3)*0.5 + 3
    });

    test('EMA of a constant series is that constant', () {
      final ema = ChartMath.emaSeries(List.filled(10, 7.0), 4);
      for (int i = 3; i < 10; i++) {
        expect(ema[i], closeTo(7.0, 1e-9));
      }
    });

    test('returns all-null when there is not enough history', () {
      final ema = ChartMath.emaSeries([1, 2], 5);
      expect(ema.every((v) => v == null), isTrue);
    });
  });

  group('rsiSeries', () {
    // Canonical StockCharts 14-period worked example.
    const closes = <double>[
      44.34, 44.09, 44.15, 43.61, 44.33, 44.83, 45.10, 45.42,
      45.84, 46.08, 45.89, 46.03, 45.61, 46.28, 46.28,
    ];

    test('first RSI matches the known reference (~70.5)', () {
      final rsi = ChartMath.rsiSeries(closes, period: 14);
      expect(rsi[13], isNull, reason: 'not enough history yet');
      expect(rsi[14], isNotNull);
      expect(rsi[14]!, inInclusiveRange(69.0, 72.0));
    });

    test('a rising-only series is overbought (100)', () {
      final rsi = ChartMath.rsiSeries(
          List.generate(30, (i) => i.toDouble()),
          period: 14);
      expect(rsi[14]!, closeTo(100.0, 1e-9));
    });

    test('a falling-only series is oversold (0)', () {
      final rsi = ChartMath.rsiSeries(
          List.generate(30, (i) => (30 - i).toDouble()),
          period: 14);
      expect(rsi[14]!, closeTo(0.0, 1e-9));
    });

    test('a flat series is neutral (50)', () {
      final rsi = ChartMath.rsiSeries(List.filled(30, 5.0), period: 14);
      expect(rsi[14]!, closeTo(50.0, 1e-9));
    });

    test('RSI always stays within 0..100', () {
      final rsi = ChartMath.rsiSeries(
        List.generate(60, (i) => (50 + 10 * (i % 5 - 2)).toDouble()),
        period: 14,
      );
      for (final v in rsi) {
        if (v != null) expect(v, inInclusiveRange(0.0, 100.0));
      }
    });
  });

  group('nearestIndexByTime', () {
    const times = [100, 200, 300, 400];

    test('empty list returns -1', () {
      expect(ChartMath.nearestIndexByTime(const [], 5), -1);
    });
    test('before first clamps to 0', () {
      expect(ChartMath.nearestIndexByTime(times, 10), 0);
    });
    test('after last clamps to the end', () {
      expect(ChartMath.nearestIndexByTime(times, 9999), 3);
    });
    test('exact match returns that index', () {
      expect(ChartMath.nearestIndexByTime(times, 300), 2);
    });
    test('rounds to the nearer neighbour', () {
      expect(ChartMath.nearestIndexByTime(times, 240), 1);
      expect(ChartMath.nearestIndexByTime(times, 260), 2);
    });
    test('a tie resolves to the lower index', () {
      expect(ChartMath.nearestIndexByTime(times, 250), 1);
    });
  });

  group('distanceToSegment', () {
    test('a point on the segment is distance 0', () {
      expect(ChartMath.distanceToSegment(1, 0, 0, 0, 2, 0), closeTo(0, 1e-9));
    });
    test('perpendicular distance to the line', () {
      expect(ChartMath.distanceToSegment(1, 3, 0, 0, 2, 0), closeTo(3, 1e-9));
    });
    test('beyond an endpoint measures to that endpoint', () {
      expect(ChartMath.distanceToSegment(5, 0, 0, 0, 2, 0), closeTo(3, 1e-9));
    });
    test('a zero-length segment measures to its point', () {
      expect(ChartMath.distanceToSegment(3, 4, 0, 0, 0, 0), closeTo(5, 1e-9));
    });
  });

  group('macd', () {
    test('constant series gives zero macd, signal and histogram', () {
      final r = ChartMath.macd(List.filled(60, 3.0));
      for (int i = 0; i < 60; i++) {
        if (r.macd[i] != null) expect(r.macd[i]!, closeTo(0.0, 1e-9));
        if (r.signal[i] != null) expect(r.signal[i]!, closeTo(0.0, 1e-9));
        if (r.histogram[i] != null) expect(r.histogram[i]!, closeTo(0.0, 1e-9));
      }
    });

    test('histogram equals macd minus signal wherever both are defined', () {
      final closes = List.generate(80, (i) => 100 + (i % 7) * 1.3 - i * 0.2);
      final r = ChartMath.macd(closes);
      for (int i = 0; i < closes.length; i++) {
        final m = r.macd[i];
        final s = r.signal[i];
        final h = r.histogram[i];
        if (m != null && s != null) {
          expect(h, isNotNull);
          expect(h!, closeTo(m - s, 1e-9));
        }
      }
    });

    test('macd line is defined only once the slow EMA has history', () {
      final closes = List.generate(40, (i) => i.toDouble());
      final r = ChartMath.macd(closes, fast: 12, slow: 26, signalPeriod: 9);
      // slow EMA seeds at index 25, so macd is null before that.
      for (int i = 0; i < 25; i++) {
        expect(r.macd[i], isNull);
      }
      expect(r.macd[25], isNotNull);
    });
  });
}
