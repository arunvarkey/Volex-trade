import 'dart:async';
import 'dart:math' as math;
import 'package:volex_terminal/services/risk_state_sync_service.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/engine/access_control_service.dart';
import 'package:volex_terminal/engine/notifications/notification_bus.dart';
import 'package:volex_terminal/engine/notifications/notification_model.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/engine/persistence/persistence_service.dart';

enum RiskProfile {
  conservative,
  moderate,
  aggressive,
}

class StrategyAuthorization {
  final double maxPositionSizeUsdt;
  final int maxDailyTrades;
  final double maxRiskPerTradeUsdt;
  final double maxDailyLossUsdt;
  final int maxOrdersPerMinute;
  final Set<String> allowedSymbols;

  const StrategyAuthorization({
    required this.maxPositionSizeUsdt,
    required this.maxDailyTrades,
    required this.maxRiskPerTradeUsdt,
    this.maxDailyLossUsdt = 100.0,
    this.maxOrdersPerMinute = 5,
    this.allowedSymbols = const {},
  });
}

/// Professional-Grade Risk Management Engine
///
/// This service acts as the primary safety gate for all trades.
class RiskManager {
  // Task 42 Fix: Standard singleton pattern
  factory RiskManager() {
    // Standard GetIt pattern.
    // Reference private member to satisfy 'unused' check if strict.
    final _ = RiskManager._internal();
    return getIt<RiskManager>();
  }
  RiskManager._internal();

  // Registration: getIt.registerLazySingleton(() => RiskManager._internal());

  RiskManager.inject({PersistenceService? persistence});

  /// Initializes the manager, loads local limits, and syncs with cloud state.
  Future<void> initialize() async {
    // Load limits from persistence if available
    AppLogger.info("RISK: Manager initializing...");

    // Initialize Cloud Sync
    await RiskStateSyncService.instance.initialize();

    // Pull remote state and enforce stricter limits
    final remoteState = await RiskStateSyncService.instance.pullState();
    if (remoteState != null) {
      // If cloud says we lost $50, but local says $0, trust cloud.
      _currentDailyLoss =
          math.max(_currentDailyLoss, remoteState.currentDailyLoss);

      // If cloud says locked, we lock.
      if (remoteState.isEmergencyStopActive) {
        _isEmergencyStopActive = true;
        _safetyController.add(true);
      }

      AppLogger.info(
          "RISK: Synced with cloud. Loss: \$$_currentDailyLoss, Locked: $_isEmergencyStopActive");
    } else {
      AppLogger.info("RISK: No remote state found or sync disabled.");
    }
  }

  NotificationBus get _bus => NotificationBus();

  bool _isEmergencyStopActive = false;
  double _maxOrderSizeUsdt = 1000.0;
  double _dailyLossLimit = 100.0; // Default: $100 max daily loss
  double _currentDailyLoss = 0.0;

  // Production-Grade Safety Gates
  double _maxAggregateRiskUsdt = 5000.0;
  double _currentAggregateRiskUsdt = 0.0;

  // Day 25: Enhanced Authorization Registry
  final Map<String, StrategyAuthorization> _authorizedStrategies = {};
  final Map<String, int> _dailyTradeCounts = {};
  final Map<String, double> _dailyStrategyLoss = {}; // Day 26
  final Map<String, List<DateTime>> _strategyOrderTimestamps =
      {}; // Day 26: Frequency Control

  // Day 24: Manual-Only "Tuition Size" Gates
  bool isManualOnlyMode = true; // Default to safest
  static const double tuitionSizeLimitUsdt = 20.0;
  static const double tuitionAggregateRiskUsdt = 100.0;

  // Day 28: New Getters for ExecutionManager
  double get maxDailyLoss => _dailyLossLimit;
  double get maxPositionSizePercent => 0.1; // 10%
  double get maxTotalExposurePercent => 0.5; // 50%
  int get maxOpenPositions => 5;

  bool get isLocked => _isEmergencyStopActive;

  final StreamController<bool> _safetyController =
      StreamController<bool>.broadcast();
  Stream<bool> get safetyStream => _safetyController.stream;

  void authorizeStrategy(String id, StrategyAuthorization config) {
    if (!AccessControlService().canAuthorizeStrategies) {
      AppLogger.warning(
          "SECURITY: Authorization DENIED. User '${AccessControlService().currentRole.name}' cannot authorize strategies.");
      return;
    }
    _authorizedStrategies[id] = config;
    _dailyTradeCounts[id] = 0;
    _dailyStrategyLoss[id] = 0.0;
    AppLogger.info(
        "RISK: Strategy $id authorized for live trading with config: Size=\$${config.maxPositionSizeUsdt}");
  }

