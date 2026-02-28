import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:volex_terminal/core/app_logger.dart';

class NotificationService {
  static const platform = MethodChannel('com.antigravity.volextrade/native');
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) {
      AppLogger.info('NOTIF: Skipping native initialization on Web.');
      return;
    }

    // Android-specific initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel via native code
    try {
      await platform.invokeMethod('createNotificationChannel');
    } catch (e) {
      AppLogger.error('Failed to create notification channel: $e');
    }

    // Request permission on Android 13+
    await requestNotificationPermission();
  }

  static Future<void> requestNotificationPermission() async {
    if (kIsWeb) return;
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();

      if (status.isDenied) {
        AppLogger.warning('Notification permission denied');
      }
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    AppLogger.info('Notification tapped: ${response.payload}');
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      AppLogger.info('NOTIF [WEB]: $title - $body');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'volex_trading_channel', // Must match CHANNEL_ID in MainActivity
      'Volex Trading Service',
      channelDescription:
          'Notifications for trading alerts and background operations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
