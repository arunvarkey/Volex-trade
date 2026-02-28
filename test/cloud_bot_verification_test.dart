// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart'; // Standard Flutter test
import 'package:volex_terminal/engine/sandbox/sandbox_kernel.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/order.dart'; // For OrderSide
import 'dart:math' as math;

void main() {
  group('Cloud Bot "Hyper-Thread" Verification', () {
    late List<Candle> mockHistory;

    setUp(() {
      final now = DateTime.now();
      mockHistory = List.generate(100, (i) {
        final time =
            now.subtract(Duration(minutes: 100 - i)).millisecondsSinceEpoch;
        final angle = (i / 100) * 4 * math.pi;
        final price = 51000 + (math.sin(angle) * 1000);

        return Candle(
          time: time,
          open: price,
          high: price + 10,
          low: price - 10,
          close: price,
          volume: 100,
        );
      });
    });

    test('Script should generate signals (Pure Dart)', () {
      const script = """
def on_candle(candle):
    rsi = indicators.rsi(period=14)
    if rsi < 30:
        volex.buy()
    elif rsi > 70:
        volex.sell()
""";

      final signals = executeStrategyKernel(
        SimulationRequest(script, mockHistory),
      );

      print('KERNEL OUT: Generated ${signals.length} signals');

      if (signals.isNotEmpty) {
        print('First Signal: ${signals.first.side}');
      }

      expect(signals, isNotEmpty);
      expect(signals.first.side,
          OrderSide.buy); // Assuming first signal is buy at dip
    });
  });
}
