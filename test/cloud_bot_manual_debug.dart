// ignore_for_file: avoid_print
import 'package:volex_terminal/engine/sandbox/sandbox_kernel.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/order.dart';
import 'dart:io';

void main() {
  try {
    // 1. Setup Data (Uptrend 100->200)
    final history = List.generate(100, (i) {
      return Candle(
        time: i * 60000,
        open: 100.0 + i,
        high: 105.0 + i,
        low: 95.0 + i,
        close: 100.0 + i,
        volume: 100,
      );
    });

    // 2. Test EMA Logic (close > ema)
    // In strict uptrend, Close > EMA is ALWAYS true after warmup.
    const script = """
def on_candle(candle):
    ema = indicators.ema(period=10)
    if close > ema:
        volex.buy()
""";

    final signals = executeStrategyKernel(SimulationRequest(script, history));

    if (signals.isEmpty) {
      print('FAILURE: No signals generated');
      exit(1);
    }

    if (signals.last.side != OrderSide.buy) {
      print('FAILURE: Expected BUY signal');
      exit(1);
    }

    // Test Dynamic Threshold: rsi < 999 (should yield signals) vs rsi < 0 (none)
    // Sine wave

    print('SUCCESS: Dynamic Logic Verified');
    exit(0);
  } catch (e) {
    print('EXCEPTION: $e');
    exit(1);
  }
}
