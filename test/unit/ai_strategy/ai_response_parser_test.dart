// test/unit/ai_strategy/ai_response_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/services/ai_response_parser.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';

void main() {
  const validJson = '''
  {
    "name": "RSI Strategy",
    "description": "Test",
    "entryConditions": [{"indicator": "RSI", "comparator": "<", "value": 30}],
    "exitConditions": [],
    "riskParams": {"stopLossPercent": 2.0, "takeProfitPercent": 4.0, "positionSizePercent": 10.0},
    "educationalExplanation": "Valid",
    "confidenceScore": 0.8
  }
  ''';

  group('AiResponseParser', () {
    test('parses clean JSON', () {
      final strategy = AiResponseParser.parse(validJson);
      expect(strategy.name, 'RSI Strategy');
    });

    test('sanitizes markdown code blocks', () {
      const raw = '''
      Here is your strategy:
      ```json
      $validJson
      ```
      Hope you like it!
      ''';

      final strategy = AiResponseParser.parse(raw);
      expect(strategy.name, 'RSI Strategy');
    });

    test('throws on partial/invalid JSON', () {
      const invalid = '{"name": "Incomplete...';
      expect(() => AiResponseParser.parse(invalid),
          throwsA(isA<StrategyParsingException>()));
    });

    test('throws on logical validation failure (OutOfBounds)', () {
      const outOfBoundsJson = '''
      {
        "name": "Bad RSI",
        "description": "Test",
        "entryConditions": [{"indicator": "RSI", "comparator": "<", "value": 150}],
        "exitConditions": [],
        "riskParams": {"stopLossPercent": 1, "takeProfitPercent": 1, "positionSizePercent": 1},
        "educationalExplanation": "",
        "confidenceScore": 1.0
      }
      ''';
      // Should parse JSON fine, but fail validation step
      expect(() => AiResponseParser.parse(outOfBoundsJson),
          throwsA(isA<StrategyValidationException>()));
    });
  });
}
