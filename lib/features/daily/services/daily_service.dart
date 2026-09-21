import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../academy/services/xp_service.dart';
import '../../../core/analytics/vx_funnel.dart';
import '../data/daily_question_bank.dart';
import '../models/daily_models.dart';

/// Drives Volex Daily: a deterministic daily challenge, streak tracking, and
/// results. Self-contained singleton backed by SharedPreferences (no DI), the
/// same pattern as the other feature services.
class DailyService extends ChangeNotifier {
  DailyService._();
  static final DailyService instance = DailyService._();

  /// Day 1 of Volex Daily — challenge numbers count from here.
  static final DateTime _epoch = DateTime(2026, 1, 1);
  static const int _callsPerDay = 5;

  static const String _kLastKey = 'daily_last_key_v1';
  static const String _kStreak = 'daily_streak_v1';
  static const String _kBest = 'daily_best_v1';
  static const String _kLastScore = 'daily_last_score_v1';
  static const String _kPlayed = 'daily_played_count_v1';

  /// Date key of the last day a freeze was spent, and the ISO week it was
  /// spent in. One freeze per calendar week.
  static const String _kFreezeUsedKey = 'daily_freeze_used_key_v1';
  static const String _kFreezeWeek = 'daily_freeze_week_v1';

  bool _loaded = false;
  String? _lastKey;
  int _streak = 0;
  int _best = 0;
  int _lastScore = 0;
  int _played = 0;
  String? _freezeUsedKey;
  int? _freezeWeek;

  bool get isLoaded => _loaded;
  int get currentStreak => _streak;
  int get bestStreak => _best;
  int get playedCount => _played;
  int get lastScore => _lastScore;

