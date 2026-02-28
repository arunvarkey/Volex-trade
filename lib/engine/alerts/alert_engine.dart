import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/app_logger.dart';
import 'alert_models.dart';
import 'alert_repository.dart';
import '../../core/app_router.dart';
import '../../engine/services/notification_service.dart';

/// Core alert engine - monitors prices and triggers alerts
class AlertEngine extends ChangeNotifier {
  final AlertRepository _repository;
  final NotificationService _notifications;

  // Market data stream (to be injected)
  Stream<Map<String, double>>? _priceStream;
  StreamSubscription<Map<String, double>>? _priceSubscription;

  // Active alerts grouped by symbol for O(1) lookup
  Map<String, List<PriceAlert>> _activeAlertsBySymbol = {};

  // Debouncing to prevent spam
  final Map<String, DateTime> _lastTriggerTime = {};
  static const Duration _triggerCooldown = Duration(seconds: 5);

  // State
  bool _isRunning = false;
  int _evaluationCount = 0;

  AlertEngine({
    required AlertRepository repository,
    required NotificationService notifications,
  })  : _repository = repository,
        _notifications = notifications;

  // ===== Getters =====

  bool get isRunning => _isRunning;
  int get evaluationCount => _evaluationCount;
  int get activeAlertCount => _activeAlertsBySymbol.values
      .fold<int>(0, (sum, list) => sum + list.length);

  // ===== Lifecycle =====

  /// Start the alert engine
  Future<void> start(Stream<Map<String, double>> priceStream) async {
    if (_isRunning) return;

    AppLogger.info('AlertEngine: Starting...');

    _priceStream = priceStream;
    await _loadActiveAlerts();

    // Subscribe to price updates
    _priceSubscription = _priceStream!.listen(
      _onPriceUpdate,
      onError: (error) {
        AppLogger.error('AlertEngine: Price stream error', error);
      },
    );

    _isRunning = true;
    notifyListeners();

    AppLogger.info('AlertEngine: Started with $activeAlertCount active alerts');
  }

  /// Stop the alert engine
  Future<void> stop() async {
    if (!_isRunning) return;

    AppLogger.info('AlertEngine: Stopping...');

    await _priceSubscription?.cancel();
    _priceSubscription = null;
    _isRunning = false;

    notifyListeners();
    AppLogger.info('AlertEngine: Stopped');
  }

  // ===== Alert Management =====

  /// Create a new alert
  Future<void> createAlert(PriceAlert alert) async {
    AppLogger.info('Creating alert: ${alert.description}');

    await _repository.save(alert);

    // Add to active map if should evaluate
    if (alert.shouldEvaluate) {
      _activeAlertsBySymbol.putIfAbsent(alert.symbol, () => []).add(alert);
    }

    notifyListeners();
    _notifications.showSuccess('Alert created: ${alert.description}');
  }

  /// Cancel (delete) an alert
  Future<void> cancelAlert(String id) async {
    final alerts = await _repository.getAll();
    final alert = alerts.firstWhere((a) => a.id == id,
        orElse: () => throw Exception('Alert not found'));

    AppLogger.info('Canceling alert: ${alert.description}');

    await _repository.delete(id);

    // Remove from active map
    _activeAlertsBySymbol[alert.symbol]?.removeWhere((a) => a.id == id);
    if (_activeAlertsBySymbol[alert.symbol]?.isEmpty ?? false) {
      _activeAlertsBySymbol.remove(alert.symbol);
    }

    notifyListeners();
    _notifications.showToast('Alert canceled');
  }

  /// Toggle alert active state
  Future<void> toggleAlert(String id) async {
    final alerts = await _repository.getAll();
    final alert = alerts.firstWhere((a) => a.id == id);

    final updated = alert.copyWith(isActive: !alert.isActive);
    await _repository.update(id, updated);

    // Update active map
    if (updated.shouldEvaluate) {
      _activeAlertsBySymbol.putIfAbsent(updated.symbol, () => []).add(updated);
    } else {
      _activeAlertsBySymbol[updated.symbol]?.removeWhere((a) => a.id == id);
    }

    notifyListeners();
  }

  /// Reload all active alerts from repository
  Future<void> reloadAlerts() async {
    await _loadActiveAlerts();
    notifyListeners();
  }

  // ===== Core Logic =====

  /// Handle price updates
  void _onPriceUpdate(Map<String, double> prices) {
    _evaluationCount++;

    // Only evaluate symbols we have alerts for
    for (final entry in prices.entries) {
      final symbol = entry.key;
      final price = entry.value;

      final alerts = _activeAlertsBySymbol[symbol];
      if (alerts == null || alerts.isEmpty) continue;

      _evaluateAlertsForSymbol(symbol, price, alerts);
    }
  }

