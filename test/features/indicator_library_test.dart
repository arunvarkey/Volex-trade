import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/features/simulator/backtest/indicator_library.dart';
import 'package:volex_terminal/core/chart_math.dart';

Candle _c(double close) =>
    Candle(time: 0, open: close, high: close, low: close, close: close, volume: 0);

void main() {
  group('IndicatorLibrary.calculateRSI (Wilder)', () {
    // Canonical StockCharts 14-period worked example.
    const closes = <double>[
      44.34, 44.09, 44.15, 43.61, 44.33, 44.83, 45.10, 45.42,
      45.84, 46.08, 45.89, 46.03, 45.61, 46.28, 46.28,
    ];
    final candles = [for (final v in closes) _c(v)];

    test('matches the StockCharts reference (~70.5)', () {
      final rsi = IndicatorLibrary.calculateRSI(candles, 14, atIndex: 14);
      expect(rsi, inInclusiveRange(69.0, 72.0));
    });

    test('agrees exactly with the chart RSI (single source of truth)', () {
      final rsi = IndicatorLibrary.calculateRSI(candles, 14, atIndex: 14);
      final chart = ChartMath.rsiSeries(closes, period: 14)[14];
      expect(chart, isNotNull);
      expect(rsi, closeTo(chart!, 1e-9));
    });

    test('returns neutral 50 before there is enough history', () {
      expect(IndicatorLibrary.calculateRSI(candles, 14, atIndex: 5), 50.0);
    });
  });

  group('IndicatorLibrary.calculateMACD', () {
    final candles = [
      for (int i = 0; i < 60; i++) _c(100 + (i % 7) * 1.3 - i * 0.2),
    ];

    test('signal line is a real EMA, not stubbed to 0', () {
      final macd = IndicatorLibrary.calculateMACD(candles, atIndex: 59);
      expect(macd.signalLine, isNot(0.0));
    });

    test('histogram equals macdLine minus signalLine', () {
      final macd = IndicatorLibrary.calculateMACD(candles, atIndex: 59);
      expect(macd.histogram, closeTo(macd.macdLine - macd.signalLine, 1e-9));
    });
  });
}