  /// The day a streak freeze covered for the user, if it has not been
  /// acknowledged yet. The UI reads this to tell them after the fact.
  String? get freezeUsedOn => _freezeUsedKey;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastKey = prefs.getString(_kLastKey);
      _streak = prefs.getInt(_kStreak) ?? 0;
      _best = prefs.getInt(_kBest) ?? 0;
      _lastScore = prefs.getInt(_kLastScore) ?? 0;
      _played = prefs.getInt(_kPlayed) ?? 0;
      _freezeUsedKey = prefs.getString(_kFreezeUsedKey);
      _freezeWeek = prefs.getInt(_kFreezeWeek);
    } catch (_) {
      // Start fresh if storage is unavailable.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  // ── Date helpers (pure, testable) ─────────────────────────────────

  /// yyyy-mm-dd in local time.
  static String dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// "Volex Daily #N" for a date (day 1 == the epoch).
  static int challengeNumber(DateTime d) {
    final a = DateTime(d.year, d.month, d.day);
    return a.difference(_epoch).inDays + 1;
  }

  // ── Challenge generation (deterministic) ──────────────────────────

  /// The challenge for [date] — the same five calls for everyone on that day.
  ///
  /// Days take consecutive, non-overlapping slices of the pool rather than a
  /// fresh random draw. A per-day shuffle looks correct and is not: each day
  /// samples independently, so with 5 draws from 300 the chance of a repeat
  /// within a week is high, and that repeat is what makes a streak feel
  /// pointless. Slicing guarantees no question returns until the whole pool
  /// has been seen — currently about two months.
  ///
  /// Once the pool is exhausted the cycle restarts, offset by one so the
  /// second pass does not reproduce the first pass's groupings.
  DailyChallenge challengeFor(DateTime date) {
    final number = challengeNumber(date);
    final pool = DailyQuestionBank.all;
    final take = min(_callsPerDay, pool.length);

    // Day 1 starts at index 0.
    final day = number - 1;
    final cycleLength = pool.length ~/ take;
    final cycle = cycleLength > 0 ? day ~/ cycleLength : 0;
    final dayInCycle = cycleLength > 0 ? day % cycleLength : 0;

    final start = (dayInCycle * take + cycle) % pool.length;
    final calls = [
      for (int i = 0; i < take; i++) pool[(start + i) % pool.length],
    ];

    return DailyChallenge(
      dateKey: dateKey(date),
      number: number,
      calls: calls,
    );
  }

  DailyChallenge todayChallenge({DateTime? now}) =>
      challengeFor(now ?? DateTime.now());

  bool hasPlayedToday({DateTime? now}) =>
      _lastKey == dateKey(now ?? DateTime.now());

  // ── Streak freeze ─────────────────────────────────────────────────

  /// One freeze per calendar week.
  ///
  /// Weekly rather than a stockpile you earn and spend: a balance turns into
  /// a resource to manage, and the point is to absorb the one night someone
  /// forgot — not to add a second game on top of the first.
  bool _canFreeze(DateTime today) => _freezeWeek != _weekOf(today);

  /// True when the gap is exactly one missed day. A freeze covers a slip, not
  /// a fortnight away; extending a month-old streak would make the number
  /// meaningless.
  bool _missedExactlyOneDay(DateTime today) {
    if (_lastKey == null) return false;
    final twoDaysAgo = dateKey(today.subtract(const Duration(days: 2)));
    return _lastKey == twoDaysAgo;
  }

  /// Calendar week index, weeks starting Monday.
  ///
  /// Not simply `daysSinceEpoch ~/ 7`: the epoch is a Thursday, so plain
  /// division puts the boundary mid-week and "one freeze per week" would
  /// quietly mean "one per arbitrary seven-day bucket". Offsetting by the
  /// epoch's weekday moves the break to Monday, which is what a user means.
  ///
  /// Only used for equality, so the absolute value does not matter.
  int _weekOf(DateTime date) {
    final days =
        DateTime(date.year, date.month, date.day).difference(_epoch).inDays;
    return (days + (_epoch.weekday - DateTime.monday)) ~/ 7;
  }

  /// Marks the freeze notice as seen, so it is shown once and not on every
  /// visit to the Daily screen.
  Future<void> acknowledgeFreeze() async {
    if (_freezeUsedKey == null) return;
    _freezeUsedKey = null;
    await _persist();
    notifyListeners();
  }

  // ── Completion + streak ───────────────────────────────────────────

  /// Records a finished challenge and updates the streak.
  /// - New day adjacent to the last play → streak extends.
  /// - Gap of more than a day → streak resets to 1.
  /// - Same day replay → idempotent (streak unchanged; score updated).
  Future<DailyResult> recordCompletion(
    DailyChallenge challenge,
    List<bool> correctness, {
    DateTime? now,
  }) async {
    await ensureLoaded();
    final today = now ?? DateTime.now();
    final todayKey = dateKey(today);
    final score = correctness.where((c) => c).length;

    if (_lastKey == todayKey) {
      // Already played today — don't touch the streak.
      _lastScore = score;
    } else {
      final yesterdayKey = dateKey(today.subtract(const Duration(days: 1)));
      final continued = _lastKey == yesterdayKey;

      // Exactly one day was missed, and a freeze is available this week.
      // Cover it silently: the user finds out afterwards, the way Duolingo
      // does it, because a "spend your freeze?" prompt turns a kindness into
      // another decision and another thing to feel bad about.
      final broke = !continued && _streak > 0;
      final covered = broke && _canFreeze(today) && _missedExactlyOneDay(today);

      if (covered) {
        _freezeUsedKey = dateKey(today.subtract(const Duration(days: 1)));
        _freezeWeek = _weekOf(today);
      } else if (broke) {
        // A streak that ended is a churn signal, and the distribution of how
        // long they were tells us where a streak freeze would pay for itself.
        // Reported here rather than at app start because this is the only
        // place that knows the previous run's length before it is overwritten.
        VxFunnel.dailyStreakLost(_streak);
      }

      _streak = (continued || covered) ? _streak + 1 : 1;
      _best = max(_best, _streak);
      _lastKey = todayKey;
      _lastScore = score;
      _played += 1;
    }

    await _persist();

    VxFunnel.dailyCompleted(
      score: score,
      outOf: challenge.length,
      streakDays: _streak,
    );
    VxFunnel.setStreakBucket(_streak);

    // Award XP once per challenge — replaying the same day never double-counts.
    await XpService.instance
        .awardOnce('daily:${challenge.number}', XpService.dailyXp);

    return DailyResult(
      dateKey: todayKey,
      number: challenge.number,
      score: score,
      total: challenge.length,
      correctness: correctness,
      streakAfter: _streak,
    );
  }

  Future<void> resetAll() async {
    _lastKey = null;
    _streak = 0;
    _best = 0;
    _lastScore = 0;
    _played = 0;
    _freezeUsedKey = null;
    _freezeWeek = null;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastKey != null) {
        await prefs.setString(_kLastKey, _lastKey!);
      } else {
        await prefs.remove(_kLastKey);
      }
      await prefs.setInt(_kStreak, _streak);
      await prefs.setInt(_kBest, _best);
      await prefs.setInt(_kLastScore, _lastScore);
      await prefs.setInt(_kPlayed, _played);
      if (_freezeUsedKey != null) {
        await prefs.setString(_kFreezeUsedKey, _freezeUsedKey!);
      } else {
        await prefs.remove(_kFreezeUsedKey);
      }
      if (_freezeWeek != null) {
        await prefs.setInt(_kFreezeWeek, _freezeWeek!);
      } else {
        // resetAll() clears this; without the remove, a stale week would
        // survive the reset and deny the next freeze.
        await prefs.remove(_kFreezeWeek);
      }
    } catch (_) {
      // Non-fatal: in-memory state stands for this session.
    }
  }
}