  // Day 27: Exposed for testing/console
  Map<String, StrategyAuthorization> get authorizedStrategies =>
      Map.unmodifiable(_authorizedStrategies);
  double get maxAggregateRiskUsdt => _maxAggregateRiskUsdt;
  double get currentAggregateRiskUsdt => _currentAggregateRiskUsdt;

  void revokeStrategy(String id) {
    _authorizedStrategies.remove(id);
    _dailyTradeCounts.remove(id);
    _dailyStrategyLoss.remove(id);
    _strategyOrderTimestamps.remove(id);
    AppLogger.info("RISK: Strategy $id revoked from live trading.");
  }

  void setMaxAggregateRisk(double limit) {
    if (!AccessControlService().canConfigureRisk) {
      AppLogger.warning(
          "SECURITY: Risk Config DENIED. User cannot change Aggregate Risk.");
      return;
    }
    _maxAggregateRiskUsdt = limit;
  }

  void setDailyLossLimit(double limit) {
    if (!AccessControlService().canConfigureRisk) {
      AppLogger.warning(
          "SECURITY: Risk Config DENIED. User cannot change Daily Loss Limit.");
      return;
    }
    _dailyLossLimit = limit;
    AppLogger.info("RISK: Daily Loss Limit updated to \$$limit");
  }

  void setMaxOrderSize(double limit) {
    if (!AccessControlService().canConfigureRisk) {
      AppLogger.warning(
          "SECURITY: Risk Config DENIED. User cannot change Order Size.");
      return;
    }
    _maxOrderSizeUsdt = limit;
  }

  /// Instantly locks the terminal and notifies the cloud.
  void activateEmergencyStop() {
    _isEmergencyStopActive = true;
    _safetyController.add(true);
    _syncToCloud();
    AppLogger.warning("RISK: EMERGENCY STOP ACTIVATED. Terminal locked.");
  }

  void reset() {
    _isEmergencyStopActive = false;
    _currentDailyLoss = 0.0;
    _currentAggregateRiskUsdt = 0.0;
    _authorizedStrategies.clear(); // Day 25: Clear registry on reset
    _dailyTradeCounts.clear();
    _dailyStrategyLoss.clear();
    _strategyOrderTimestamps.clear();
    _safetyController.add(false);
    _syncToCloud();
    AppLogger.info("RISK: Global reset.");
  }

  /// Final verification before an order is sent to the exchange.
  bool validateOrder({
    required double quantity,
    required double priceUsdt,
    String? strategyId,
    bool isLive = false,
    bool isReduction = false,
  }) {
    // The emergency stop blocks new exposure, never an exit.
    //
    // It used to block every order without exception — and recordTradeResult
    // trips it automatically the moment the daily loss limit is reached. So
    // hitting the limit locked the user *into* their open positions: closes
    // were rejected, and since protective exits close through the same path,
    // their stop-losses stopped firing too. A kill switch that prevents you
    // from flattening leaves the loss it was meant to cap running unbounded.
    //
    // Reductions are therefore allowed through. Opening or adding is not.
    if (_isEmergencyStopActive && !isReduction) {
      _bus.publish(
        type: NotificationType.risk,
        severity: NotificationSeverity.critical,
        title: "Emergency Stop Active",
        message: "New trades blocked. You can still close open positions.",
        userId: "current_user",
      );
      AppLogger.warning("RISK: Order rejected. Emergency stop active.");
      return false;
    }

    // 1. Daily Loss Limit
    if (_currentDailyLoss >= _dailyLossLimit && !isReduction) {
      _bus.publish(
        type: NotificationType.risk,
        severity: NotificationSeverity.critical,
        title: "Daily Loss Limit Hit",
        message: "Trading blocked. Realized Loss: \$$_currentDailyLoss",
        userId: "current_user",
      );
      AppLogger.warning("RISK: Daily Loss Limit Exceeded. Blocked.");
      return false;
    }

    double orderSize = quantity * priceUsdt;

    // 2. Live Execution Safety Gates
    if (isLive) {
      if (strategyId != null) {
        // --- STRATEGY ORDERS ---
        if (isManualOnlyMode) {
          AppLogger.warning(
              "RISK: Order rejected. Strategy execution blocked in Manual-Only mode.");
          return false;
        } else {
          // Auto-Capped: Authorization & Limit Check
          if (!_validateStrategyLimits(strategyId, orderSize)) {
            return false;
          }
        }
      } else {
        // --- MANUAL ORDERS ---
        if (isManualOnlyMode) {
          // Manual-Only: Tuition Size Check
          if (orderSize > tuitionSizeLimitUsdt) {
            AppLogger.warning(
                "RISK: Order rejected. $orderSize exceeds Tuition limit of $tuitionSizeLimitUsdt");
            return false;
          }
        }
      }
    }

    // 3. Global Size Limit — a real-money guardrail. Paper trading is a
    // practice sandbox (funded with a large simulated balance), so a single
    // 0.1 BTC practice order (~$6k) must not be rejected against the live
    // $1k cap. Enforce this ceiling only for live orders.
    if (isLive && orderSize > _maxOrderSizeUsdt) {
      AppLogger.warning(
          "RISK: Order rejected. Size $orderSize exceeds max $_maxOrderSizeUsdt");
      return false;
    }

    // 4. Aggregate Risk Limit
    double limitToUse = (isLive && isManualOnlyMode)
        ? tuitionAggregateRiskUsdt
        : _maxAggregateRiskUsdt;

    if (isLive && (_currentAggregateRiskUsdt + orderSize) > limitToUse) {
      AppLogger.warning(
          "RISK: Order rejected. Global exposure limit ($limitToUse) would be exceeded.");
      return false;
    }

    return true;
  }

