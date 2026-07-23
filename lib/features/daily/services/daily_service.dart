import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../academy/services/xp_service.dart';
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

  bool _loaded = false;
  String? _lastKey;
  int _streak = 0;
  int _best = 0;
  int _lastScore = 0;
  int _played = 0;

  bool get isLoaded => _loaded;
  int get currentStreak => _streak;
  int get bestStreak => _best;
  int get playedCount => _played;
  int get lastScore => _lastScore;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastKey = prefs.getString(_kLastKey);
      _streak = prefs.getInt(_kStreak) ?? 0;
      _best = prefs.getInt(_kBest) ?? 0;
      _lastScore = prefs.getInt(_kLastScore) ?? 0;
      _played = prefs.getInt(_kPlayed) ?? 0;
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
  DailyChallenge challengeFor(DateTime date) {
    final number = challengeNumber(date);
    final indices = List<int>.generate(DailyQuestionBank.all.length, (i) => i);
    // Seeded shuffle → stable per calendar day across devices.
    indices.shuffle(Random(number));
    final take = min(_callsPerDay, indices.length);
    final calls = [for (int i = 0; i < take; i++) DailyQuestionBank.all[indices[i]]];
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
      _streak = (_lastKey == yesterdayKey) ? _streak + 1 : 1;
      _best = max(_best, _streak);
      _lastKey = todayKey;
      _lastScore = score;
      _played += 1;
    }

    await _persist();

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
    } catch (_) {
      // Non-fatal: in-memory state stands for this session.
    }
  }
}
