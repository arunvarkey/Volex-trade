import 'package:flutter/material.dart';
import 'persistence/persistence_service.dart';

import '../core/service_locator.dart';

enum LogVerbosity { basic, advanced, raw }

class TerminalSettingsProvider extends ChangeNotifier {
  factory TerminalSettingsProvider() => getIt<TerminalSettingsProvider>();
  final PersistenceService _persistence;

  bool _isProMode = false;
  bool get isProMode => _isProMode;

  Duration _refreshInterval = const Duration(seconds: 1);
  Duration get refreshInterval => _refreshInterval;

  LogVerbosity _logVerbosity = LogVerbosity.basic;
  LogVerbosity get logVerbosity => _logVerbosity;

  bool _showIndicators = false;
  bool get showIndicators => _showIndicators;

  bool _useDarkTheme = true;
  bool get useDarkTheme => _useDarkTheme;

  bool _simulationMode = true;
  bool get simulationMode => _simulationMode;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  TerminalSettingsProvider.inject(this._persistence) {
    _loadSettings();
  }

  void _loadSettings() {
    final onboardingComplete = _persistence
            .getSetting<bool>('onboarding_complete', defaultValue: false) ??
        false;

    _isProMode = onboardingComplete
        ? (_persistence.getSetting<bool>('isProMode', defaultValue: false) ??
            false)
        : false;

    final intervalMs =
        _persistence.getSetting<int>('refreshIntervalMs', defaultValue: 1000) ??
            1000;
    _refreshInterval = Duration(milliseconds: intervalMs);

    final verbosityIndex =
        _persistence.getSetting<int>('logVerbosityIndex', defaultValue: 0) ?? 0;
    _logVerbosity = LogVerbosity.values[verbosityIndex];

    _showIndicators =
        _persistence.getSetting<bool>('showIndicators', defaultValue: false) ??
            false;
    _useDarkTheme =
        _persistence.getSetting<bool>('useDarkTheme', defaultValue: true) ??
            true;
    _simulationMode = onboardingComplete
        ? (_persistence.getSetting<bool>('simulationMode',
                defaultValue: true) ??
            true)
        : true;

    _biometricEnabled = _persistence.getSetting<bool>('biometricEnabled',
            defaultValue: false) ??
        false;

    notifyListeners();
  }

  void toggleProMode() {
    _isProMode = !_isProMode;
    if (_isProMode && _logVerbosity == LogVerbosity.basic) {
      _logVerbosity = LogVerbosity.advanced;
      _persistence.saveSetting('logVerbosityIndex', _logVerbosity.index);
    }
    _persistence.saveSetting('isProMode', _isProMode);
    notifyListeners();
  }

  void setRefreshInterval(Duration interval) {
    _refreshInterval = interval;
    _persistence.saveSetting(
        'refreshIntervalMs', _refreshInterval.inMilliseconds);
    notifyListeners();
  }

  void setLogVerbosity(LogVerbosity verbosity) {
    _logVerbosity = verbosity;
    _persistence.saveSetting('logVerbosityIndex', _logVerbosity.index);
    notifyListeners();
  }

  void toggleIndicators() {
    _showIndicators = !_showIndicators;
    _persistence.saveSetting('showIndicators', _showIndicators);
    notifyListeners();
  }

  void toggleTheme() {
    _useDarkTheme = !_useDarkTheme;
    _persistence.saveSetting('useDarkTheme', _useDarkTheme);
    notifyListeners();
  }

  void toggleSimulationMode() {
    _simulationMode = !_simulationMode;
    _persistence.saveSetting('simulationMode', _simulationMode);
    notifyListeners();
  }

  void toggleBiometrics(bool enabled) {
    _biometricEnabled = enabled;
    _persistence.saveSetting('biometricEnabled', _biometricEnabled);
    notifyListeners();
  }
}
