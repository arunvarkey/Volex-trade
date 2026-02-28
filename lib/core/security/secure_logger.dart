import 'package:flutter/foundation.dart';
import '../app_logger.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class SecureLogger {
  static final _sensitivePatterns = [
    // API Keys
    RegExp(r'[A-Z0-9]{64}', caseSensitive: true),
    RegExp(r'sk_live_[A-Za-z0-9]{24,}'),
    RegExp(r'pk_live_[A-Za-z0-9]{24,}'),

    // Private keys
    RegExp(r'-----BEGIN (?:RSA )?PRIVATE KEY-----'),
    RegExp(r'[A-Za-z0-9+/]{40,}={0,2}'),

    // Secrets
    RegExp(r'secret.*[:=].*[A-Za-z0-9+/=]{20,}', caseSensitive: false),
    RegExp(r'api.*secret.*[:=].*[A-Za-z0-9+/=]{20,}', caseSensitive: false),

    // Email addresses
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),

    // Phone numbers
    RegExp(r'\+?[1-9]\d{1,14}'),

    // Credit card numbers
    RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),

    // Social security numbers
    RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),

    // IP addresses
    RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b'),

    // Passwords
    RegExp(r'password.*[:=].*\S+', caseSensitive: false),
    RegExp(r'pwd.*[:=].*\S+', caseSensitive: false),

    // Auth tokens
    RegExp(r'bearer\s+[A-Za-z0-9\-_=]+\.[A-Za-z0-9\-_=]+',
        caseSensitive: false),

    // AWS keys
    RegExp(r'AKIA[0-9A-Z]{16}'),

    // Binance-specific
    RegExp(r'binance.*api.*key', caseSensitive: false),
    RegExp(r'binance.*secret', caseSensitive: false),
  ];

  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    // Never log in production unless critical
    if (kReleaseMode && level != LogLevel.critical) {
      return;
    }

    // Sanitize message
    final sanitized = _sanitize(message);

    // Sanitize data
    final sanitizedData = data != null ? _sanitizeMap(data) : null;

    // Format output
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();

    String output = '[$timestamp] [$levelStr] $sanitized';

    if (sanitizedData != null && sanitizedData.isNotEmpty) {
      output += '\nData: ${_formatData(sanitizedData)}';
    }

    if (stackTrace != null &&
        (level == LogLevel.error || level == LogLevel.critical)) {
      output += '\nStack: ${_sanitizeStackTrace(stackTrace)}';
    }

    // Output based on level
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        AppLogger.info(output);
        break;
      case LogLevel.warning:
        AppLogger.warning(output);
        break;
      case LogLevel.error:
        AppLogger.error(output);
        break;
      case LogLevel.critical:
        AppLogger.error('CRITICAL: $output');
        break;
    }
  }

  static String _sanitize(String message) {
    String sanitized = message;

    for (final pattern in _sensitivePatterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        final matched = match.group(0) ?? '';
        if (matched.length <= 4) return '[REDACTED]';

        // Keep first 4 chars for debugging
        return '${matched.substring(0, 4)}***';
      });
    }

    return sanitized;
  }

  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      final sensitiveKeys = [
        'password',
        'pwd',
        'secret',
        'token',
        'key',
        'api',
        'auth',
        'credential',
        'private',
        'ssn',
        'pin',
      ];

      final isSensitiveKey = sensitiveKeys.any(
        (sensitive) => key.toLowerCase().contains(sensitive),
      );

      if (isSensitiveKey) {
        return MapEntry(key, '[REDACTED]');
      }

      if (value is String) {
        return MapEntry(key, _sanitize(value));
      }

      if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitizeMap(value));
      }

      return MapEntry(key, value);
    });
  }

  static String _formatData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  static String _sanitizeStackTrace(StackTrace stackTrace) {
    return stackTrace
        .toString()
        .replaceAll(
          RegExp(r'/Users/[^/]+/'),
          '/Users/[REDACTED]/',
        )
        .replaceAll(
          RegExp(r'C:\\Users\\[^\\]+\\'),
          'C:\\Users\\[REDACTED]\\',
        );
  }

  // Convenience methods
  static void debug(String message, {Map<String, dynamic>? data}) {
    log(message, level: LogLevel.debug, data: data);
  }

  static void info(String message, {Map<String, dynamic>? data}) {
    log(message, level: LogLevel.info, data: data);
  }

  static void warning(String message, {Map<String, dynamic>? data}) {
    log(message, level: LogLevel.warning, data: data);
  }

  static void error(String message,
      {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    log(message, level: LogLevel.error, data: data, stackTrace: stackTrace);
  }

  static void critical(String message,
      {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    log(message, level: LogLevel.critical, data: data, stackTrace: stackTrace);
  }
}
