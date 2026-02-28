import 'dart:convert';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/core/app_logger.dart';

/// Responsible for cleaning, parsing, and validating raw LLM output.
/// "Defense in depth" against hallucinations and formatting errors.
class AiResponseParser {
  /// Parses raw string from OpenAI into a validated GeneratedStrategy object.
  /// Throws [StrategyParsingException] on failure.
  static GeneratedStrategy parse(String rawContent) {
    try {
      // 1. Strip Artifacts
      final cleanJson = _sanitizeJson(rawContent);

      // 2. Parse JSON
      final Map<String, dynamic> jsonMap = jsonDecode(cleanJson);

      // 3. Deserialize (Schema Check)
      final strategy = GeneratedStrategy.fromJson({
        ...jsonMap,
        if (!jsonMap.containsKey('symbol')) 'symbol': 'BTCUSDT',
        if (!jsonMap.containsKey('timeframe')) 'timeframe': '1h',
      });

      // 4. Bounds/Logic Validate
      strategy.validate();

      return strategy;
    } on StrategyValidationException {
      rethrow; // Pass validation errors up as-is
    } catch (e, stack) {
      AppLogger.error('AI Response Parsing Failed', e, stack);
      throw StrategyParsingException(
          'Failed to parse AI response: ${e.toString()}',
          originalContent: rawContent);
    }
  }

  /// Removes Markdown code blocks (```json ... ```) and extra whitespace.
  /// Finds the first '{' and the last '}'.
  static String _sanitizeJson(String raw) {
    String clean = raw.trim();

    // Remove markdown code blocks if present
    if (clean.startsWith('```')) {
      clean = clean.replaceAll(RegExp(r'^```(json)?'), '');
      clean = clean.replaceAll(RegExp(r'```$'), '');
    }

    // Find valid JSON boundaries
    final startIndex = clean.indexOf('{');
    final endIndex = clean.lastIndexOf('}');

    if (startIndex == -1 || endIndex == -1 || startIndex > endIndex) {
      throw const StrategyParsingException(
          'No valid JSON object found in response');
    }

    return clean.substring(startIndex, endIndex + 1);
  }
}
