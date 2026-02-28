/*
import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../domain/price_alert.dart';

import '../core/app_logger.dart';

/// Entry point for the background service
Future<void> initializeBackgroundMonitor() async {
  // final service = FlutterBackgroundService();

  // Android Notification Setup for "Foreground Service" persistent notif
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'monitor_service', // id
    'Market Monitor', // title
    description: 'Running in background to check price alerts',
    importance: Importance.low, // vital: low importance prevents sound loop
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart,
  //     autoStart: true,
  //     isForegroundMode: true,
  //     notificationChannelId: 'monitor_service',
  //     initialNotificationTitle: 'Volex Terminal Active',
  //     initialNotificationContent: 'Monitoring market prices...',
  //     foregroundServiceNotificationId: 888,
  //   ),
  //   iosConfiguration: IosConfiguration(
  //     autoStart: true,
  //     onForeground: onStart,
  //     onBackground: onIosBackground,
  //   ),
  // );
}

@pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
Future<bool> onIosBackground(dynamic service) async {
  // iOS Background Fetch (limited execution time)
  return true;
}

@pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
void onStart(dynamic service) async {
  // 1. Initialize Notifications
  final notifs = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await notifs.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings));

  // 2. Start Loop
  Timer.periodic(const Duration(seconds: 60), (timer) async {
    // if (service is AndroidServiceInstance) {
    //   if (await service.isForegroundService()) {
    //     service.setForegroundNotificationInfo(
    //       title: "Volex Terminal Active",
    //       content:
    //           "Last check: ${DateTime.now().hour}:${DateTime.now().minute}",
    //     );
    //   }
    // }

    try {
      await _checkAlerts(notifs);
    } catch (e) {
      AppLogger.error("[BgMonitor] Error: $e");
    }
  });
}

Future<void> _checkAlerts(FlutterLocalNotificationsPlugin notifs) async {
  // 1. Load Alerts
  final prefs = await SharedPreferences.getInstance();
  final jsonList = prefs.getStringList('alerts_v1') ?? [];

  if (jsonList.isEmpty) return;

  final List<PriceAlert> alerts = [];
  for (final raw in jsonList) {
    try {
      final parts = raw.split('|');
      if (parts.length >= 5) {
        alerts.add(PriceAlert(
          id: parts[0],
          symbol: parts[1],
          targetPrice: double.parse(parts[2]),
          type: parts[3] == 'crossesAbove'
              ? AlertType.crossesAbove
              : AlertType.crossesBelow,
          isActive: parts[4] == 'true',
        ));
      }
    } catch (_) {}
  }

  // 2. Group by Symbol to batch fetch
  final symbols = alerts.where((a) => a.isActive).map((a) => a.symbol).toSet();
  if (symbols.isEmpty) return;

  // 3. Fetch Prices (Binance Public API)
  for (final symbol in symbols) {
    // Basic mapping: BTC -> BTCUSDT
    final pair =
        symbol.toUpperCase().endsWith('USDT') ? symbol : '${symbol}USDT';
    try {
      final url =
          Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$pair');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double price = double.parse(data['price']);

        // 4. Check & Trigger
        bool stateChanged = false;
        for (final alert
            in alerts.where((a) => a.symbol == symbol && a.isActive)) {
          if (alert.check(price)) {
            await _showNotification(notifs, alert, price);
            // Mark inactive locally
            alert.isActive = false;
            stateChanged = true;
          }
        }

        // 5. Save State back
        if (stateChanged) {
          final newJsonList = alerts
              .map((a) =>
                  '${a.id}|${a.symbol}|${a.targetPrice}|${a.type.name}|${a.isActive}')
              .toList();
          await prefs.setStringList('alerts_v1', newJsonList);
        }
      }
    } catch (e) {
      AppLogger.error("Check failed for $symbol: $e");
    }
  }
}

Future<void> _showNotification(FlutterLocalNotificationsPlugin notifs,
    PriceAlert alert, double price) async {
  const androidDetails = AndroidNotificationDetails(
    'price_alerts',
    'Price Alerts',
    channelDescription: 'Specific price targets',
    importance: Importance.max,
    priority: Priority.high,
    // sound: RawResourceAndroidNotificationSound('alert_tone'), // Removed: resource missing
  );
  const details = NotificationDetails(android: androidDetails);

  await notifs.show(
    alert.hashCode,
    "🚀 TARGET HIT: ${alert.symbol}",
    "${alert.symbol} hit ${alert.targetPrice} (Now: $price)",
    details,
  );
}
*/

// Stub to satisfy main.dart import if any other file imports it (though I removed it from main)
// But best to leave an empty function for safety if I missed a spot.
Future<void> initializeBackgroundMonitor() async {
  // No-op for isolation
}
