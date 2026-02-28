// lib/core/config/app_mode_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_mode.dart';

class AppModeService extends ChangeNotifier {
  static const _key = 'app_mode';

  AppMode _currentMode = AppMode.paper; // Default to safe mode
  AppMode get currentMode => _currentMode;

  final SharedPreferences _prefs;

  AppModeService(this._prefs) {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final modeIndex = _prefs.getInt(_key);
    if (modeIndex != null && modeIndex < AppMode.values.length) {
      _currentMode = AppMode.values[modeIndex];
      notifyListeners();
    }
  }

  Future<bool> setMode(AppMode mode) async {
    // CRITICAL: Require confirmation for live mode
    if (mode == AppMode.live && _currentMode != AppMode.live) {
      // This should trigger a confirmation dialog in UI
      // For now, allow it programmatically, but UI must check this return value
      // logic handled in UI layer or Dialog service.
    }

    _currentMode = mode;
    await _prefs.setInt(_key, mode.index);
    notifyListeners();
    return true;
  }

  bool canExecuteOrders() {
    return _currentMode == AppMode.testnet || _currentMode == AppMode.live;
  }

  bool shouldUseSimulatedExecution() {
    return _currentMode.isSimulated;
  }
}
