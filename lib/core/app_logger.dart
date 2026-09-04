import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  /// Release ships warnings and errors only.
  ///
  /// debugPrint is throttled print, not a debug-only print — it writes to
  /// logcat in release builds as well. At info level that meant a release
  /// build logging the signed-in user's Firebase UID, whether they were
  /// authenticated, their paper balance and the day's restored losses, all
  /// readable over adb or by anything holding READ_LOGS. Errors still print
  /// and still reach Crashlytics; info-level breadcrumbs do not belong in a
  /// device log.
  static LogLevel _minLevel =
      kReleaseMode ? LogLevel.warning : LogLevel.debug;

  static void setLevel(LogLevel level) {
    _minLevel = level;
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
      LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = _getPrefix(level);

    // In production, we might want to strip debug logs entirely or send errors to a service.
    // For this implementation, we ensure it's safe and tagged.
    debugPrint("[$timestamp] $prefix $message");
    if (error != null) {
      debugPrint("  Error: $error");
    }
    if (stackTrace != null) {
      debugPrint("  Stack: $stackTrace");
    }
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return "[DEBUG]";
      case LogLevel.info:
        return "[INFO]";
      case LogLevel.warning:
        return "[WARN]";
      case LogLevel.error:
        return "[ERROR]";
    }
  }
}
