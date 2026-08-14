import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enforces Volex's 13+ minimum age.
///
/// Privacy-minimising by design: we store only a derived boolean ("confirmed
/// 13 or older"), never a birthdate. 13+ is the deliberate floor — it covers
/// most students while staying clear of the COPPA under-13 regime.
class AgeGateService extends ChangeNotifier {
  AgeGateService._();
  static final AgeGateService instance = AgeGateService._();

  /// Minimum age to use Volex.
  static const int minimumAge = 13;

  static const String _kConfirmed = 'age_gate_confirmed_13plus_v1';
  static const String _kBlocked = 'age_gate_blocked_under13_v1';

  bool _loaded = false;
  bool _confirmed = false;
  bool _blocked = false;

  bool get isLoaded => _loaded;

  /// True once the user has affirmed they meet the minimum age.
  bool get isConfirmed => _confirmed;

  /// True if the user indicated they are under the minimum age.
  bool get isBlocked => _blocked;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _confirmed = prefs.getBool(_kConfirmed) ?? false;
      _blocked = prefs.getBool(_kBlocked) ?? false;
    } catch (_) {
      // Fail closed to "not confirmed" so the gate still shows.
      _confirmed = false;
      _blocked = false;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// User affirmed they are at least [minimumAge].
  Future<void> confirmMeetsMinimum() async {
    _confirmed = true;
    _blocked = false;
    notifyListeners();
    await _persist();
  }

  /// User indicated they are under [minimumAge].
  Future<void> declineUnderAge() async {
    _confirmed = false;
    _blocked = true;
    notifyListeners();
    await _persist();
  }

  Future<void> reset() async {
    _confirmed = false;
    _blocked = false;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kConfirmed, _confirmed);
      await prefs.setBool(_kBlocked, _blocked);
    } catch (_) {
      // Non-fatal; in-memory state stands for this session.
    }
  }
}
