import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/engine/strategy/strategy_base.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/engine/execution/i_execution_service.dart';
import 'package:volex_terminal/engine/parameters/parameter_models.dart';

class MockRuntimeStrategy extends Strategy {
  @override
  String get id => 'mock_runtime';
  @override
  String get name => 'Mock Runtime Strategy';
  @override
  String get description => 'For testing';

  @override
  List<StrategyParameterSchema> get parameters => [];
  @override
  Map<String, dynamic> get currentParameterValues => {};

  @override
  Strategy cloneWith(Map<String, dynamic> newValues) {
    return this;
  }

  @override
  Future<void> onTick(Candle candle, IExecutionService execution,
      ChartController controller) async {
    // Simple logic: buy on every tick if no position, sell on next tick
    // Just to test loop execution
    if (candle.close > 100) {
      // Do something
    }
  }

  Map<String, dynamic> toJson() => {};
}

void main() {
  test('BacktestEngine runs runtime strategy', () async {
    final candles = List.generate(100, (i) {
      return Candle(
        time: DateTime.now().add(Duration(minutes: i)).millisecondsSinceEpoch,
        open: 100.0 + i,
        high: 105.0 + i,
        low: 95.0 + i,
        close: 102.0 + i,
        volume: 1000,
      );
    });

    final strategy = MockRuntimeStrategy();

    final result = await BacktestEngine.runBacktest(BacktestIsolateParams(
      candles: candles,
      runtimeStrategy: strategy,
      initialEquity: 10000,
    ));

    expect(result.metrics.totalTrades, greaterThanOrEqualTo(0));
    expect(result.finalEquity, greaterThan(0));
    // Since runtime strategy logic is minimal, expecting no errors.
    expect(result.error, isNull);
  });
}
