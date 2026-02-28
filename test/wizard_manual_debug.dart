// ignore_for_file: avoid_print
import 'package:volex_terminal/engine/wizard/script_templates.dart';
import 'package:volex_terminal/engine/sandbox/sandbox_kernel.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/order.dart';
import 'dart:io';

void main() {
  print('--- WIZARD MANUAL DEBUG ---');
  try {
    // 1. Setup Data
    final uptrendHistory = List.generate(100, (i) {
      return Candle(
        time: i * 60000,
        open: 100.0 + i,
        high: 105.0 + i,
        low: 95.0 + i,
        close: 100.0 + i,
        volume: 100,
      );
    });

    // 2. Test EMA Generation
    final script =
        ScriptTemplates.generateEmaTrend(fastPeriod: 10, slowPeriod: 0);
    print("SCRIPT GENERATED:\n$script");

    if (!script.contains('if close > ema:')) {
      print('FAILURE: Script missing condition');
      exit(1);
    }

    // 3. Execution
    final signals =
        executeStrategyKernel(simulationRequest(script, uptrendHistory));

    print('Signals Count: ${signals.length}');
    if (signals.isEmpty) {
      print('FAILURE: No signals produced');
      exit(1);
    }

    if (signals.last.side != OrderSide.buy) {
      print('FAILURE: Wrong signal side');
      exit(1);
    }

    print('SUCCESS: Wizard Verified');
    exit(0);
  } catch (e, st) {
    print('EXCEPTION: $e');
    print(st);
    exit(1);
  }
}

SimulationRequest simulationRequest(String s, List<Candle> h) =>
    SimulationRequest(s, h);
