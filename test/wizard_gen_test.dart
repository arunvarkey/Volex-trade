// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/engine/wizard/script_templates.dart';
import 'package:volex_terminal/engine/sandbox/sandbox_kernel.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/order.dart';

void main() {
  group('Wizard Template Verification', () {
    late List<Candle> uptrendHistory;

    setUp(() {
      // Linear UPTREND (Price 100 -> 200). EMA will be below price.
      uptrendHistory = List.generate(100, (i) {
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

    test('EMA Trend Template - Should generate BUY signals in Uptrend', () {
      // 1. Generate Script
      final script =
          ScriptTemplates.generateEmaTrend(fastPeriod: 10, slowPeriod: 0);
      print("GENERATED SCRIPT:\n$script");

      // 2. Validate Strings
      expect(script, contains('indicators.ema(period=10)'));
      expect(script, contains('if close > ema:'));

      // 3. Execute in Kernel
      final signals = executeStrategyKernel(
        SimulationRequest(script, uptrendHistory),
      );

      // 4. Verification
      expect(signals, isNotEmpty);
      expect(signals.last.side, OrderSide.buy);
      print(
          "Success: Generated EMA script produced ${signals.length} signals.");
    });

    test('RSI Template - Syntax Check', () {
      final script = ScriptTemplates.generateRsiReversion(
          period: 14, buyThreshold: 25.0, sellThreshold: 75.0);

      expect(script, contains('indicators.rsi(period=14)'));
      expect(script, contains('if rsi < 25.0:'));
      expect(script, contains('elif rsi > 75.0:'));
    });
  });
}
