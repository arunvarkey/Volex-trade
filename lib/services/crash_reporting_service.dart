import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../core/app_logger.dart';

/// Service for reporting crashes and significant errors to production monitoring tools (Sentry/Crashlytics).
class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  bool _initialized = false;

  /// Initializes the reporting service.
  /// Uses Sentry DSN from environment variables.
  Future<void> initialize() async {
    if (_initialized) return;

    String? dsn;
    try {
      dsn = dotenv.env['SENTRY_DSN'];
    } catch (_) {
      // dotenv not initialized
    }

    if (dsn == null || dsn.isEmpty) {
      AppLogger.warning("MONITOR: SENTRY_DSN not found. Skipping Sentry init.");
      _initialized = true;
      return;
    }

    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.tracesSampleRate =
              1.0; // Capture 100% of transactions for testing
          options.debug = kDebugMode;
        },
      );
      AppLogger.info("MONITOR: Sentry Initialized via CrashReportingService.");
    } catch (e) {
      AppLogger.error("MONITOR: Failed to init Sentry: $e");
    }

    _initialized = true;
  }

  /// Logs a non-fatal error.
  Future<void> logError(dynamic error,
      {StackTrace? stackTrace, String? reason}) async {
    AppLogger.error("MONITOR: Exception caught: $error");
    if (stackTrace != null) {
      AppLogger.debug(stackTrace.toString());
    }

    if (_initialized) {
      // 1. Send to Sentry
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: reason != null ? Hint.withMap({'reason': reason}) : null,
      );

      // 2. Send to Firebase Crashlytics if initialized
      // FirebaseCrashlytics.instance will throw a StateError if Firebase is not initialized.
      // The try-catch block handles this gracefully.
      try {
        await FirebaseCrashlytics.instance.recordError(error, stackTrace,
            reason: reason, printDetails: false);
      } catch (e) {
        // Firebase not initialized or failed, ignore in unit tests or log
        AppLogger.debug("Crashlytics skipped: $e");
      }
    }
  }

  /// Logs a custom breadcrumb to help debug the path to a crash.
  Future<void> logBreadcrumb(String message,
      {String? category, Map<String, dynamic>? data}) async {
    AppLogger.info("MONITOR: Breadcrumb: [$category] $message");

    if (_initialized) {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data,
          level: SentryLevel.info,
        ),
      );
    }
  }
}
