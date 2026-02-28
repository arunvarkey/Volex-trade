import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform, Process, File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:volex_terminal/core/security/secure_logger.dart';

class DeviceSecurity {
  static Future<DeviceSecurityReport> analyzeDevice() async {
    SecureLogger.info('Starting device security analysis...');

    if (kIsWeb) {
      return DeviceSecurityReport(
        isJailbroken: false,
        isDeveloperMode: false,
        isEmulator: false,
        canMockLocation: false,
        isOnExternalStorage: false,
        hasAdbEnabled: false,
        suspiciousApps: [],
        deviceInfo: {'platform': 'Web'},
      );
    }

    final isJailbroken = await _checkJailbreak();
    final isDeveloperMode = await _checkDeveloperMode();
    final isRealDevice = await _checkRealDevice();
    final canMockLocation = await _checkMockLocation();
    final isOnExternalStorage = await _checkExternalStorage();
    final hasAdbEnabled = await _checkAdb();
    final suspiciousApps = await _checkSuspiciousApps();
    final deviceInfo = await _getDeviceInfo();

    final report = DeviceSecurityReport(
      isJailbroken: isJailbroken,
      isDeveloperMode: isDeveloperMode,
      isEmulator: !isRealDevice,
      canMockLocation: canMockLocation,
      isOnExternalStorage: isOnExternalStorage,
      hasAdbEnabled: hasAdbEnabled,
      suspiciousApps: suspiciousApps,
      deviceInfo: deviceInfo,
    );

    SecureLogger.info(
      'Device security analysis complete',
      data: report.toJson(),
    );

    return report;
  }

