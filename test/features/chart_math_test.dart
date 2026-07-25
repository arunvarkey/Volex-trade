import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/core/chart_math.dart';

void main() {
  group('ChartMath.niceStep', () {
    test('returns 0 for flat/invalid ranges instead of crashing', () {
      expect(ChartMath.niceStep(0), 0);
      expect(ChartMath.niceStep(-5), 0);
      expect(ChartMath.niceStep(double.infinity), 0);
      expect(ChartMath.niceStep(double.nan), 0);
    });

    test('picks 1 / 2.5 / 5 / 10 style steps', () {
      expect(ChartMath.niceStep(1), 1);
      expect(ChartMath.niceStep(2), 2.5);
      expect(ChartMath.niceStep(4), 5);
      expect(ChartMath.niceStep(8), 10);
      expect(ChartMath.niceStep(0.003), closeTo(0.0025, 1e-12));
      expect(ChartMath.niceStep(30000), closeTo(25000, 1e-6));
    });
  });

  group('ChartMath.priceLevels', () {
    test('flat range yields no levels (regression: log(0) crash)', () {
      expect(ChartMath.priceLevels(100, 100), isEmpty);
      expect(ChartMath.priceLevels(100, 99), isEmpty);
    });

    test('produces levels strictly inside the range at nice steps', () {
      final levels = ChartMath.priceLevels(0, 10);
      expect(levels, [0, 2.5, 5, 7.5]);
      for (final l in ChartMath.priceLevels(68000, 69000)) {
        expect(l, greaterThanOrEqualTo(68000));
        expect(l, lessThan(69000));
      }
      expect(ChartMath.priceLevels(68000, 69000), isNotEmpty);
    });
  });

  group('ChartMath.sma', () {
    test('averages the trailing window', () {
      final v = [1.0, 2.0, 3.0, 4.0, 5.0];
      expect(ChartMath.sma(v, 4, 5), 3.0);
      expect(ChartMath.sma(v, 4, 2), 4.5);
      expect(ChartMath.sma(v, 1, 2), 1.5);
    });

    test('returns null with insufficient history or bad input', () {
      final v = [1.0, 2.0, 3.0];
      expect(ChartMath.sma(v, 1, 3), isNull);
      expect(ChartMath.sma(v, 5, 2), isNull);
      expect(ChartMath.sma(v, 2, 0), isNull);
    });
  });
}
