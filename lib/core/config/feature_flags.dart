// lib/core/config/feature_flags.dart
class FeatureFlags {
  // Simulator features
  static const bool simulatorEnabled = true;
  static const bool strategyTemplatesEnabled = true;
  static const bool aiAssistantEnabled = true; // Premium only
  static const bool paperTradingEnabled = true;
  static const bool educationEnabled = false; // Future

  // Existing features (document what you already have)
  static const bool liveExecutionEnabled = true;
  static const bool backtestingEnabled = true;

  // Environment-specific
  static bool get isProduction => const String.fromEnvironment('ENV') == 'prod';
  static bool get useTestnet => !isProduction;

  // Maintenance Mode (can be toggled via Remote Config in production)
  static const bool defaultMaintenanceMode = false;
}
