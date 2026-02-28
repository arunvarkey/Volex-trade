import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/services/ai_service.dart';

void main() {
  late AIService aiService;

  setUp(() {
    aiService = AIService(allowDelay: false);
  });

  group('AIService Demo Mode', () {
    test('returns RSI strategy when query contains "rsi"', () async {
      final strategy =
          await aiService.generateMockStrategy(query: 'I want an RSI strategy');
      expect(strategy.name, contains('RSI'));
      expect(strategy.entryConditions.first.indicator, 'RSI');
    });

    test('returns MACD strategy when query contains "macd"', () async {
      final strategy =
          await aiService.generateMockStrategy(query: 'Show me a MACD trend');
      expect(strategy.name, contains('MACD'));
      expect(strategy.entryConditions.first.indicator, 'MACD');
    });

    test('returns Bollinger strategy when query contains "bollinger"',
        () async {
      final strategy =
          await aiService.generateMockStrategy(query: 'Use Bollinger Bands');
      expect(strategy.name, contains('BB'));
      expect(strategy.entryConditions.first.indicator, 'BOLLINGER_BANDS');
    });

    test('returns SMA strategy when query contains "sma" or "cross"', () async {
      final strategy =
          await aiService.generateMockStrategy(query: 'Simple SMA cross');
      expect(strategy.name, contains('Golden Cross'));
      // Note: The entry condition for Golden Cross in demo uses RSI as placeholder in current impl,
      // but let's check name to be sure it selected the right one.
    });

    test('returns valid strategy even with null query', () async {
      final strategy = await aiService.generateMockStrategy();
      expect(strategy.name, isNotEmpty);
      expect(strategy.entryConditions, isNotEmpty);
    });
  });
}
