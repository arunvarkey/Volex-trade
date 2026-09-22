import 'package:flutter/foundation.dart';
import 'built_in_strategies.dart';
import 'strategy_base.dart';
import 'strategy_metadata.dart';
import '../../core/app_logger.dart';
import 'package:volex_terminal/engine/strategy/unavailable_strategy.dart';

/// Central registry for all trading strategies
class StrategyRegistry with ChangeNotifier {
  static final StrategyRegistry _instance = StrategyRegistry._internal();
  factory StrategyRegistry() => _instance;
  StrategyRegistry._internal();

  /// Map of strategy ID → factory function
  static final Map<String, StrategyFactory> _strategies = {
    'bollinger_rsi': () => BollingerRSIStrategy(),
    'ghost_trend': () => GhostTrendStrategy(),
    'arbitrage': () => ArbitrageStrategy(),
    'scalper': () => ScalperStrategy(),
    'market_maker': () => MarketMakerStrategy(),
    'mean_reversion_v2': () => BollingerRSIStrategy(), // Compatibility
    'ghost_trend_v1': () => GhostTrendStrategy(), // Compatibility
    'arbitrage_v1': () => ArbitrageStrategy(), // Compatibility
    'scalper_v1': () => ScalperStrategy(), // Compatibility
    'market_maker_v1': () => MarketMakerStrategy(), // Compatibility
  };

  // Day 28: Store metadata for published strategies
  static final Map<String, StrategyMetadata> _customMetadata = {};

  List<StrategyMetadata> get allStrategies => getAllMetadata();

  void publish(StrategyMetadata metadata) {
    // Register a dummy factory for the published strategy so it appears in the registry
    // In a real app, this would involve uploading code or linking to a dynamic module
    if (!exists(metadata.id)) {
      registerCustom(
          metadata.id, () => _createPublishedStrategyPlaceholder(metadata));
      _customMetadata[metadata.id] = metadata;
    }
    notifyListeners();
  }

  /// Stand-in for a published strategy whose rules this build does not have.
  ///
  /// This used to return a BollingerRSIStrategy for *every* published entry.
  /// Running any published strategy therefore executed Bollinger+RSI while
  /// the screen showed the published strategy's name, and the resulting
  /// trades and backtest figures were attributed to rules that never ran.
  /// Quietly substituting different logic is worse than admitting there is
  /// none, so it now returns a strategy that takes no trades and says why.
  Strategy _createPublishedStrategyPlaceholder(StrategyMetadata meta) {
    return UnavailableStrategy(id: meta.id, name: meta.name);
  }

  void clear() {
    _strategies.clear();
    _customMetadata.clear();
    notifyListeners();
  }

  StrategyMetadata? getStrategy(String id) => getMetadata(id);

  List<StrategyMetadata> getByTag(String tag) {
    return allStrategies.where((s) => s.tags.contains(tag)).toList();
  }

  void remove(String id) {
    unregisterCustom(id);
  }

  /// Get list of all available strategy IDs
  static List<String> get allStrategyIds => _strategies.keys.toList();

  /// Get list of enabled strategy IDs (can be filtered by settings)
  static List<String> getEnabledStrategies({
    List<String>? filter,
  }) {
    if (filter == null) return allStrategyIds;
    return allStrategyIds.where((id) => filter.contains(id)).toList();
  }

  /// Create a strategy instance by ID
  static Strategy create(String id) {
    final factory = _strategies[id];

    if (factory == null) {
      throw StrategyNotFoundException(
        'Strategy "$id" not found in registry. '
        'Available: ${allStrategyIds.join(", ")}',
      );
    }

    try {
      return factory();
    } catch (e) {
      throw StrategyCreationException(
        'Failed to create strategy "$id": $e',
      );
    }
  }

  /// Check if a strategy exists
  static bool exists(String id) {
    return _strategies.containsKey(id);
  }

