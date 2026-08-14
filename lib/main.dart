import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart'; // For defaultTargetPlatform
import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'package:volex_terminal/core/security/emergency_wipe.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';

import 'core/service_locator.dart';
import 'package:volex_terminal/core/services/auth/security_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
// import 'services/crash_reporting_service.dart'; // Disabled for isolation
import 'ui/design_system/vx_colors.dart';

import 'core/app_logger.dart'; // Logging
import 'app.dart'; // The app widget

Future<void> main() async {
  AppLogger.info("!!! DART MAIN STARTING !!!");
  // Wrap in runZonedGuarded for global error handling
  runZonedGuarded(() async {
    // Ensure Flutter is initialized within the zone
    WidgetsFlutterBinding.ensureInitialized();

    // We will initialize Crashlytics only AFTER Firebase.initializeApp()

    // Initialize notifications BEFORE runApp
    try {
      await NotificationService.initialize();
    } catch (e) {
      AppLogger.error("Failed to init notifications", e);
    }

    AppLogger.info("Starting Volex Terminal...");

    // Load environment variables (removed to prevent .env leak on device as per Task 22)

    // Initialize Firebase
    try {
      AppLogger.info("🔥 Initiating Firebase...");

      if (kIsWeb) {
        AppLogger.warning(
            "🔥 WEB: Skipping Firebase init (DefaultFirebaseOptions not configured for web)");
        // We could add web options here if needed, but for now we skip to prevent crash
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // On Android, we rely on google-services.json (Native)
        // This avoids issues with .env loading or missing keys
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      AppLogger.info("🔥 Firebase Connected!");

      // Unified Error Handling within the zone (AFTER Firebase init)
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // Crashlytics has no web support; calling it here would make the
        // error handler itself throw and cascade.
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };
    } catch (e, stack) {
      AppLogger.error("❌ Firebase init failed: $e", e, stack);
    }

    // System UI configuration
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: VxColors.deepBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Lock portrait orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize core services
    final initResult = await ServiceLocator.setupServices(
      onProgress: (message, progress) {
        AppLogger.debug('[${(progress * 100).toStringAsFixed(0)}%] $message');
      },
    );

    if (!initResult.success) {
      runApp(ErrorApp(error: initResult.errorMessage ?? 'Unknown error'));
      return;
    }

    // SecureAuthService is now initialized via ServiceLocator.setupServices()

    // 4. Security Checks
    final getIt = GetIt.instance;
    final securityService = getIt<SecurityService>();
    await securityService.initialize();

    if (!kIsWeb && !securityService.isDeviceSecure) {
      if (kDebugMode) {
        AppLogger.warning(
            'SECURITY: Device potentially compromised (Debug Mode - Ignoring)');
      } else {
        // In production we might want to show a blocker or limit functionality
        AppLogger.error('SECURITY: CRITICAL - Device is compromised.');
        // runApp(const SecurityLockoutApp()); return; // Uncomment to enforce
      }
    }
    // Initialize analytics
    await AnalyticsService.instance.initialize();

    // Check for previous emergency wipe
    final wipeStatus = await EmergencyWipe.checkWipeStatus();
    if (wipeStatus.wasWiped) {
      SecureLogger.critical('App was previously wiped!',
          data: wipeStatus.toJson());
      // Clear flag after logging/notifying
      await EmergencyWipe.clearWipeFlag();
      // In a real app, you might show a specific "Compromised" UI here
    }

    // Start continuous security monitoring
    EmergencyWipe.startSecurityMonitoring();

    // Run the app
    runApp(const VolexTerminalApp());
  }, (error, stack) {
    AppLogger.error("🔴 Uncaught Dart Error: $error", error, stack);
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    } catch (e) {
      debugPrint("Failed to record error to Crashlytics: $e");
    }
  });
}
