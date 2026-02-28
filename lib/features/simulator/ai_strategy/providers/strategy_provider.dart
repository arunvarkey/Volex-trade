// lib/features/simulator/ai_strategy/providers/strategy_provider.dart
import 'package:flutter/foundation.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/services/ai_service.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_request.dart';
import 'package:get_it/get_it.dart';

class StrategyProvider extends ChangeNotifier {
  final AIService _aiService;
  final BacktestEngine _backtestEngine;

  StrategyProvider({AIService? aiService, BacktestEngine? backtestEngine})
      : _aiService = aiService ?? AIService(),
        _backtestEngine = backtestEngine ?? GetIt.I<BacktestEngine>();

  GeneratedStrategy? _currentStrategy;
  GeneratedStrategy? get currentStrategy => _currentStrategy;

  BacktestResult? _backtestResult;
  BacktestResult? get backtestResult => _backtestResult;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Generates a new strategy using AI.
  Future<void> generateStrategy(String prompt,
      {bool useCompanyKey = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStrategy = await _aiService.generateStrategy(
          userPrompt: prompt, useCompanyKey: useCompanyKey);
      _backtestResult = null; // Reset backtest on new strategy
    } catch (e) {
      // Fallback to Mock Strategy (Demo Mode) if key missing/invalid
      if (e is AiStrategyError &&
          (e.type == AiErrorType.missingKey ||
              e.type == AiErrorType.invalidKey)) {
        AppLogger.warning(
            'No valid API key found/accessible. Falling back to Demo Mode.');
        _currentStrategy = await _aiService.generateMockStrategy(query: prompt);
        _backtestResult = null;
        // Optionally notify user via snackbar that we used Demo Mode?
        // _error = "Running in Demo Mode (No API Key)"; // Or keep silent?
        // Silent fallback is smoother, maybe add a flag to strategy?
      } else {
        _error = e.toString();
        // Improve error message for users if it's our typed error
        if (e is AiStrategyError) {
          _error = e.message;
        }
        AppLogger.error('Strategy Generation Failed', e);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Runs backtest on the current valid strategy.
  Future<void> runBacktest() async {
    if (_currentStrategy == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final request = BacktestRequest(
        strategy: _currentStrategy!,
        startDate: now.subtract(const Duration(days: 90)),
        endDate: now,
        initialEquity: 10000.0,
      );

      _backtestResult = await _backtestEngine.run(request);
    } catch (e) {
      _error = 'Backtest Failed: $e';
      AppLogger.error('Backtest Failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearStrategy() {
    _currentStrategy = null;
    _backtestResult = null;
    _error = null;
    notifyListeners();
  }
}
