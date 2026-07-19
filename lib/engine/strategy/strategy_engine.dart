import 'dart:async';
import 'package:flutter/material.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/engine/parameters/parameter_models.dart';
import 'package:volex_terminal/engine/parameters/parameter_storage.dart';
import 'package:volex_terminal/engine/persistence/persistence_service.dart';
import 'package:volex_terminal/engine/risk_manager.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/engine/strategy/strategy_registry.dart';
export 'package:volex_terminal/engine/strategy/strategy_base.dart';
import 'package:volex_terminal/engine/strategy/strategy_base.dart';
import 'package:volex_terminal/engine/strategy/strategy_recommendation.dart';

class StrategyEngine extends ChangeNotifier {
  final List<Strategy> _strategies = [];
  final ExecutionManager _executionManager;
  final ChartController _controller;
  final RiskManager _riskManager;
  final ParameterStorageService _paramPersistence = ParameterStorageService();
  final PersistenceService _persistence = getIt<PersistenceService>();

  final StreamController<StrategyLog> _logStream = StreamController.broadcast();
  Stream<StrategyLog> get allLogs => _logStream.stream;
  final List<StrategyLog> _logHistory = [];
  List<StrategyLog> get logHistory => List.unmodifiable(_logHistory);
  StreamSubscription? _liveSubscription;

  String? _activeStrategyId;
  String? get activeStrategyId => _activeStrategyId;

  List<Strategy> get allStrategies => List.unmodifiable(_strategies);

  StrategyEngine({
    required ExecutionManager executionManager,
    required ChartController chartController,
    required RiskManager riskManager,
  })  : _executionManager = executionManager,
        _controller = chartController,
        _riskManager = riskManager {
    _executionManager.addListener(_onExecutionUpdate);
  }

  Future<void> initialize() async {
    _loadBuiltInStrategies();
    await _loadPersistedParameters();
    _loadStrategyStates();
    notifyListeners();
    AppLogger.info(
        "STRATEGY: Engine ready with ${_strategies.length} strategies.");
  }

  void _loadStrategyStates() {
    final enabledMap =
        _persistence.getSetting<Map<dynamic, dynamic>>('enabled_strategies') ??
            {};
    for (var s in _strategies) {
      if (enabledMap.containsKey(s.id)) {
        s.isEnabled = enabledMap[s.id] as bool;
      }
    }
  }

  void _loadBuiltInStrategies() {
    AppLogger.info("STRATEGY: Loading built-in strategies...");
    final ids = StrategyRegistry.allStrategyIds;
    AppLogger.info("STRATEGY: Registry found ${ids.length} strategy IDs: $ids");

    for (final id in ids) {
      try {
        final instance = StrategyRegistry.create(id);
        if (!_strategies.any((s) => s.id == instance.id)) {
          _strategies.add(instance);
          // Hook logging
          instance.onLog = (log) {
            _logHistory.add(log);
            if (_logHistory.length > 500) _logHistory.removeAt(0);
            _logStream.add(log);
          };
          AppLogger.info("STRATEGY: Loaded ${instance.name} (${instance.id})");
        }
      } catch (e) {
        AppLogger.error("STRATEGY: Failed to load $id from registry: $e");
      }
    }
  }

  void setActiveStrategy(String? id) {
    _activeStrategyId = id;
    notifyListeners();
  }

  void toggleStrategy(String id, bool enabled) {
    try {
      final s = _strategies.firstWhere((s) => s.id == id);
      s.isEnabled = enabled;
      _saveEnabledStates();
      notifyListeners();
    } catch (e) {
      AppLogger.error("STRATEGY: Failed to toggle $id: $e");
    }
  }

  void _saveEnabledStates() {
    final Map<String, bool> enabledMap = {
      for (var s in _strategies) s.id: s.isEnabled
    };
    _persistence.saveSetting('enabled_strategies', enabledMap);
  }

  Future<void> _loadPersistedParameters() async {
    final sets = await _paramPersistence.loadParameters();
    for (var set in sets) {
      try {
        final index = _strategies.indexWhere((s) => s.id == set.strategyId);
        if (index != -1) {
          _strategies[index] = _strategies[index].cloneWith(set.values);
        }
      } catch (e) {
        AppLogger.error(
            "STRATEGY: Failed to apply parameters for ${set.strategyId}: $e");
      }
    }
  }

  void _onExecutionUpdate() {
    // React to fills or status changes
    AppLogger.info(
        "STRATEGY: Execution update received. Current risk: ${_riskManager.currentAggregateRiskUsdt}");
  }

  void register(Strategy strategy) {
    if (!_strategies.any((s) => s.id == strategy.id)) {
      _strategies.add(strategy);
      strategy.onLog = (log) {
        _logHistory.add(log);
        if (_logHistory.length > 500) _logHistory.removeAt(0);
        _logStream.add(log);
      };
      _loadStrategyStates(); // Ensure new strategy gets its saved state
      notifyListeners();
    }
  }

  void updateStrategyParams(String id, Map<String, dynamic> newParams,
      {bool persist = true}) {
    final index = _strategies.indexWhere((s) => s.id == id);
    if (index != -1) {
      _strategies[index] = _strategies[index].cloneWith(newParams);
      if (persist) {
        _paramPersistence.saveParameterSet(StrategyParameterSet(
          userId: "sys",
          strategyId: id,
          values: newParams,
          version: 1,
          updatedAt: DateTime.now(),
        ));
      }
      notifyListeners();
    }
  }

  Strategy? getStrategy(String id) {
    try {
      return _strategies.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void pauseAll() {
    _isPaused = true;
    AppLogger.info("STRATEGY: System paused.");
    notifyListeners();
  }

  void resumeAll() {
    _isPaused = false;
    AppLogger.info("STRATEGY: System resumed.");
    notifyListeners();
  }

  bool _isProcessingTick = false;

  Future<void> onTick(Candle candle) async {
    if (_isPaused || _isProcessingTick) {
      return; // Skip if already busy (Task 47)
    }
    _isProcessingTick = true;

    try {
      // Run in microtask to avoid blocking the remainder of the current frame (Task 47)
      await Future.microtask(() async {
        for (var strategy in _strategies) {
          if (strategy.isEnabled) {
            await strategy.onTick(candle, _executionManager, _controller);
          }
        }
      });
    } finally {
      _isProcessingTick = false;
    }
  }

  /// Analyzes a symbol using all enabled strategies to generate recommendations
  Future<List<StrategyRecommendation>> analyzeSymbol(
      String symbol, List<Candle> history) async {
    final recommendations = <StrategyRecommendation>[];

    for (var strategy in _strategies) {
      if (strategy.isEnabled) {
        try {
          final results = await strategy.analyze(symbol, history);
          recommendations.addAll(results);
        } catch (e) {
          AppLogger.error('Error analyzing $symbol with ${strategy.name}: $e');
        }
      }
    }

    return recommendations;
  }

  @override
  void dispose() {
    _logStream.close();
    _liveSubscription?.cancel();
    super.dispose();
  }

  void startLive(dynamic exchange, dynamic symbol) {
    // Real-time tick logic
  }

  void stopLive() {
    _liveSubscription?.cancel();
  }
}
