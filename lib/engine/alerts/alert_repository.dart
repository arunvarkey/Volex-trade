import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_models.dart';
import '../../core/app_logger.dart';

/// Repository for persisting price alerts
class AlertRepository {
  static const String _alertsKey = 'vx_price_alerts';
  static const String _eventsKey = 'vx_alert_events';

  final SharedPreferences _prefs;
  final _alertsController = StreamController<List<PriceAlert>>.broadcast();

  AlertRepository(this._prefs);

  /// Stream of all alerts (for UI reactivity)
  Stream<List<PriceAlert>> get alertsStream => _alertsController.stream;

  // ===== CRUD Operations =====

  /// Save a new alert
  Future<void> save(PriceAlert alert) async {
    final alerts = await getAll();
    alerts.add(alert);
    await _persist(alerts);
    _alertsController.add(alerts);
  }

  /// Update an existing alert
  Future<void> update(String id, PriceAlert alert) async {
    final alerts = await getAll();
    final index = alerts.indexWhere((a) => a.id == id);

    if (index != -1) {
      alerts[index] = alert;
      await _persist(alerts);
      _alertsController.add(alerts);
    }
  }

  /// Delete an alert
  Future<void> delete(String id) async {
    final alerts = await getAll();
    alerts.removeWhere((a) => a.id == id);
    await _persist(alerts);
    _alertsController.add(alerts);
  }

  /// Delete all alerts (clear all)
  Future<void> deleteAll() async {
    await _prefs.remove(_alertsKey);
    _alertsController.add([]);
  }

  // ===== Queries =====

  /// Get all alerts
  Future<List<PriceAlert>> getAll() async {
    final json = _prefs.getString(_alertsKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((item) => PriceAlert.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error loading alerts: $e');
      return [];
    }
  }

  /// Get only active alerts (not triggered, still enabled)
  Future<List<PriceAlert>> getActive() async {
    final all = await getAll();
    return all.where((a) => a.shouldEvaluate).toList();
  }

  /// Get alerts for a specific symbol
  Future<List<PriceAlert>> getForSymbol(String symbol) async {
    final all = await getAll();
    return all.where((a) => a.symbol == symbol).toList();
  }

  /// Get triggered alerts (history)
  Future<List<PriceAlert>> getTriggered() async {
    final all = await getAll();
    return all.where((a) => a.hasTriggered).toList();
  }

  // ===== Alert Events (Trigger History) =====

  /// Save an alert trigger event
  Future<void> saveEvent(AlertTriggerEvent event) async {
    final events = await getEvents();
    events.add(event);

    // Keep only last 100 events
    if (events.length > 100) {
      events.removeRange(0, events.length - 100);
    }

    await _persistEvents(events);
  }

  /// Get all trigger events
  Future<List<AlertTriggerEvent>> getEvents() async {
    final json = _prefs.getString(_eventsKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((item) =>
              AlertTriggerEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error loading alert events: $e');
      return [];
    }
  }

  /// Get events for a specific symbol
  Future<List<AlertTriggerEvent>> getEventsForSymbol(String symbol) async {
    final all = await getEvents();
    return all.where((e) => e.symbol == symbol).toList();
  }

  // ===== Utilities =====

  /// Group active alerts by symbol for efficient lookup
  Future<Map<String, List<PriceAlert>>> getActiveBySymbol() async {
    final active = await getActive();
    final Map<String, List<PriceAlert>> grouped = {};

    for (final alert in active) {
      grouped.putIfAbsent(alert.symbol, () => []).add(alert);
    }

    return grouped;
  }

  /// Get alert statistics
  Future<AlertStats> getStats() async {
    final all = await getAll();
    final active = all.where((a) => a.isActive && !a.hasTriggered).length;
    final triggered = all.where((a) => a.hasTriggered).length;
    final disabled = all.where((a) => !a.isActive && !a.hasTriggered).length;

    return AlertStats(
      total: all.length,
      active: active,
      triggered: triggered,
      disabled: disabled,
    );
  }

  // ===== Private Helpers =====

  Future<void> _persist(List<PriceAlert> alerts) async {
    final json = jsonEncode(alerts.map((a) => a.toJson()).toList());
    await _prefs.setString(_alertsKey, json);
  }

  Future<void> _persistEvents(List<AlertTriggerEvent> events) async {
    final json = jsonEncode(events.map((e) => e.toJson()).toList());
    await _prefs.setString(_eventsKey, json);
  }

  /// Clean up old triggered alerts (optional housekeeping)
  Future<void> cleanupOldAlerts(
      {Duration age = const Duration(days: 7)}) async {
    final all = await getAll();
    final cutoff = DateTime.now().subtract(age);

    final cleaned = all.where((a) {
      // Keep active alerts
      if (a.isActive && !a.hasTriggered) return true;

      // Keep recent triggered alerts
      if (a.hasTriggered && a.triggeredAt != null) {
        return a.triggeredAt!.isAfter(cutoff);
      }

      return false;
    }).toList();

    if (cleaned.length != all.length) {
      await _persist(cleaned);
      _alertsController.add(cleaned);
    }
  }

  void dispose() {
    _alertsController.close();
  }
}

/// Alert statistics summary
class AlertStats {
  final int total;
  final int active;
  final int triggered;
  final int disabled;

  AlertStats({
    required this.total,
    required this.active,
    required this.triggered,
    required this.disabled,
  });

  @override
  String toString() =>
      'AlertStats(total: $total, active: $active, triggered: $triggered, disabled: $disabled)';
}
