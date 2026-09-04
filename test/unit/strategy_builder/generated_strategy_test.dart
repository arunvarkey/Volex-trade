// test/unit/strategy_builder/generated_strategy_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/simulator/strategy_builder/models/generated_strategy.dart';

void main() {
  group('GeneratedStrategy Validation', () {
    test('valid strategy passes validation', () {
      final strategy = GeneratedStrategy(
        name: 'Test',
        symbol: 'BTCUSDT',
        timeframe: '1h',
        description: 'Desc',
        entryConditions: const [
          StrategyCondition(indicator: 'RSI', comparator: '<', value: 30)
        ],
        exitConditions: const [
          StrategyCondition(indicator: 'RSI', comparator: '>', value: 70)
        ],
        riskParams: const RiskParameters(
            stopLossPercent: 2.0,
            takeProfitPercent: 4.0,
            positionSizePercent: 10.0),
        educationalExplanation: 'Works properly',
        confidenceScore: 0.9,
      );

      expect(() => strategy.validate(), returnsNormally);
    });

    test('throws on empty entry conditions', () {
      final strategy = GeneratedStrategy(
        name: 'Test',
        symbol: 'BTCUSDT',
        timeframe: '1h',
        description: 'Desc',
        entryConditions: const [], // Empty
        exitConditions: const [],
        riskParams: const RiskParameters(
            stopLossPercent: 1, takeProfitPercent: 1, positionSizePercent: 1),
        educationalExplanation: '',
        confidenceScore: 1.0,
      );
      expect(() => strategy.validate(),
          throwsA(isA<StrategyValidationException>()));
    });
  });

  group('StrategyCondition Bounds', () {
    test('RSI > 100 throws', () {
      const condition =
          StrategyCondition(indicator: 'RSI', comparator: '>', value: 150.0);
      expect(() => condition.validateBounds(),
          throwsA(isA<StrategyValidationException>()));
    });

    test('RSI period < 2 throws', () {
      const condition = StrategyCondition(
        indicator: 'RSI',
        comparator: '>',
        value: 50,
        params: {'period': 1},
      );
      expect(() => condition.validateBounds(),
          throwsA(isA<StrategyValidationException>()));
    });

    test('Volume negative throws', () {
      const condition =
          StrategyCondition(indicator: 'VOLUME', comparator: '>', value: -100);
      expect(() => condition.validateBounds(),
          throwsA(isA<StrategyValidationException>()));
    });
  });
}
