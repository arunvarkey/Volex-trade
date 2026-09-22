import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../core/app_logger.dart';

/// Service for managing remote configuration and feature flags.
///
/// Uses [FirebaseRemoteConfig] to control app behavior without app updates.
///
/// **Common Flags:**
/// *   `maintenance_mode` (bool): Blocks access to the app.
/// *   `enable_live_trading` (bool): Global kill switch for live execution.
/// *   `welcome_message` (string): Dynamic welcome text.
class FeatureFlagService {
  final FirebaseRemoteConfig? _remoteConfig;

  FeatureFlagService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig;

  bool _initialized = false;

  /// Initialize Remote Config with default values and fetch/activate.
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      AppLogger.warning("FLAGS: Remote Config skipped on Web.");
      return;
    }

    try {
      final config = _remoteConfig ?? FirebaseRemoteConfig.instance;
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval:
            kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 12),
      ));

      // 1. Set Defaults
      await config.setDefaults({
        'maintenance_mode': false,
        'enable_live_trading': true,
        'ai_model_version': 'v1.0.0',
        'max_leverage': 3.0,
        'ai_guardian_enabled': true,
      });

      // 2. Fetch & Activate
      await config.fetchAndActivate();

      _initialized = true;
      AppLogger.info("FLAGS: Remote Config Initialized");
    } catch (e) {
      AppLogger.error("FLAGS: Failed to init remote config: $e");
    }
  }

  // --- Getters ---

  /// Blocks app access if true.
  bool get isMaintenanceMode => !kIsWeb && _initialized
      ? (_remoteConfig ?? FirebaseRemoteConfig.instance)
          .getBool('maintenance_mode')
      : false;

  /// Global kill switch for live trading.
  bool get isLiveTradingEnabled => !kIsWeb && _initialized
      ? (_remoteConfig ?? FirebaseRemoteConfig.instance)
          .getBool('enable_live_trading')
      : true;

  /// Max leverage allowed (risk control).
  double get maxLeverage => !kIsWeb && _initialized
      ? (_remoteConfig ?? FirebaseRemoteConfig.instance)
          .getDouble('max_leverage')
      : 3.0;

  /// Master switch for the pre-trade checks (revenge-trading and
  /// overtrading detection). The remote key keeps its original name so
  /// existing Remote Config entries keep working.
  bool get areTradeChecksEnabled => !kIsWeb && _initialized
      ? (_remoteConfig ?? FirebaseRemoteConfig.instance)
          .getBool('ai_guardian_enabled')
      : true;
}
