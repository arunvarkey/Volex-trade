import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Secure application configuration with secrets management
class SecureConfig {
  // Version Info
  static const String version = '1.0.1';
  static const int buildNumber = 2;

  // Environment Detection
  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'development');
  static bool get isDevelopment => _env == 'development';
  static bool get isProduction => _env == 'production';
  static bool get isStaging => _env == 'staging';

  // Feature Flags (Compile-time)

  /// Live trading is LOCKED to false for V1 release.
  static bool get enableLiveTrading => false;

  // Security Settings
  static const bool enforceApiKeyEncryption = true;
  static const bool requireBiometricForLiveTrading = true;
  static const bool enableCertificatePinning = true;
  static const int maxLoginAttempts = 3;
  static const Duration sessionTimeout = Duration(minutes: 30);

  // API Configuration (No hardcoded URLs in production)
  static String get binanceApiUrl {
    if (isProduction) {
      // In production, MUST be set via environment
      const url = String.fromEnvironment('BINANCE_API_URL');
      if (url.isEmpty) {
        throw StateError('BINANCE_API_URL not configured for production');
      }
      return url;
    }
    return 'https://testnet.binance.vision'; // Safe default for dev/staging
  }

  static String get binanceWsUrl {
    if (isProduction) {
      const url = String.fromEnvironment('BINANCE_WS_URL');
      if (url.isEmpty) {
        throw StateError('BINANCE_WS_URL not configured for production');
      }
      return url;
    }
    return 'wss://testnet.binance.vision/ws';
  }

  // Rate Limiting (Binance enforces strict limits)
  static const int maxRequestsPerMinute = 1200; // Binance limit
  static const int maxWebSocketConnections = 5;
  static const int maxOrdersPerSecond = 10;

  // Trading Limits (Safety)
  static const int maxConcurrentStrategies = 5; // Reduced from 10 for safety
  static const double maxPositionSizePercent =
      0.10; // Max 10% of account per trade
  static const double maxDailyLossPercent = 0.05; // Max 5% daily loss
  static const int maxConsecutiveLosses = 3; // Reduced from 5

  // Data Limits
  static const int maxCandlesInMemory = 10000; // Reduced from 100k
  static const int maxOrderHistoryDays = 90;
  static const Duration cacheExpiration = Duration(hours: 24);

  // Performance
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 3;

  // Logging (Never log sensitive data in production)
  static bool get enableVerboseLogging => !isProduction && kDebugMode;
  static bool get logApiRequests => !isProduction;
  static bool get logTrades => true; // Always log for audit

  // Fixed-Point Arithmetic for Financial Calculations
  // Migrated to FinancialMath

  /// Validate numerical input for trading
  static bool isValidAmount(double amount) {
    if (amount.isNaN || amount.isInfinite) return false;
    if (amount < 0) return false;
    if (amount > 1000000000) return false; // Sanity check: max $1B
    return true;
  }

  /// Validate symbol format
  static bool isValidSymbol(String symbol) {
    if (symbol.isEmpty || symbol.length > 20) return false;
    // Only alphanumeric
    return RegExp(r'^[A-Z0-9]+$').hasMatch(symbol);
  }

  /// Sanitize user input
  static String sanitizeInput(String input) {
    // Remove any potential injection characters
    return input
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .trim()
        .substring(0, input.length > 100 ? 100 : input.length);
  }

  // Certificate Pinning (SHA256 hashes of expected certificates)
  static const List<String> binanceCertificateHashes = [
    // Add actual certificate hashes for production
    // These should be updated when Binance updates their certificates
    // Example format: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
  ];

  /// Print secure banner (no sensitive info)
  static void printBanner() {
    if (!kReleaseMode) {
      AppLogger.info('╔════════════════════════════════════════╗');
      AppLogger.info('║     VOLEX TERMINAL v$version         ║');
      AppLogger.info('║     Build: $buildNumber                         ║');
      AppLogger.info('║     Environment: $_env              ║');
      AppLogger.info(
          '║     Live Trading: ${enableLiveTrading ? "ENABLED" : "DISABLED"}   ║');
      AppLogger.info('╚════════════════════════════════════════╝');
    }
  }

  static void _log(String message) {
    AppLogger.info(message);
  }

  /// Validate configuration before app start
  static void validate() {
    // In production, ensure all required configs are set
    if (isProduction) {
      _log('SAFETY: V1 Live Trading Lock is ACTIVE.');

      // Verify API URLs are configured
      try {
        binanceApiUrl;
        binanceWsUrl;
      } catch (e) {
        throw StateError('Production configuration incomplete: $e');
      }
    }
  }
}
