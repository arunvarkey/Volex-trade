// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/engine/sandbox/sandbox_kernel.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/order.dart';
import 'dart:math' as math;

void main() {
  group('Dynamic Kernel V2', () {
    late List<Candle> mockHistory;

    setUp(() {
      // Linear UPTREND
      // Price goes 100, 101, 102...
      // EMA will lag below Price.
      mockHistory = List.generate(100, (i) {
        return Candle(
          time: i * 60000,
          open: 100.0 + i,
          high: 105.0 + i,
          low: 95.0 + i,
          close: 100.0 + i,
          volume: 100,
        );
      });
    });

    test('EMA Crossover Logic (Price > EMA)', () {
      const script = """
def on_candle(candle):
    ema = indicators.ema(period=10)
    if close > ema:
        volex.buy()
    elif close < ema:
        volex.sell()
""";

      final signals = executeStrategyKernel(
        SimulationRequest(script, mockHistory),
      );

      print('Signals: ${signals.length}');
      // In an uptrend, close is ALWAYS > EMA (after warmup)
      // So we should see predominantly BUY signals

      expect(signals, isNotEmpty);
      expect(signals.last.side, OrderSide.buy);

      // Verify EMA was calculated
      expect(signals.first.description, 'Condition Met');
    });

    test('Custom RSI Threshold (20 instead of 30)', () {
      // Sine Wave for RSI

      final sineHistory = List.generate(100, (i) {
        final angle = (i / 100) * 4 * math.pi;
        final price = 50 + (math.sin(angle) * 10);
        return Candle(
            time: i * 60000,
            open: price,
            high: price + 1,
            low: price - 1,
            close: price,
            volume: 100);
      });

      // Script A: RSI < 20
      const scriptA = """
def on_candle(candle):
    rsi = indicators.rsi(period=14)
    if rsi < 20:
        volex.buy()
""";

      // Script B: RSI < 80 (Should trigger WAY more)
      const scriptB = """
def on_candle(candle):
    rsi = indicators.rsi(period=14)
    if rsi < 80:
        volex.buy()
""";

      final signalsA =
          executeStrategyKernel(SimulationRequest(scriptA, sineHistory));
      final signalsB =
          executeStrategyKernel(SimulationRequest(scriptB, sineHistory));

      print('Signals A (<20): ${signalsA.length}');
      print('Signals B (<80): ${signalsB.length}');

      // Logic Check: RSI < 80 is almost always true. RSI < 20 is rare.
      expect(signalsB.length, greaterThan(signalsA.length));
    });
  });
}
