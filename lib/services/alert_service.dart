import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [NEW]
import '../domain/price_alert.dart';
import '../domain/candle_model.dart'; // To listen to price updates
import '../core/app_logger.dart';

class AlertService extends ChangeNotifier {
  // final FlutterLocalNotificationsPlugin _notifications =
  //     FlutterLocalNotificationsPlugin();

  final List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => List.unmodifiable(_alerts);

  AlertService() {
    _initNotifications();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('alerts_v1') ?? [];
    _alerts.clear();
    for (final raw in jsonList) {
      try {
        final parts = raw.split('|');
        if (parts.length >= 5) {
          _alerts.add(PriceAlert(
            id: parts[0],
            symbol: parts[1],
            targetPrice: double.parse(parts[2]),
            type: parts[3] == 'crossesAbove'
                ? AlertType.crossesAbove
                : AlertType.crossesBelow,
            isActive: parts[4] == 'true',
          ));
        }
      } catch (e) {
        AppLogger.error("Failed to load alert: $e");
      }
    }
    notifyListeners();
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    // Manual serialization to basic JSON string
    final jsonList = _alerts
        .map((a) =>
            '${a.id}|${a.symbol}|${a.targetPrice}|${a.type.name}|${a.isActive}')
        .toList();
    await prefs.setStringList('alerts_v1', jsonList);
  }

  Future<void> _initNotifications() async {
    // const androidSettings =
    //     AndroidInitializationSettings('@mipmap/ic_launcher');
    // const iosSettings = DarwinInitializationSettings();
    // const settings =
    //     InitializationSettings(android: androidSettings, iOS: iosSettings);
    //
    // await _notifications.initialize(settings);
  }

  void addAlert(PriceAlert alert) {
    _alerts.add(alert);
    _saveAlerts(); // [NEW] Save
    notifyListeners();
    AppLogger.info(
        "ALERT: Added ${alert.symbol} ${alert.type.name} ${alert.targetPrice}");
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    _saveAlerts(); // [NEW] Save
    notifyListeners();
  }

  /// Called whenever a new candle/tick is received from the repository
  void onPriceUpdate(Candle candle) {
    // We check against candle.close which acts as "current price"
    for (final alert in _alerts) {
      if (alert.isActive && alert.check(candle.close)) {
        _triggerNotification(alert, candle.close);
        _saveAlerts(); // [NEW] Persist the inactive state
        notifyListeners(); // Update UI (inactive state)
      }
    }
  }

  Future<void> _triggerNotification(PriceAlert alert, double price) async {
    AppLogger.info("ALERT TRIGGERED: ${alert.symbol} hit ${alert.targetPrice}");

    // const androidDetails = AndroidNotificationDetails(
    //   'price_alerts',
    //   'Price Alerts',
    //   channelDescription: 'Notifications for price targets',
    //   importance: Importance.max,
    //   priority: Priority.high,
    // );
    // const details = NotificationDetails(android: androidDetails);
    //
    // await _notifications.show(
    //   alert.hashCode,
    //   title,
    //   body,
    //   details,
    // );
  }
}
