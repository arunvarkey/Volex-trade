import '../../domain/candle_model.dart';
import '../../domain/trade_signal.dart';
import '../../domain/order.dart';
import 'dart:math' as math;

class SimulationRequest {
  final String script;
  final List<Candle> history;
  SimulationRequest(this.script, this.history);
}

/// The "Kernel" that runs inside the Isolate.
/// Now features a "Micro-Interpreter" to execute dynamic user logic.
List<TradeSignal> executeStrategyKernel(SimulationRequest request) {
  final signals = <TradeSignal>[];
  final candles = request.history;

  if (candles.isEmpty) return signals;

  // --- 1. PARSE & SETUP ---
  // We scan the script to see what indicators are needed.
  // Syntax expected: indicators.rsi(period=14), indicators.ema(period=20)

  final rsiPeriod = _extractParameter(request.script, 'rsi', 14);
  final smaPeriod = _extractParameter(request.script, 'sma', 20);
  final emaPeriod = _extractParameter(request.script, 'ema', 20); // NEW

  // Pre-calculate Data
  final useRSI = request.script.contains('rsi');
  final useSMA = request.script.contains('sma');
  final useEMA = request.script.contains('ema');

  List<double>? rsiValues;
  List<double>? smaValues;
  List<double>? emaValues;

  if (useRSI) rsiValues = _calculateRSI(candles, rsiPeriod);
  if (useSMA) smaValues = _calculateSMA(candles, smaPeriod);
  if (useEMA) emaValues = _calculateEMA(candles, emaPeriod); // NEW

  // --- 2. LOGIC EXTRACTION (Simple Rule Matcher) ---
  // We support two main rules: BUY Condition and SELL Condition.
  // We look for lines starting with "if" and "elif"/"else".

  // Example: "if rsi < 30 and close > ema:"
  final buyConditions = _extractConditions(request.script, 'if');
  final sellConditions = _extractConditions(request.script, 'elif');
  if (sellConditions.isEmpty) {
    // fallback if user manually typed "else:" or second "if"
    _extractConditions(request.script, 'if', skipFirst: true);
  }

  // --- 3. EXECUTION LOOP ---
  // Start after warmup
  final startIdx = [rsiPeriod, smaPeriod, emaPeriod].reduce(math.max) + 1;

  for (int i = startIdx; i < candles.length; i++) {
    final candle = candles[i];
    final values = <String, double>{
      'close': candle.close,
      'open': candle.open,
      'high': candle.high,
      'low': candle.low,
      'volume': candle.volume,
      if (useRSI) 'rsi': rsiValues![i],
      if (useSMA) 'sma': smaValues![i],
      if (useEMA) 'ema': emaValues![i],
    };

    // Evaluate BUY
    if (_evaluate(buyConditions, values)) {
      signals.add(TradeSignal(
        timestamp: candle.date,
        price: candle.close,
        side: OrderSide.buy,
        strategyName: 'PythonBot',
        description: 'Condition Met',
      ));
    }
    // Evaluate SELL
    else if (_evaluate(sellConditions, values)) {
      signals.add(TradeSignal(
        timestamp: candle.date,
        price: candle.close,
        side: OrderSide.sell,
        strategyName: 'PythonBot',
        description: 'Condition Met',
      ));
    }
  }

  return signals;
}

// --- PARSER UTILS ---

int _extractParameter(String script, String func, int defaultVal) {
  final regex = RegExp('$func\\(period=(\\d+)\\)');
  final match = regex.firstMatch(script);
  if (match != null) {
    return int.parse(match.group(1)!);
  }
  return defaultVal;
}

List<String> _extractConditions(String script, String type,
    {bool skipFirst = false}) {
  // Finds lines starting with "if " or "elif ". Returns the condition string.
  final lines = script.split('\n');
  int count = 0;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('$type ')) {
      if (skipFirst && count == 0) {
        count++;
        continue;
      }
      // "if rsi < 30:" -> "rsi < 30"
      return [trimmed.substring(type.length, trimmed.lastIndexOf(':')).trim()];
    }
  }
  return [];
}

bool _evaluate(List<String> conditions, Map<String, double> values) {
  if (conditions.isEmpty) return false;

  // Minimal Logic Engine
  // Supports AND logic. e.g. "rsi < 30 and close > ema"
  final conditionPart = conditions.first; // Single line logic for now

  final parts = conditionPart.split(' and ');
  for (final part in parts) {
    if (!_evaluateSingle(part.trim(), values)) return false;
  }
  return true;
}

bool _evaluateSingle(String part, Map<String, double> values) {
  // "rsi < 30"
  String op = '';
  if (part.contains('>=')) {
    op = '>=';
  } else if (part.contains('<=')) {
    op = '<=';
  } else if (part.contains('>')) {
    op = '>';
  } else if (part.contains('<')) {
    op = '<';
  } else {
    return false;
  }

  final sides = part.split(op);
  if (sides.length != 2) return false;

  final leftStr = sides[0].trim();
  final rightStr = sides[1].trim();

  final leftVal = values[leftStr] ?? double.tryParse(leftStr) ?? 0.0;
  final rightVal = values[rightStr] ?? double.tryParse(rightStr) ?? 0.0;

  switch (op) {
    case '>':
      return leftVal > rightVal;
    case '<':
      return leftVal < rightVal;
    case '>=':
      return leftVal >= rightVal;
    case '<=':
      return leftVal <= rightVal;
    default:
      return false;
  }
}

// --- INDICATORS ---

List<double> _calculateSMA(List<Candle> candles, int period) {
  final result = List<double>.filled(candles.length, 0.0);
  for (int i = period; i < candles.length; i++) {
    double sum = 0;
    for (int j = 0; j < period; j++) {
      sum += candles[i - j].close;
    }
    result[i] = sum / period;
  }
  return result;
}

List<double> _calculateEMA(List<Candle> candles, int period) {
  final result = List<double>.filled(candles.length, 0.0);
  if (candles.isEmpty) return result;

  final k = 2 / (period + 1);
  result[0] = candles[0].close;

  for (int i = 1; i < candles.length; i++) {
    result[i] = (candles[i].close * k) + (result[i - 1] * (1 - k));
  }
  return result;
}

List<double> _calculateRSI(List<Candle> candles, int period) {
  final result = List<double>.filled(candles.length, 50.0);
  if (candles.length <= period) return result;

  // Initial Average Gain/Loss
  double gain = 0;
  double loss = 0;
  for (int j = 1; j <= period; j++) {
    final change = candles[j].close - candles[j - 1].close;
    if (change > 0) {
      gain += change;
    } else {
      loss -= change;
    }
  }
  double avgGain = gain / period;
  double avgLoss = loss / period;

  // Smoothing
  for (int i = period + 1; i < candles.length; i++) {
    final change = candles[i].close - candles[i - 1].close;
    double currentGain = 0;
    double currentLoss = 0;

    if (change > 0) {
      currentGain = change;
    } else {
      currentLoss = -change;
    }

    avgGain = ((avgGain * (period - 1)) + currentGain) / period;
    avgLoss = ((avgLoss * (period - 1)) + currentLoss) / period;

    if (avgLoss == 0) {
      result[i] = 100;
    } else {
      final rs = avgGain / avgLoss;
      result[i] = 100 - (100 / (1 + rs));
    }
  }
  return result;
}
