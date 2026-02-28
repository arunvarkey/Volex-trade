// ignore_for_file: avoid_print
import 'package:volex_terminal/engine/sandbox/sandbox_kernel.dart';
import 'package:volex_terminal/domain/candle_model.dart';
// For OrderSide
import 'dart:math' as math;

void main() {
  print('--- CLOUD BOT LOGIC CHECK ---');

  // 1. Generate Mock Data
  final now = DateTime.now();
  final mockHistory = List.generate(100, (i) {
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
  print('Generated 100 mock candles.');

  // 2. Define Script
  const script = """
def on_candle(candle):
    rsi = indicators.rsi(period=14)
    if rsi < 30:
        volex.buy()
    elif rsi > 70:
        volex.sell()
""";

  // 3. Execute Kernel
  try {
    print('Executing Kernel...');
    final signals = executeStrategyKernel(
      SimulationRequest(script, mockHistory),
    );

    print('Kernel Execution Complete.');
    print('Signals Generated: ${signals.length}');

    for (final s in signals) {
      print(
          '  [SIGNAL] ${s.timestamp.toIso8601String()} : ${s.side} @ ${s.price.toStringAsFixed(2)} (${s.description})');
    }

    if (signals.isNotEmpty) {
      print('SUCCESS: Signals generated correctly.');
    } else {
      print(
          'WARNING: No signals generated (check RSI thresholds vs sine wave amplitude).');
    }
  } catch (e, st) {
    print('CRITICAL ERROR: $e');
    print(st);
  }
}
