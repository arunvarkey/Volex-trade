import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/features/daily/services/daily_service.dart';
import 'package:volex_terminal/services/notification_service.dart';

/// Schedules the daily reminder.
///
/// ## What this is allowed to say
///
/// Every message here is about practice. None of them mentions price, a
/// market move, or a trade — and that constraint is the whole design, not a
/// stylistic preference.
///
/// A notification that says "BTC just moved 5%" is an instruction to open the
/// app and trade, and the Academy's own lesson on base rates is that trading
/// more makes retail outcomes worse. It would also put Volex in the exact
/// category regulators have been narrowing: FINRA's action against Robinhood
/// over gamification, and the FCA's restrictions on trading-app engagement
/// incentives. We hold no money and execute nothing, so the exposure is
/// smaller — but an app that pushes people toward trades on a schedule is the
/// shape of the problem regardless of who clears the order.
///
/// Nudging someone to answer five judgment questions has none of that. It is
/// repeatable daily without harm, which is precisely why it is the habit
/// worth building.
///
/// ## Why seven one-shots instead of a repeating schedule
///
/// A single repeating notification can only carry one fixed message. The two
/// cases worth distinguishing — a streak at risk tonight, and someone who has
/// drifted away — need different words, and the right words depend on state
/// that only exists at scheduling time. So this cancels and rewrites the next
/// seven days on every app open, which is also what keeps the wall-clock time
/// correct across a timezone or DST change.
class DailyReminderService {
  DailyReminderService._();
  static final DailyReminderService instance = DailyReminderService._();

  /// Notification ids are fixed so a reschedule replaces rather than stacks.
  /// Seven consecutive ids, one per day ahead.
  static const int _baseId = 7100;
  static const int _horizonDays = 7;

  static const String _kEnabled = 'daily_reminder_enabled_v1';
  static const String _kHour = 'daily_reminder_hour_v1';
  static const String _kMinute = 'daily_reminder_minute_v1';

  /// Early evening: after work for most people, late enough that "I'll do it
  /// later today" is still true, early enough not to be the last thing before
  /// sleep. A guess, and one the analytics can correct later.
  static const int defaultHour = 19;
  static const int defaultMinute = 0;

  bool _enabled = true;
  int _hour = defaultHour;
  int _minute = defaultMinute;
  bool _loaded = false;

  bool get isEnabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Defaults to on. The permission prompt is the real consent gate on
      // Android 13+, and a reminder nobody asked for that also never fires
      // because permission was denied is the worst of both.
      _enabled = prefs.getBool(_kEnabled) ?? true;
      _hour = prefs.getInt(_kHour) ?? defaultHour;
      _minute = prefs.getInt(_kMinute) ?? defaultMinute;
    } catch (_) {
      // Defaults stand.
    }
    _loaded = true;
  }

  Future<void> setEnabled({required bool enabled}) async {
    await ensureLoaded();
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, enabled);
    } catch (_) {
      // Non-fatal.
    }
    await reschedule();
  }

  Future<void> setTime({required int hour, required int minute}) async {
    await ensureLoaded();
    _hour = hour.clamp(0, 23);
    _minute = minute.clamp(0, 59);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kHour, _hour);
      await prefs.setInt(_kMinute, _minute);
    } catch (_) {
      // Non-fatal.
    }
    await reschedule();
  }

  /// Rebuilds the next [_horizonDays] reminders from current state.
  ///
  /// Safe to call often — it cancels the whole window first, so repeated
  /// calls cannot stack duplicates. Called on app resume and after the Daily
  /// is completed, which is when the answer changes.
  Future<void> reschedule({DateTime? now}) async {
    await ensureLoaded();

    // Always clear first, so disabling actually removes what is pending.
    for (var i = 0; i < _horizonDays; i++) {
      await NotificationService.cancel(_baseId + i);
    }
    if (!_enabled) return;

    if (!await NotificationService.hasPermission()) {
      // Nothing to do, and worth a line: a reminder that silently never
      // fires looks identical to a bug.
      AppLogger.info('Daily reminder: notification permission not granted');
      return;
    }

    final daily = DailyService.instance;
    await daily.ensureLoaded();

    final today = now ?? DateTime.now();
    final playedToday = daily.hasPlayedToday(now: today);
    final streak = daily.currentStreak;

    var scheduled = 0;
    for (var i = 0; i < _horizonDays; i++) {
      final date = DateTime(today.year, today.month, today.day + i,
          _hour, _minute);

      // Today's reminder is pointless if they have already played.
      if (i == 0 && playedToday) continue;
      if (!date.isAfter(today)) continue;

      final message = _messageFor(dayOffset: i, streak: streak);
      final ok = await NotificationService.scheduleAt(
        id: _baseId + i,
        when: date,
        title: message.$1,
        body: message.$2,
        payload: '/daily',
      );
      if (ok) scheduled++;
    }
    AppLogger.info('Daily reminder: scheduled $scheduled of $_horizonDays');
  }

  /// Exposed so a test can assert that no reminder ever mentions price, a
  /// market move or a trade. That rule is the difference between a learning
  /// nudge and a push to transact, and it is too easy to break by writing
  /// one well-meaning line of copy.
  @visibleForTesting
  (String, String) messageForTest({required int dayOffset, required int streak}) =>
      _messageFor(dayOffset: dayOffset, streak: streak);

  /// Title and body for the reminder [dayOffset] days from now.
  ///
  /// Three registers, chosen by how much the user has to lose:
  ///
  /// - a live streak gets the loss-aversion framing, because that is what
  ///   makes streaks work and there is nothing dishonest about it;
  /// - no streak gets a plain invitation;
  /// - further out, where we are guessing about someone who has not opened
  ///   the app in days, the tone drops to neutral. Escalating urgency at
  ///   somebody who has drifted away is how an app gets uninstalled rather
  ///   than reopened.
  (String, String) _messageFor({required int dayOffset, required int streak}) {
    if (dayOffset >= 3) {
      return (
        'Five questions, whenever you like',
        'No streak pressure — just a quick read on your trading judgment.',
      );
    }

    if (streak <= 0) {
      return (
        'Today\'s five calls are up',
        'Five judgment questions, about a minute. No trading required.',
      );
    }

    if (dayOffset == 0) {
      return (
        'Your $streak-day streak ends tonight',
        'Five questions is all it takes to keep it going.',
      );
    }

    return (
      'Volex Daily is ready',
      'Keep the $streak-day streak alive — five questions, one minute.',
    );
  }
}
