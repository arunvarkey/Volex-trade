import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/app_logger.dart';

/// Service interface for logging application events and user actions.
///
/// Wraps [FirebaseAnalytics] to provide a unified interface for tracking:
/// *   **User Behavior**: Screen views, clicks, interactions.
/// *   **Trading Activity**: Orders placed, strategies started/stopped (Anonymized).
/// *   **Performance Metrics**: Latency, errors (non-fatal).
///
/// **Usage:**
/// ```dart
/// AnalyticsService.instance.logEvent('trade_executed', parameters: {'symbol': 'BTCUSDT'});
/// ```
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  FirebaseAnalytics? _analytics;

  AnalyticsService._internal();

  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      AppLogger.info('Firebase Analytics Service Initialized');
      await _analytics?.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      AppLogger.error('Firebase Analytics Init failed (Non-fatal)', e);
      _analytics = null;
    }
  }

  /// Logs a custom event with optional parameters.
  ///
  /// Parameters are limited to 25 keys and string/number values.
  /// Events are batched and uploaded periodically to conserve battery.
  ///
  /// Example:
  /// ```dart
  /// logEvent('strategy_started', parameters: {'id': 'ghost_trend'});
  /// ```
  void logEvent(String name, {Map<String, Object>? parameters}) {
    AppLogger.debug('Event: $name ${parameters ?? ''}');
    try {
      _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      AppLogger.error('Event log failed', e);
    }
  }

  void setCurrentScreen(String screenName) {
    try {
      _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      AppLogger.error('Screen view log failed', e);
    }
  }
}
