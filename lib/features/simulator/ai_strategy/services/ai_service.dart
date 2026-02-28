// lib/features/simulator/ai_strategy/services/ai_service.dart
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/services/ai_response_parser.dart';
import '../models/strategy_template.dart';
import '../models/template_parameter.dart';

class AIService {
  final bool _allowDelay;

  AIService({
    bool allowDelay = true,
  }) : _allowDelay = allowDelay;

  /// Generates a complete trading strategy based on user prompt.
  Future<GeneratedStrategy> generateStrategy({
    required String userPrompt,
    bool useCompanyKey = false, // Kept for interface compatibility but ignored
  }) async {
    final systemPrompt = _buildSystemPrompt();
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    try {
      final rawContent =
          await _callCloudFunction('generateStrategy', {'messages': messages});
      final strategy = AiResponseParser.parse(rawContent);
      return strategy;
    } catch (e) {
      if (e is AiStrategyError ||
          e is StrategyValidationException ||
          e is StrategyParsingException) {
        rethrow;
      }
      throw AiStrategyError(AiErrorType.unknown, 'Unexpected error: $e',
          originalError: e.toString());
    }
  }

  /// Suggestions for "Mad Libs" mode
  Future<AIResult<Map<String, dynamic>>> suggestParameters({
    required StrategyTemplate template,
    required String userDescription,
  }) async {
    final prompt = _buildParamSuggestionPrompt(template, userDescription);
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'You are a quantitative config assistant. JSON only.'
        },
        {'role': 'user', 'content': prompt},
      ];

      final rawContent =
          await _callCloudFunction('suggestParameters', {'messages': messages});

      final cleaned =
          rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
      final suggestion = jsonDecode(cleaned) as Map<String, dynamic>;
      return AIResult.success(suggestion);
    } catch (e) {
      return AIResult.error('Failed to get suggestions: $e');
    }
  }

  Future<GeneratedStrategy> generateMockStrategy({String? query}) async {
    if (_allowDelay) {
      await Future.delayed(const Duration(seconds: 1));
    }

    final strategies = [
      _rsiReversalStrategy,
      _macdTrendStrategy,
      _bollingerBreakoutStrategy,
      _smaCrossoverStrategy,
    ];

    if (query != null) {
      final q = query.toLowerCase();
      if (q.contains('rsi')) {
        return _rsiReversalStrategy;
      }
      if (q.contains('macd') || q.contains('trend')) {
        return _macdTrendStrategy;
      }
      if (q.contains('band') || q.contains('bollinger')) {
        return _bollingerBreakoutStrategy;
      }
      if (q.contains('sma') || q.contains('cross')) {
        return _smaCrossoverStrategy;
      }
    }

    return (strategies..shuffle()).first;
  }

  static final _rsiReversalStrategy = GeneratedStrategy(
    name: 'Demo RSI Reversal',
    symbol: 'BTCUSDT',
    timeframe: '1h',
    description:
        'A classic mean-reversion strategy for demonstration purposes.',
    educationalExplanation:
        'This strategy attempts to catch potential reversals by buying when the Relative Strength Index (RSI) indicates the asset is oversold (< 30) and selling when it becomes overbought (> 70).',
    entryConditions: const [
      StrategyCondition(
        indicator: 'RSI',
        comparator: '<',
        value: 30.0,
        params: {'period': 14},
      ),
    ],
    exitConditions: const [
      StrategyCondition(
        indicator: 'RSI',
        comparator: '>',
        value: 70.0,
        params: {'period': 14},
      ),
    ],
    riskParams: const RiskParameters(
        stopLossPercent: 2.0,
        takeProfitPercent: 4.0,
        positionSizePercent: 10.0),
    confidenceScore: 0.85,
  );

  static final _macdTrendStrategy = GeneratedStrategy(
    name: 'Demo MACD Trend',
    symbol: 'BTCUSDT',
    timeframe: '1h',
    description:
        'Follows the trend using Moving Average Convergence Divergence.',
    educationalExplanation:
        'This strategy buys when the MACD line crosses above the signal line, indicating bullish momentum, and sells when it crosses below. Ideally used in trending markets.',
    entryConditions: const [
      StrategyCondition(
        indicator: 'MACD',
        comparator: '>',
        value: 0.0,
        params: {'fastPeriod': 12, 'slowPeriod': 26, 'signalPeriod': 9},
      ),
    ],
    exitConditions: const [
      StrategyCondition(
        indicator: 'MACD',
        comparator: '<',
        value: 0.0,
        params: {'fastPeriod': 12, 'slowPeriod': 26, 'signalPeriod': 9},
      ),
    ],
    riskParams: const RiskParameters(
        stopLossPercent: 1.5,
        takeProfitPercent: 3.0,
        positionSizePercent: 10.0),
    confidenceScore: 0.78,
  );

  static final _bollingerBreakoutStrategy = GeneratedStrategy(
    name: 'Demo BB Breakout',
    symbol: 'BTCUSDT',
    timeframe: '1h',
    description: 'Captures volatility breakouts using Bollinger Bands.',
    educationalExplanation:
        'Bollinger Bands measure volatility. This strategy buys when price closes above the upper band, suggesting a strong breakout, and sells when it returns to the mean (SMA).',
    entryConditions: const [
      StrategyCondition(
        indicator: 'BOLLINGER_BANDS',
        comparator: '>',
        value: 2.0,
        params: {'period': 20, 'stdDev': 2.0},
      ),
    ],
    exitConditions: const [
      StrategyCondition(
        indicator: 'RSI',
        comparator: '>',
        value: 50.0,
        params: {'period': 14},
      ),
    ],
    riskParams: const RiskParameters(
        stopLossPercent: 1.0,
        takeProfitPercent: 5.0,
        positionSizePercent: 10.0),
    confidenceScore: 0.72,
  );

  static final _smaCrossoverStrategy = GeneratedStrategy(
    name: 'Demo Golden Cross',
    symbol: 'BTCUSDT',
    timeframe: '1h',
    description: 'Long-term trend following using Moving Averages.',
    educationalExplanation:
        'Attempts to capture major trends by entering when the short-term average (SMA 50) is above the long-term average (SMA 200).',
    entryConditions: const [
      StrategyCondition(
        indicator: 'RSI',
        comparator: '>',
        value: 50.0,
        params: {'period': 14},
      ),
    ],
    exitConditions: const [
      StrategyCondition(
        indicator: 'RSI',
        comparator: '<',
        value: 40.0,
        params: {'period': 14},
      ),
    ],
    riskParams: const RiskParameters(
        stopLossPercent: 2.0,
        takeProfitPercent: 6.0,
        positionSizePercent: 10.0),
    confidenceScore: 0.65,
  );

  /// Calls the secure Firebase Cloud Function instead of the OpenAI API directly
  Future<String> _callCloudFunction(
      String functionName, Map<String, dynamic> data) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable(functionName);
      final results = await callable.call(data);

      final content = results.data['result'] as String?;
      if (content == null || content.isEmpty) {
        throw const AiStrategyError(
            AiErrorType.parsingError, 'Empty response from Cloud Function.');
      }
      return content;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('Cloud Function Exception: ${e.code} - ${e.message}');

      if (e.code == 'unauthenticated') {
        throw const AiStrategyError(
            AiErrorType.invalidKey, 'User must be authenticated to use AI.');
      } else if (e.code == 'resource-exhausted') {
        throw const AiStrategyError(
            AiErrorType.rateLimit, 'Rate limit exceeded. Try again later.');
      } else {
        throw AiStrategyError(
            AiErrorType.networkError, 'Cloud Function Error: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('Network Error: $e');
      throw AiStrategyError(
          AiErrorType.networkError, 'Network/Connection Error: $e');
    }
  }

  String _buildSystemPrompt() {
    return '''
You are "Volex StratGen", an expert quantitative trading strategist for a specialized educational simulator.
Your goal is to generate executable trading strategies based on user descriptions.

You MUST respond with a SINGLE valid JSON object matching the `GeneratedStrategy` schema.
NO markdown formatting (no ```json code blocks).
NO conversational text before or after the JSON.

SCHEMA REQUIREMENTS:
{
  "name": "Short catchy name",
  "description": "2-sentence summary",
  "entryConditions": [
    { "indicator": "RSI" | "MACD" | "SMA" | "EMA" | "VOLUME" | "BOLLINGER_BANDS", "comparator": ">" | "<", "value": number, "params": {"period": int} }
  ],
  "exitConditions": [ ...same structure... ],
  "riskParams": {
    "stopLossPercent": number (0.1-50.0),
    "takeProfitPercent": number (0.1-1000.0),
    "positionSizePercent": number (1.0-100.0)
  },
  "educationalExplanation": "A detailed paragraph teaching the user WHY this strategy works, explaining the indicators used and the logic behind the entry/exit points.",
  "confidenceScore": number (0.0-1.0),
  "warnings": ["Array of potential risks or limitations"]
}

STRICT RULES:
1. "educationalExplanation" is CRITICAL. It must be educational and explain the "Why".
2. Use specific parameters (e.g., RSI period 14, SMA period 50) based on typical market standards unless requested otherwise.
3. Ensure "stopLossPercent" and "takeProfitPercent" are realistic (e.g., SL 2%, TP 4% for trend following).
4. If the user request is vague ("make money"), generate a conservative, standard trend-following strategy (e.g., Golden Cross or RSI pullback).
5. If the user request is unsafe or non-sensical, generate a safe fallback strategy and explain in "educationalExplanation" why the original request was risky, or add "warnings".

''';
  }

  String _buildParamSuggestionPrompt(
      StrategyTemplate template, String userDescription) {
    final params = template.parameters.map((p) {
      if (p is NumericParameter) {
        return '- ${p.id}: number (${p.min}-${p.max}, default ${p.defaultValue}) - ${p.description ?? p.label}';
      } else if (p is DropdownParameter) {
        return '- ${p.id}: string (${p.options.join("|")}) - ${p.description ?? p.label}';
      }
      return '- ${p.id}: ${p.description ?? p.label}';
    }).join('\n');

    return '''
Template: ${template.name}
User's goal: "$userDescription"

Available parameters:
$params

Based on the user's description, suggest optimal parameter values that would help achieve their trading goal.

Respond with ONLY this JSON structure (no markdown, no explanations):
{
  ${template.parameters.map((p) => '"${p.id}": <appropriate_value>').join(',\n  ')},
  "reasoning": "Brief 1-sentence explanation of why these values match the goal"
}
''';
  }
}

// ... AIResult class (Keep existing)
class AIResult<T> {
  final T? value;
  final String? error;
  AIResult.success(this.value) : error = null;
  AIResult.error(this.error) : value = null;
  bool get isSuccess => error == null;
}