  /// Get metadata for a strategy
  static StrategyMetadata? getMetadata(String id) {
    if (!exists(id)) return null;

    // Check custom metadata first
    if (_customMetadata.containsKey(id)) {
      return _customMetadata[id];
    }

    try {
      final strategy = create(id);
      // Constructing the complex StrategyMetadata from the app's existing model
      return StrategyMetadata(
        id: id,
        name: strategy.name,
        description: strategy.description,
        author: 'Volex Core',
        version: '1.0.0',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: _getTagsForStrategy(id),
        riskProfile: _assessRiskProfile(id),
        timeframe: _assessTimeframe(id),
        supportedSymbols: ['BTCUSDT', 'ETHUSDT'],
        parameters: strategy.parameters,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all strategy metadata
  static List<StrategyMetadata> getAllMetadata() {
    return allStrategyIds
        .map((id) => getMetadata(id))
        .whereType<StrategyMetadata>()
        .toList();
  }

  /// Register a custom strategy (for user-defined strategies)
  static void registerCustom(String id, StrategyFactory factory) {
    if (exists(id)) {
      throw StrategyRegistrationException(
        'Strategy "$id" already exists. Use a different ID.',
      );
    }

    _strategies[id] = factory;
    _instance.notifyListeners();
    AppLogger.info('✅ Custom strategy registered: $id');
  }

  /// Unregister a custom strategy
  static void unregisterCustom(String id) {
    if (!exists(id)) {
      throw StrategyNotFoundException('Strategy "$id" not found');
    }

    _strategies.remove(id);
    _instance.notifyListeners();
    AppLogger.info('♻️ Strategy unregistered: $id');
  }

  /// Validate all strategies (for testing)
  static Map<String, StrategyValidationResult> validateAll() {
    final results = <String, StrategyValidationResult>{};

    for (final id in allStrategyIds) {
      try {
        final strategy = create(id);

        // Basic validation
        final errors = <String>[];

        if (strategy.name.isEmpty) {
          errors.add('Strategy name is empty');
        }

        if (strategy.description.isEmpty) {
          errors.add('Strategy description is empty');
        }

        results[id] = StrategyValidationResult(
          id: id,
          valid: errors.isEmpty,
          errors: errors,
        );
      } catch (e) {
        results[id] = StrategyValidationResult(
          id: id,
          valid: false,
          errors: ['Failed to instantiate: $e'],
        );
      }
    }

    return results;
  }

  // Internal Helper methods for Metadata generation
  static List<String> _getTagsForStrategy(String id) {
    if (id.contains('trend')) return ['TREND', 'MOMENTUM'];
    if (id.contains('arbitrage')) return ['ARBITRAGE', 'LOW_RISK'];
    if (id.contains('scalp')) return ['SCALPING', 'HIGH_FREQ'];
    if (id.contains('market_maker')) return ['HFT', 'LIQUIDITY'];
    return ['MEAN_REVERSION', 'ALPHA'];
  }

  static RiskProfile _assessRiskProfile(String id) {
    if (id.contains('arbitrage')) return RiskProfile.low;
    if (id.contains('scalp')) return RiskProfile.extreme;
    return RiskProfile.medium;
  }

  static StrategyTimeframe _assessTimeframe(String id) {
    if (id.contains('scalp')) return StrategyTimeframe.scalping;
    if (id.contains('trend')) return StrategyTimeframe.swingTrading;
    return StrategyTimeframe.dayTrading;
  }
}

/// Factory function type for creating strategies
typedef StrategyFactory = Strategy Function();

/// Strategy validation result
class StrategyValidationResult {
  final String id;
  final bool valid;
  final List<String> errors;

  StrategyValidationResult({
    required this.id,
    required this.valid,
    required this.errors,
  });

  @override
  String toString() {
    if (valid) return '✅ $id: Valid';
    return '❌ $id: ${errors.join(", ")}';
  }
}

/// Exceptions
class StrategyNotFoundException implements Exception {
  final String message;
  StrategyNotFoundException(this.message);

  @override
  String toString() => 'StrategyNotFoundException: $message';
}

class StrategyCreationException implements Exception {
  final String message;
  StrategyCreationException(this.message);

  @override
  String toString() => 'StrategyCreationException: $message';
}

class StrategyRegistrationException implements Exception {
  final String message;
  StrategyRegistrationException(this.message);

  @override
  String toString() => 'StrategyRegistrationException: $message';
}