  /// Evaluate all alerts for a specific symbol
  void _evaluateAlertsForSymbol(
    String symbol,
    double currentPrice,
    List<PriceAlert> alerts,
  ) {
    final triggeredAlerts = <PriceAlert>[];

    for (final alert in alerts) {
      if (!alert.shouldEvaluate) continue;

      // Check if condition is met
      if (alert.condition.evaluate(currentPrice, alert.targetPrice)) {
        // Check cooldown to prevent spam
        if (_shouldTrigger(alert.id)) {
          _triggerAlert(alert, currentPrice);
          triggeredAlerts.add(alert);
        }
      }
    }

    // Remove triggered alerts from active map
    if (triggeredAlerts.isNotEmpty) {
      _activeAlertsBySymbol[symbol]?.removeWhere(
        (a) => triggeredAlerts.contains(a),
      );

      if (_activeAlertsBySymbol[symbol]?.isEmpty ?? false) {
        _activeAlertsBySymbol.remove(symbol);
      }
    }
  }

  /// Check if alert should trigger (respects cooldown)
  bool _shouldTrigger(String alertId) {
    final lastTrigger = _lastTriggerTime[alertId];
    if (lastTrigger == null) return true;

    final elapsed = DateTime.now().difference(lastTrigger);
    return elapsed >= _triggerCooldown;
  }

  /// Trigger an alert
  void _triggerAlert(PriceAlert alert, double currentPrice) {
    AppLogger.warning(
        'ALERT TRIGGERED: ${alert.description} at \$${currentPrice.toStringAsFixed(2)}');

    // 1. Update last trigger time
    _lastTriggerTime[alert.id] = DateTime.now();

    // 2. Show notification
    _notifications.showPriceAlert(
      symbol: alert.symbol,
      condition: alert.condition.label,
      targetPrice: alert.targetPrice,
      currentPrice: currentPrice,
      onTap: () {
        appRouter.push('/chart?symbol=${alert.symbol}');
      },
    );

    // 3. Update alert state in repository
    final updated = alert.copyWith(
      hasTriggered: true,
      isActive: false,
      triggeredAt: DateTime.now(),
    );
    _repository.update(alert.id, updated);

    // 4. Save trigger event
    final event = AlertTriggerEvent(
      alertId: alert.id,
      symbol: alert.symbol,
      targetPrice: alert.targetPrice,
      actualPrice: currentPrice,
      condition: alert.condition,
    );
    _repository.saveEvent(event);

    notifyListeners();
  }

  // ===== Helpers =====

  /// Load active alerts from repository into memory
  Future<void> _loadActiveAlerts() async {
    _activeAlertsBySymbol = await _repository.getActiveBySymbol();
    AppLogger.info('Loaded $activeAlertCount active alerts');
  }

  /// Get all alerts (for UI)
  Future<List<PriceAlert>> getAllAlerts() => _repository.getAll();

  /// Get active alerts (for UI)
  Future<List<PriceAlert>> getActiveAlerts() => _repository.getActive();

  /// Get triggered alerts (for UI)
  Future<List<PriceAlert>> getTriggeredAlerts() => _repository.getTriggered();

  /// Get alerts for a symbol (for UI)
  Future<List<PriceAlert>> getAlertsForSymbol(String symbol) =>
      _repository.getForSymbol(symbol);

  /// Get statistics (for UI)
  Future<AlertStats> getStats() => _repository.getStats();

  /// Get trigger events (for UI)
  Future<List<AlertTriggerEvent>> getEvents() => _repository.getEvents();

  /// Clean up old alerts
  Future<void> cleanup() async {
    await _repository.cleanupOldAlerts();
    await reloadAlerts();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Mock price stream for testing
Stream<Map<String, double>> createMockPriceStream() async* {
  var btcPrice = 43250.0;
  var ethPrice = 2280.0;

  while (true) {
    await Future.delayed(const Duration(seconds: 1));

    // Simulate price movements
    btcPrice += (btcPrice * 0.001) * (DateTime.now().second % 2 == 0 ? 1 : -1);
    ethPrice += (ethPrice * 0.001) * (DateTime.now().second % 3 == 0 ? 1 : -1);

    yield {
      'BTC/USDT': btcPrice,
      'ETH/USDT': ethPrice,
      'SOL/USDT': 98.30,
    };
  }
}