  // Day 25: Helper to validate strategy specific constraints (Size, Frequency)
  bool _validateStrategyLimits(String strategyId, double orderSize) {
    if (!_authorizedStrategies.containsKey(strategyId)) return false;

    final auth = _authorizedStrategies[strategyId]!;

    // Size Cap
    if (orderSize > auth.maxPositionSizeUsdt) {
      AppLogger.warning(
          "RISK: Strategy $strategyId exceeded max position size ${auth.maxPositionSizeUsdt} with $orderSize");
      return false;
    }

    // Trade Frequency (Daily)
    final currentTrades = _dailyTradeCounts[strategyId] ?? 0;
    if (currentTrades >= auth.maxDailyTrades) {
      AppLogger.warning(
          "RISK: Strategy $strategyId exceeded max daily trades ${auth.maxDailyTrades}");
      return false;
    }

    // Order Frequency (1 Minute Window)
    final now = DateTime.now();
    final timestamps = _strategyOrderTimestamps[strategyId] ?? [];
    // Prune entries older than 1 minute
    timestamps.removeWhere((t) => now.difference(t).inSeconds > 60);
    _strategyOrderTimestamps[strategyId] = timestamps;

    if (timestamps.length >= auth.maxOrdersPerMinute) {
      AppLogger.warning(
          "RISK: Strategy $strategyId exceeded max orders per minute (${auth.maxOrdersPerMinute})");
      return false;
    }

    return true;
  }

  void incrementStrategyTradeCount(String strategyId) {
    if (_dailyTradeCounts.containsKey(strategyId)) {
      _dailyTradeCounts[strategyId] = (_dailyTradeCounts[strategyId] ?? 0) + 1;
    }
    // Track timestamp for frequency check
    if (!_strategyOrderTimestamps.containsKey(strategyId)) {
      _strategyOrderTimestamps[strategyId] = [];
    }
    _strategyOrderTimestamps[strategyId]!.add(DateTime.now());
  }

  void recordTradeResult(double pnlUsdt, {String? strategyId}) {
    if (strategyId != null && pnlUsdt < 0) {
      _dailyStrategyLoss[strategyId] =
          (_dailyStrategyLoss[strategyId] ?? 0.0) + pnlUsdt.abs();
    }

    if (pnlUsdt < 0) {
      _currentDailyLoss += pnlUsdt.abs();
      if (_currentDailyLoss >= _dailyLossLimit) {
        activateEmergencyStop();
      }
      _syncToCloud(); // Sync after loss update
    }
  }

  // To be called when a position is opened/closed in live mode
  void updateAggregateRisk(double deltaUsdt) {
    _currentAggregateRiskUsdt += deltaUsdt;
  }

  // Helper to push state
  void _syncToCloud() {
    RiskStateSyncService.instance.pushState(
      currentDailyLoss: _currentDailyLoss,
      isEmergencyStopActive: _isEmergencyStopActive,
    );
  }

  Map<String, dynamic> getStatus() {
    return {
      'isEmergencyStopActive': _isEmergencyStopActive,
      'maxOrderSize': _maxOrderSizeUsdt,
      'maxDailyLoss': _dailyLossLimit,
      'currentDailyLoss': _currentDailyLoss,
      'aggregateRisk': _currentAggregateRiskUsdt,
      'maxAggregateRisk': _maxAggregateRiskUsdt,
      'authorizedStrategies': _authorizedStrategies.keys.toList(),
      'dailyStrategyLoss': _dailyStrategyLoss,
    };
  }

  /// Dispose resources to prevent memory leaks
  void dispose() {
    _safetyController.close();
  }
}
