import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:volex_terminal/core/app_logger.dart';

class NotificationService {
  static const platform = MethodChannel('com.antigravity.volextrade/native');
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _tzReady = false;

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

    // The timezone database has to exist before anything can be scheduled.
    // Cheap, and doing it here means callers never have to think about it.
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }

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

  // ── Scheduling ────────────────────────────────────────────────────

  /// Reminders live on their own channel so a user can silence the daily
  /// nudge in Android settings without losing anything else the app sends.
  /// Burying both in one channel makes "turn this off" mean "turn all of it
  /// off", which is how apps earn a permanent denial.
  static const AndroidNotificationDetails _reminderChannel =
      AndroidNotificationDetails(
    'volex_daily_reminder',
    'Daily reminder',
    channelDescription: 'A once-a-day nudge to play Volex Daily.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  /// Schedules a one-shot notification for [when] (device local time).
  ///
  /// Returns false if the time has already passed or the platform refuses —
  /// scheduling is best-effort and must never throw into a caller that is
  /// mid-startup.
  static Future<bool> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return false;
    if (!when.isAfter(DateTime.now())) return false;

    try {
      if (!_tzReady) {
        tzdata.initializeTimeZones();
        _tzReady = true;
      }

      // Convert the local wall-clock time to an absolute UTC instant and
      // schedule that. The alternative — setting tz.local from the device's
      // zone name — needs another plugin, and the only thing it would buy is
      // correctness across a DST change. Reminders are rescheduled every time
      // the app opens, so a shift can survive at most one cycle.
      final instant = tz.TZDateTime.from(when.toUtc(), tz.UTC);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        instant,
        const NotificationDetails(android: _reminderChannel),
        // Deliberately inexact. exactAllowWhileIdle needs SCHEDULE_EXACT_ALARM,
        // which Play restricts to alarm and calendar apps and which would put
        // a declaration form between us and every release. A reminder that
        // arrives within the hour is a reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Still required at this plugin version. absoluteTime, not
        // wallClockTime, because [instant] is already a fixed UTC moment
        // converted from the user's local time above — asking the platform to
        // reinterpret it as a wall clock would shift it by the offset twice.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return true;
    } catch (e) {
      AppLogger.warning('Could not schedule notification $id: $e');
      return false;
    }
  }

  /// Cancels a previously scheduled notification. Safe to call for an id that
  /// was never scheduled.
  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    try {
      await _notifications.cancel(id);
    } catch (e) {
      AppLogger.warning('Could not cancel notification $id: $e');
    }
  }

  /// Whether the user has actually granted notification permission.
  ///
  /// Distinct from having asked: on Android 13+ a denial is sticky, and
  /// scheduling into a denied permission silently does nothing. Callers that
  /// promise the user a reminder need to know which it is.
  static Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }
}