  static Future<bool> _checkJailbreak() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      SecureLogger.warning('Jailbreak check failed: $e');
      return false;
    }
  }

  static Future<bool> _checkDeveloperMode() async {
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (e) {
      SecureLogger.warning('Developer mode check failed: $e');
      return false;
    }
  }

  static Future<bool> _checkRealDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.isPhysicalDevice;
      }
      return true;
    } catch (e) {
      SecureLogger.warning('Real device check failed: $e');
      return true; // Assume real if check fails
    }
  }

  static Future<bool> _checkMockLocation() async {
    // Mock location check requires specialized plugin or platform channel
    // Temporarily disabled due to dependency conflict
    return false;
  }

  static Future<bool> _checkExternalStorage() async {
    // External storage check requires specialized plugin or platform channel
    // Temporarily disabled due to dependency conflict
    return false;
  }

  static Future<bool> _checkAdb() async {
    try {
      if (Platform.isAndroid) {
        // Check if ADB is enabled
        final result = await Process.run('getprop', ['ro.debuggable']);
        return result.stdout.toString().trim() == '1';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> _checkSuspiciousApps() async {
    final suspicious = <String>[];

    if (Platform.isAndroid) {
      // Check for known hacking/rooting apps
      final suspiciousPackages = [
        'com.topjohnwu.magisk', // Magisk
        'eu.chainfire.supersu', // SuperSU
        'com.noshufou.android.su', // Superuser
        'com.koushikdutta.superuser',
        'com.thirdparty.superuser',
        'com.yellowes.su',
        'com.ramdroid.appquarantine',
        'com.devadvance.rootcloak',
        'com.devadvance.rootcloakplus',
        'de.robv.android.xposed.installer', // Xposed
        'com.saurik.substrate', // Substrate
        'com.zachspong.temprootremovejb',
        'com.amphoras.hidemyroot',
        'com.formyhm.hideroot',
      ];

      for (final package in suspiciousPackages) {
        try {
          final result = await Process.run('pm', ['list', 'packages', package]);
          if (result.stdout.toString().contains(package)) {
            suspicious.add(package);
          }
        } catch (e) {
          // Ignore
        }
      }
    }

    if (Platform.isIOS) {
      // Check for jailbreak apps
      final jailbreakPaths = [
        '/Applications/Cydia.app',
        '/Applications/RockApp.app',
        '/Applications/Icy.app',
        '/Applications/WinterBoard.app',
        '/Applications/SBSettings.app',
        '/Applications/blackra1n.app',
        '/Applications/IntelliScreen.app',
        '/Applications/Snoop-itConfig.app',
        '/private/var/lib/apt',
        '/private/var/lib/cydia',
        '/private/var/mobile/Library/SBSettings/Themes',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/usr/bin/ssh',
      ];

      for (final path in jailbreakPaths) {
        if (await File(path).exists() || await Directory(path).exists()) {
          suspicious.add(path);
        }
      }
    }

    return suspicious;
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return {
        'model': info.model,
        'manufacturer': info.manufacturer,
        'version': info.version.release,
        'sdk': info.version.sdkInt,
        'device_id': info.id,
        'is_physical': info.isPhysicalDevice,
      };
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return {
        'model': info.model,
        'name': info.name,
        'version': info.systemVersion,
        'device_id': info.identifierForVendor ?? 'unknown',
        'is_physical': info.isPhysicalDevice,
      };
    }

    return {};
  }

  static Future<bool> isDeviceSecure() async {
    final report = await analyzeDevice();
    return report.isSecure;
  }

  static Future<bool> enforceSecureDevice({
    required Function(DeviceSecurityReport) onInsecure,
  }) async {
    final report = await analyzeDevice();

    if (!report.isSecure) {
      SecureLogger.warning(
        'Device security check failed',
        data: report.toJson(),
      );

      onInsecure(report);
      return false;
    }

    return true;
  }
}

class DeviceSecurityReport {
  final bool isJailbroken;
  final bool isDeveloperMode;
  final bool isEmulator;
  final bool canMockLocation;
  final bool isOnExternalStorage;
  final bool hasAdbEnabled;
  final List<String> suspiciousApps;
  final Map<String, dynamic> deviceInfo;

  DeviceSecurityReport({
    required this.isJailbroken,
    required this.isDeveloperMode,
    required this.isEmulator,
    required this.canMockLocation,
    required this.isOnExternalStorage,
    required this.hasAdbEnabled,
    required this.suspiciousApps,
    required this.deviceInfo,
  });

  bool get isSecure {
    return !isJailbroken &&
        !isDeveloperMode &&
        !isEmulator &&
        !canMockLocation &&
        !isOnExternalStorage &&
        !hasAdbEnabled &&
        suspiciousApps.isEmpty;
  }

  int get securityScore {
    int score = 100;

    if (isJailbroken) score -= 40;
    if (isDeveloperMode) score -= 20;
    if (isEmulator) score -= 30;
    if (canMockLocation) score -= 15;
    if (isOnExternalStorage) score -= 10;
    if (hasAdbEnabled) score -= 10;
    score -= suspiciousApps.length * 5;

    return score.clamp(0, 100);
  }

  List<String> get securityIssues {
    final issues = <String>[];

    if (isJailbroken) issues.add('Device is jailbroken/rooted');
    if (isDeveloperMode) issues.add('Developer mode is enabled');
    if (isEmulator) issues.add('Running on emulator/simulator');
    if (canMockLocation) issues.add('Location spoofing is possible');
    if (isOnExternalStorage) issues.add('App installed on external storage');
    if (hasAdbEnabled) issues.add('ADB debugging is enabled');
    if (suspiciousApps.isNotEmpty) {
      issues.add('Suspicious apps detected: ${suspiciousApps.join(", ")}');
    }

    return issues;
  }

  Map<String, dynamic> toJson() => {
        'is_secure': isSecure,
        'security_score': securityScore,
        'is_jailbroken': isJailbroken,
        'is_developer_mode': isDeveloperMode,
        'is_emulator': isEmulator,
        'can_mock_location': canMockLocation,
        'is_on_external_storage': isOnExternalStorage,
        'has_adb_enabled': hasAdbEnabled,
        'suspicious_apps': suspiciousApps,
        'security_issues': securityIssues,
        'device_info': deviceInfo,
      };
}
