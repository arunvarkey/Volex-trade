import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progression tiers a learner climbs as they earn XP.
enum XpLevel { novice, operator, analyst, pro }

extension XpLevelInfo on XpLevel {
  String get label {
    switch (this) {
      case XpLevel.novice:
        return 'Novice';
      case XpLevel.operator:
        return 'Operator';
      case XpLevel.analyst:
        return 'Analyst';
      case XpLevel.pro:
        return 'Pro';
    }
  }

  /// XP at which this level begins.
  int get threshold {
    switch (this) {
      case XpLevel.novice:
        return 0;
      case XpLevel.operator:
        return 200;
      case XpLevel.analyst:
        return 600;
      case XpLevel.pro:
        return 1200;
    }
  }

  String get emoji {
    switch (this) {
      case XpLevel.novice:
        return '🌱';
      case XpLevel.operator:
        return '🎮';
      case XpLevel.analyst:
        return '📈';
      case XpLevel.pro:
        return '🧠';
    }
  }
}

/// Tracks a learner's XP and derived level across the whole app.
///
/// XP is earned once per meaningful action (a lesson passed, a backtest run, a
/// paper trade placed, a daily challenge finished) via idempotent [awardOnce]
/// calls keyed by a stable string, so replaying the same action never
/// double-counts. Self-contained singleton backed by SharedPreferences — no DI
/// wiring, listened to as a [ChangeNotifier].
class XpService extends ChangeNotifier {
  XpService._();
  static final XpService instance = XpService._();

  // XP rewards per action type.
  static const int lessonXp = 50;
  static const int backtestXp = 25;
  static const int tradeXp = 15;
  static const int dailyXp = 20;

  static const String _kTotal = 'xp_total_v1';
  static const String _kKeys = 'xp_awarded_keys_v1';

  int _total = 0;
  final Set<String> _awarded = <String>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get totalXp => _total;

  /// The level a given XP total corresponds to. Pure — used by tests and UI.
  static XpLevel levelForXp(int xp) {
    if (xp >= XpLevel.pro.threshold) return XpLevel.pro;
    if (xp >= XpLevel.analyst.threshold) return XpLevel.analyst;
    if (xp >= XpLevel.operator.threshold) return XpLevel.operator;
    return XpLevel.novice;
  }

  XpLevel get level => levelForXp(_total);

  /// The next tier up, or null if already at the top.
  XpLevel? get nextLevel {
    switch (level) {
      case XpLevel.novice:
        return XpLevel.operator;
      case XpLevel.operator:
        return XpLevel.analyst;
      case XpLevel.analyst:
        return XpLevel.pro;
      case XpLevel.pro:
        return null;
    }
  }

  /// 0.0–1.0 progress from the current level's threshold toward the next.
  double get progressToNextLevel {
    final next = nextLevel;
    if (next == null) return 1.0;
    final base = level.threshold;
    final span = next.threshold - base;
    if (span <= 0) return 1.0;
    return ((_total - base) / span).clamp(0.0, 1.0);
  }

  /// XP still needed to reach the next level (0 at the top).
  int get xpToNextLevel {
    final next = nextLevel;
    if (next == null) return 0;
    return (next.threshold - _total).clamp(0, next.threshold);
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _total = prefs.getInt(_kTotal) ?? 0;
      _awarded
        ..clear()
        ..addAll(prefs.getStringList(_kKeys) ?? const <String>[]);
    } catch (_) {
      _total = 0;
      _awarded.clear();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  bool hasAwarded(String key) => _awarded.contains(key);

  /// Awards [amount] XP for [key] exactly once. Returns the XP actually added
  /// (0 if this key was already rewarded or [amount] is non-positive), so
  /// callers can show a "+XP" flourish only when something really changed.
  Future<int> awardOnce(String key, int amount) async {
    await ensureLoaded();
    if (amount <= 0 || _awarded.contains(key)) return 0;
    _awarded.add(key);
    _total += amount;
    notifyListeners();
    await _persist();
    return amount;
  }

  /// Adds [amount] XP for a *repeatable* action (a paper trade, a backtest)
  /// without idempotency tracking — every call counts. Use [awardOnce] for
  /// one-time milestones like completing a specific lesson.
  Future<void> addXp(int amount) async {
    await ensureLoaded();
    if (amount <= 0) return;
    _total += amount;
    notifyListeners();
    await _persist();
  }

  Future<void> reset() async {
    _total = 0;
    _awarded.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTotal, _total);
      await prefs.setStringList(_kKeys, _awarded.toList());
    } catch (_) {
      // Non-fatal: XP stays in memory for this session.
    }
  }
}
