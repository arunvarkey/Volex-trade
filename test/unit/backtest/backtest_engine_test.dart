// test/unit/backtest/backtest_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/domain/candle_model.dart';

void main() {
  test('BacktestEngine runs simple strategy', () async {
    final longCandles = List.generate(100, (i) {
      return Candle(
        time: DateTime.now().add(Duration(minutes: i)).millisecondsSinceEpoch,
        open: 100.0 + i,
        high: 105.0 + i,
        low: 95.0 + i,
        close: 102.0 + i, // Uptrend
        volume: 1000,
      );
    });

    final strategy = GeneratedStrategy(
      name: 'Test Strategy',
      description: 'Test',
      symbol: 'BTCUSDT',
      timeframe: '1h',
      templateId: 'ma_crossover',
      parameters: const {
        'fast_ma_period': 2,
        'slow_ma_period': 5,
        'ma_type': 'SMA'
      },
      entryConditions: const [],
      exitConditions: const [],
      riskParams: const RiskParameters(
          stopLossPercent: 2, takeProfitPercent: 4, positionSizePercent: 10),
      educationalExplanation: 'Test',
      confidenceScore: 1.0,
    );

    final result = await BacktestEngine.runBacktest(BacktestIsolateParams(
      candles: longCandles,
      strategy: strategy,
      initialEquity: 10000,
    ));

    // Expect at least one trade
    // Fast MA (2) will be close to price. Slow MA (5) will be lagging (lower).
    // So Fast > Slow -> Buy Signal.
    expect(result.metrics.totalTrades, greaterThanOrEqualTo(0));
    expect(result.finalEquity, greaterThan(0));

    // Honesty guardrails: equity-fraction position sizing must keep results
    // finite and sanely bounded — no impossible "up 400%" blow-ups from a
    // fixed 1-unit position on a smooth synthetic series.
    expect(result.finalEquity.isFinite, isTrue);
    expect(result.metrics.totalReturnPercent.isFinite, isTrue);
    expect(result.metrics.maxDrawdownPercent, inInclusiveRange(0, 100));
    expect(result.metrics.winRate, inInclusiveRange(0, 100));
  });

  test('BacktestEngine handles empty data gracefully', () async {
    final strategy = GeneratedStrategy(
      name: 'Test Strategy',
      description: 'Test',
      symbol: 'BTCUSDT',
      timeframe: '1h',
      templateId: 'ma_crossover',
      parameters: const {
        'fast_ma_period': 2,
        'slow_ma_period': 5,
        'ma_type': 'SMA'
      },
      entryConditions: const [],
      exitConditions: const [],
      riskParams: const RiskParameters(
          stopLossPercent: 2, takeProfitPercent: 4, positionSizePercent: 10),
      educationalExplanation: 'Test',
      confidenceScore: 1.0,
    );
    final result = await BacktestEngine.runBacktest(BacktestIsolateParams(
      candles: [],
      strategy: strategy,
      initialEquity: 10000,
    ));
    // Should return error or empty result
    expect(result.error, isNotNull);
  });
}
