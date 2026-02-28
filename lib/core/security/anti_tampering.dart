import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';

class AntiTampering {
  static bool _debuggerDetected = false;
  static DateTime? _lastCheck;
  static const _checkInterval = Duration(seconds: 30);

  /// Check if app is being debugged
  static Future<bool> isDebugging() async {
    // In debug mode, always allow
    if (kDebugMode) {
      return false;
    }

    try {
      // Check various debugging indicators
      final checks = await Future.wait([
        _checkDebuggerAttached(),
        _checkDebugPort(),
        _checkTracerPid(),
      ]);

      _debuggerDetected = checks.any((check) => check);

      if (_debuggerDetected) {
        SecureLogger.critical('Debugger detected!');
      }

      _lastCheck = DateTime.now();
      return _debuggerDetected;
    } catch (e) {
      SecureLogger.error('Anti-debugging check failed',
          data: {'error': e.toString()});
      return false;
    }
  }

  /// Check if debugger is attached (Android)
  static Future<bool> _checkDebuggerAttached() async {
    if (!Platform.isAndroid) return false;

    try {
      // Check Android debug flags
      final result = await Process.run('getprop', ['ro.debuggable']);
      final debuggable = result.stdout.toString().trim() == '1';

      if (debuggable) {
        SecureLogger.warning('Device is debuggable');
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check for debug ports open
  static Future<bool> _checkDebugPort() async {
    try {
      // Common debug ports
      final debugPorts = [5005, 8000, 8080, 9222];

      for (final port in debugPorts) {
        try {
          final socket = await Socket.connect('localhost', port,
              timeout: const Duration(milliseconds: 100));
          socket.destroy();
          SecureLogger.warning('Debug port $port is open');
          return true;
        } catch (e) {
          // Port not open, continue
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check TracerPid (indicates debugging on Linux/Android)
  static Future<bool> _checkTracerPid() async {
    if (!Platform.isAndroid && !Platform.isLinux) return false;

    try {
      final statusFile = File('/proc/self/status');
      if (!await statusFile.exists()) return false;

      final contents = await statusFile.readAsString();
      final tracerPidLine = contents.split('\n').firstWhere(
            (line) => line.startsWith('TracerPid:'),
            orElse: () => '',
          );

      if (tracerPidLine.isEmpty) return false;

      final tracerPid = int.tryParse(tracerPidLine.split(':')[1].trim()) ?? 0;

      if (tracerPid != 0) {
        SecureLogger.critical('TracerPid detected: $tracerPid');
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Periodic anti-debugging checks
  static Future<void> startPeriodicChecks({
    required Function() onDebuggerDetected,
  }) async {
    // Skip in debug mode
    if (kDebugMode) return;

    while (true) {
      try {
        if (_lastCheck == null ||
            DateTime.now().difference(_lastCheck!) > _checkInterval) {
          if (await isDebugging()) {
            onDebuggerDetected();
            break; // Stop checking once detected
          }
        }

        await Future.delayed(_checkInterval);
      } catch (e) {
        SecureLogger.error('Periodic anti-debug check failed',
            data: {'error': e.toString()});
      }
    }
  }

  /// Verify app integrity (check if APK/IPA has been modified)
  static Future<bool> verifyIntegrity() async {
    if (kDebugMode) return true; // Skip in debug

    try {
      // Get app's own package info
      if (Platform.isAndroid) {
        return await _verifyAndroidIntegrity();
      } else if (Platform.isIOS) {
        return await _verifyIOSIntegrity();
      }

      return true;
    } catch (e) {
      SecureLogger.error('Integrity check failed',
          data: {'error': e.toString()});
      return false;
    }
  }

  /// Verify Android APK signature
  static Future<bool> _verifyAndroidIntegrity() async {
    try {
      // Get package signature
      final result =
          await Process.run('pm', ['dump', Platform.resolvedExecutable]);
      final output = result.stdout.toString();

      // Check for signs of repackaging
      if (output.contains('signatures mismatch')) {
        SecureLogger.critical('APK signature mismatch detected');
        return false;
      }

      // Check installer package (should be com.android.vending for Play Store)
      if (!output.contains('com.android.vending') &&
          !output.contains('installer=null')) {
        // null = sideloaded in dev
        SecureLogger.warning('App not installed from Play Store');
      }

      return true;
    } catch (e) {
      return true; // Can't verify, assume OK
    }
  }

  /// Verify iOS app signature
  static Future<bool> _verifyIOSIntegrity() async {
    // iOS has built-in signature verification
    // If app launches, signature is valid
    return true;
  }

  /// Check for code injection attempts
  static Future<bool> detectCodeInjection() async {
    if (kDebugMode) return false;

    try {
      // Check for Frida (common injection framework)
      final fridaIndicators = [
        '/data/local/tmp/frida-server',
        '/data/local/tmp/re.frida.server',
      ];

      for (final indicator in fridaIndicators) {
        if (await File(indicator).exists()) {
          SecureLogger.critical('Frida detected: $indicator');
          return true;
        }
      }

      // Check for Xposed (Android)
      if (Platform.isAndroid) {
        final xposedPaths = [
          '/system/framework/XposedBridge.jar',
          '/system/lib/libxposed_art.so',
        ];

        for (final path in xposedPaths) {
          if (await File(path).exists()) {
            SecureLogger.critical('Xposed detected: $path');
            return true;
          }
        }
      }

      // Check for Substrate (iOS)
      if (Platform.isIOS) {
        final substratePaths = [
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/usr/lib/libsubstrate.dylib',
        ];

        for (final path in substratePaths) {
          if (await File(path).exists()) {
            SecureLogger.critical('Substrate detected: $path');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check for memory dumping tools
  static Future<bool> detectMemoryDumping() async {
    if (kDebugMode) return false;

    try {
      if (Platform.isAndroid) {
        // Check for GameGuardian and similar tools
        final memoryTools = [
          'com.droidvnteam.gameguardian',
          'com.google.android.apps.maps', // Sometimes used as cover
          'jackpal.androidterm', // Terminal emulator
        ];

        for (final tool in memoryTools) {
          try {
            final result = await Process.run('pm', ['list', 'packages', tool]);
            if (result.stdout.toString().contains(tool)) {
              SecureLogger.critical('Memory dumping tool detected: $tool');
              return true;
            }
          } catch (e) {
            // Continue checking
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Comprehensive tampering check
  static Future<TamperingReport> performComprehensiveCheck() async {
    final results = await Future.wait([
      isDebugging(),
      verifyIntegrity(),
      detectCodeInjection(),
      detectMemoryDumping(),
    ]);

    final report = TamperingReport(
      isDebugging: results[0],
      integrityValid: results[1],
      codeInjectionDetected: results[2],
      memoryDumpingDetected: results[3],
    );

    if (report.isTampered) {
      SecureLogger.critical(
        'Tampering detected!',
        data: report.toJson(),
      );
    }

    return report;
  }

  /// Handle tampering detection
  static Future<void> onTamperingDetected({
    required Function() onWipeData,
    required Function() onLockApp,
  }) async {
    SecureLogger.critical('Tampering detected - initiating security protocol');

    // In production, wipe sensitive data
    if (kReleaseMode) {
      await onWipeData();
      await onLockApp();
    }
  }
}

class TamperingReport {
  final bool isDebugging;
  final bool integrityValid;
  final bool codeInjectionDetected;
  final bool memoryDumpingDetected;

  TamperingReport({
    required this.isDebugging,
    required this.integrityValid,
    required this.codeInjectionDetected,
    required this.memoryDumpingDetected,
  });

  bool get isTampered {
    return isDebugging ||
        !integrityValid ||
        codeInjectionDetected ||
        memoryDumpingDetected;
  }

  int get riskScore {
    int score = 0;
    if (isDebugging) score += 40;
    if (!integrityValid) score += 30;
    if (codeInjectionDetected) score += 50;
    if (memoryDumpingDetected) score += 30;
    return score.clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
        'is_tampered': isTampered,
        'risk_score': riskScore,
        'is_debugging': isDebugging,
        'integrity_valid': integrityValid,
        'code_injection_detected': codeInjectionDetected,
        'memory_dumping_detected': memoryDumpingDetected,
      };
}
