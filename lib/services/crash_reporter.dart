import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/app_logger.dart';

/// Crash reporting service (integrates with Sentry or similar)
class CrashReporter {
  bool _initialized = false;
  final List<ErrorLog> _localErrors = [];

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    try {
      // In production, initialize Sentry here:
      // await SentryFlutter.init((options) {
      //   options.dsn = 'YOUR_SENTRY_DSN';
      //   options.environment = SecureConfig.isProduction ? 'production' : 'development';
      // });

      _initialized = true;
      AppLogger.info('✅ Crash reporting initialized');
    } catch (e) {
      AppLogger.error('⚠️ Failed to initialize crash reporting: $e');
      _initialized = false;
    }
  }

  /// Log a general error
  void logError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? extras,
  }) {
    // Log locally
    _localErrors.add(ErrorLog(
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      timestamp: DateTime.now(),
      fatal: fatal,
      extras: extras,
    ));

    // Log to AppLogger
    final level = fatal ? 'FATAL' : 'ERROR';
    AppLogger.error('❌ $level logged: $error');
    if (stackTrace != null) {
      // Typically we don't want to spam AppLogger with the full stack trace in production logs
      // but for debug it is useful.
      AppLogger.debug(stackTrace.toString());
    }

    // In production, send to Sentry:
    // if (_initialized) {
    //   Sentry.captureException(
    //     error,
    //     stackTrace: stackTrace,
    //     hint: Hint.withMap({
    //       'fatal': fatal,
    //       ...?extras,
    //     }),
    //   );
    // }
  }

  /// Log Flutter framework errors
  void logFlutterError(FlutterErrorDetails details) {
    logError(
      details.exception,
      details.stack,
      fatal: details.silent == false,
      extras: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  }

  /// Log a custom message
  void logMessage(
    String message, {
    SeverityLevel level = SeverityLevel.info,
    Map<String, dynamic>? extras,
  }) {
    final levelName = level.name.toUpperCase();
    AppLogger.info('[$levelName] $message');

    // In production, send to Sentry:
    // if (_initialized) {
    //   Sentry.captureMessage(
    //     message,
    //     level: level.toSentryLevel(),
    //     hint: Hint.withMap(extras ?? {}),
    //   );
    // }
  }

  /// Get locally stored errors (for debugging)
  List<ErrorLog> getLocalErrors() {
    return List.unmodifiable(_localErrors);
  }

  /// Clear local error cache
  void clearLocalErrors() {
    _localErrors.clear();
  }
}

/// Error log entry
class ErrorLog {
  final String error;
  final String stackTrace;
  final DateTime timestamp;
  final bool fatal;
  final Map<String, dynamic>? extras;

  ErrorLog({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    this.fatal = false,
    this.extras,
  });

  @override
  String toString() {
    return '[$timestamp] ${fatal ? 'FATAL' : 'ERROR'}: $error\n$stackTrace';
  }
}

/// Severity levels for logging
enum SeverityLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}
