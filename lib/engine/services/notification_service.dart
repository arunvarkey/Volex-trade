import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for showing notifications and feedback
class NotificationService {
  final GlobalKey<ScaffoldMessengerState>? scaffoldKey;
  // final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();

  NotificationService({this.scaffoldKey}) {
    // _initializeLocalNotifications();
  }

  // Future<void> _initializeLocalNotifications() async {
  //   const androidSettings =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const iosSettings = DarwinInitializationSettings();
  //   const initSettings =
  //       InitializationSettings(android: androidSettings, iOS: iosSettings);
  //
  //   await _localNotifications.initialize(
  //     initSettings,
  //     onDidReceiveNotificationResponse: (details) {
  //       // Handle tapping on notification
  //       AppLogger.debug("Notification tapped: ${details.payload}");
  //     },
  //   );
  // }

  // ===== System Notifications =====

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // const androidDetails = AndroidNotificationDetails(
    //   'volex_terminal_alerts',
    //   'Market Alerts',
    //   channelDescription: 'Real-time price and strategy alerts',
    //   importance: Importance.max,
    //   priority: Priority.high,
    //   showWhen: true,
    // );
    // const iosDetails = DarwinNotificationDetails();
    // const platformDetails =
    //     NotificationDetails(android: androidDetails, iOS: iosDetails);
    //
    // await _localNotifications.show(id, title, body, platformDetails,
    //     payload: payload);
  }

  // ===== Toast Notifications =====

  /// Show a simple toast message
  void showToast(
    String message, {
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color? backgroundColor,
    Color? textColor,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor ?? Colors.black87,
      textColor: textColor ?? Colors.white,
      fontSize: 14.0,
    );
  }

  /// Show success toast (green)
  void showSuccess(String message) {
    showToast(
      message,
      backgroundColor: const Color(0xFF00FF88),
      textColor: Colors.black,
    );
    HapticFeedback.mediumImpact();
  }

  /// Show error toast (red)
  void showError(String message) {
    showToast(
      message,
      backgroundColor: const Color(0xFFFF0055),
      textColor: Colors.white,
    );
    HapticFeedback.vibrate();
  }

  /// Show warning toast (orange)
  void showWarning(String message) {
    showToast(
      message,
      backgroundColor: const Color(0xFFFFAA00),
      textColor: Colors.black,
    );
    HapticFeedback.lightImpact();
  }

  // ===== SnackBar Notifications (In-App) =====

  /// Show a SnackBar with action
  void showSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
  }) {
    scaffoldKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show alert notification with icon
  void showAlertNotification({
    required String title,
    required String body,
    IconData icon = Icons.notifications_active,
    Color? color,
    VoidCallback? onTap,
  }) {
    scaffoldKey?.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFFFFAA00)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 6),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        action: onTap != null
            ? SnackBarAction(
                label: 'VIEW',
                textColor: color ?? const Color(0xFFFFAA00),
                onPressed: onTap,
              )
            : null,
      ),
    );

    HapticFeedback.heavyImpact();

    // Also show a local notification for visibility outside app
    showLocalNotification(
      id: title.hashCode,
      title: title,
      body: body,
    );
  }

  // ===== Price Alert Specific =====

  /// Show price alert notification
  void showPriceAlert({
    required String symbol,
    required String condition,
    required double targetPrice,
    required double currentPrice,
    VoidCallback? onTap,
  }) {
    final percentDiff =
        ((currentPrice - targetPrice) / targetPrice * 100).abs();

    showAlertNotification(
      title: '🔔 $symbol Alert Triggered',
      body: '$condition \$${targetPrice.toStringAsFixed(2)} '
          '(Curr: \$${currentPrice.toStringAsFixed(2)} | Error: ${percentDiff.toStringAsFixed(2)}%)',
      icon: Icons.notifications_active,
      color: const Color(0xFFFFAA00),
      onTap: onTap,
    );
  }

  // ===== Haptic Patterns =====

  void vibrateSuccess() {
    HapticFeedback.mediumImpact();
  }

  void vibrateError() {
    HapticFeedback.vibrate();
  }

  void vibrateWarning() {
    HapticFeedback.lightImpact();
  }

  void vibrateHeavy() {
    HapticFeedback.heavyImpact();
  }
}

/// Global notification service instance
/// Should be initialized in main() with scaffoldMessengerKey
late NotificationService notificationService;
