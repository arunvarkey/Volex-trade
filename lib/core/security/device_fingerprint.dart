import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceFingerprint {
  static String? _cachedFingerprint;
  static Map<String, dynamic>? _cachedDeviceInfo;

  /// Generate unique device fingerprint
  static Future<String> generateFingerprint() async {
    if (_cachedFingerprint != null) {
      return _cachedFingerprint!;
    }

    final deviceInfo = await collectDeviceInfo();

    // Combine all device info into a unique string
    final fingerprintData = {
      'model': deviceInfo['model'],
      'manufacturer': deviceInfo['manufacturer'],
      'os_version': deviceInfo['os_version'],
      'device_id': deviceInfo['device_id'],
      'screen_resolution': deviceInfo['screen_resolution'],
      'timezone': deviceInfo['timezone'],
      'locale': deviceInfo['locale'],
    };

    // Create hash of device data
    final dataString =
        fingerprintData.entries.map((e) => '${e.key}:${e.value}').join('|');

    final hash = sha256.convert(utf8.encode(dataString));
    _cachedFingerprint = hash.toString();

    SecureLogger.info('Device fingerprint generated');

    return _cachedFingerprint!;
  }

  /// Collect detailed device information
  static Future<Map<String, dynamic>> collectDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    final deviceInfoPlugin = DeviceInfoPlugin();
    final info = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;

        info['platform'] = 'android';
        info['model'] = androidInfo.model;
        info['manufacturer'] = androidInfo.manufacturer;
        info['brand'] = androidInfo.brand;
        info['device'] = androidInfo.device;
        info['os_version'] = androidInfo.version.release;
        info['sdk_int'] = androidInfo.version.sdkInt;
        info['device_id'] = androidInfo.id;
        info['is_physical'] = androidInfo.isPhysicalDevice;
        info['hardware'] = androidInfo.hardware;
        info['product'] = androidInfo.product;
        info['fingerprint'] = androidInfo.fingerprint;
        info['supported_abis'] = androidInfo.supportedAbis.join(',');
        // info['screen_resolution'] = '${androidInfo.displayMetrics.widthPx}x${androidInfo.displayMetrics.heightPx}';
        // info['screen_density'] = androidInfo.displayMetrics.densityDpi;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;

        info['platform'] = 'ios';
        info['model'] = iosInfo.model;
        info['manufacturer'] = 'Apple';
        info['name'] = iosInfo.name;
        info['os_version'] = iosInfo.systemVersion;
        info['device_id'] =
            iosInfo.identifierForVendor ?? await _generatePersistentId();
        info['is_physical'] = iosInfo.isPhysicalDevice;
        info['system_name'] = iosInfo.systemName;
        info['utsname_machine'] = iosInfo.utsname.machine;
        info['utsname_sysname'] = iosInfo.utsname.sysname;
      }

      // Add common info
      info['timezone'] = DateTime.now().timeZoneName;
      info['timezone_offset'] = DateTime.now().timeZoneOffset.inMinutes;
      info['locale'] = Platform.localeName;

      _cachedDeviceInfo = info;

      SecureLogger.debug('Device info collected', data: {
        'platform': info['platform'],
        'model': info['model'],
      });
    } catch (e) {
      SecureLogger.error('Failed to collect device info',
          data: {'error': e.toString()});
      rethrow;
    }

    return info;
  }

  /// Generate and persist a unique device ID
  static Future<String> _generatePersistentId() async {
    final prefs = await SharedPreferences.getInstance();

    var deviceId = prefs.getString('persistent_device_id');

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('persistent_device_id', deviceId);
      SecureLogger.info('Generated new persistent device ID');
    }

    return deviceId;
  }

  /// Verify device fingerprint matches stored fingerprint
  static Future<bool> verifyFingerprint(String storedFingerprint) async {
    final currentFingerprint = await generateFingerprint();

    final matches = currentFingerprint == storedFingerprint;

    if (!matches) {
      SecureLogger.critical(
        'Device fingerprint mismatch!',
        data: {
          'expected': storedFingerprint.substring(0, 16),
          'actual': currentFingerprint.substring(0, 16),
        },
      );
    }

    return matches;
  }

  /// Detect if device characteristics have changed suspiciously
  static Future<DeviceChangeReport> detectChanges(
      Map<String, dynamic> previousInfo) async {
    final currentInfo = await collectDeviceInfo();

    final changes = <String>[];
    final suspiciousChanges = <String>[];

    // Check for critical changes
    if (currentInfo['device_id'] != previousInfo['device_id']) {
      suspiciousChanges.add('Device ID changed');
    }

    if (currentInfo['model'] != previousInfo['model']) {
      suspiciousChanges.add('Device model changed');
    }

    if (currentInfo['manufacturer'] != previousInfo['manufacturer']) {
      suspiciousChanges.add('Manufacturer changed');
    }

    // Check for normal changes
    if (currentInfo['os_version'] != previousInfo['os_version']) {
      changes.add('OS version updated');
    }

    if (currentInfo['timezone'] != previousInfo['timezone']) {
      changes.add('Timezone changed');
    }

    final isSuspicious = suspiciousChanges.isNotEmpty;

    if (isSuspicious) {
      SecureLogger.critical(
        'Suspicious device changes detected',
        data: {'changes': suspiciousChanges},
      );
    } else if (changes.isNotEmpty) {
      SecureLogger.info('Device changes detected', data: {'changes': changes});
    }

    return DeviceChangeReport(
      hasChanges: changes.isNotEmpty || suspiciousChanges.isNotEmpty,
      changes: changes,
      suspiciousChanges: suspiciousChanges,
      isSuspicious: isSuspicious,
    );
  }

  /// Get device risk score based on characteristics
  static Future<int> calculateRiskScore() async {
    final info = await collectDeviceInfo();
    int riskScore = 0;

    // Risk factors
    if (info['is_physical'] == false) {
      riskScore += 50; // Emulator
    }

    if (info['platform'] == 'android') {
      // Check for signs of rooting
      if (await File('/system/app/Superuser.apk').exists()) {
        riskScore += 30;
      }
    }

    // Low OS version (more vulnerable)
    if (info['platform'] == 'android') {
      final sdkInt = info['sdk_int'] as int?;
      if (sdkInt != null && sdkInt < 26) {
        // Android 8.0
        riskScore += 20;
      }
    }

    return riskScore.clamp(0, 100);
  }

  /// Clear cached data
  static void clearCache() {
    _cachedFingerprint = null;
    _cachedDeviceInfo = null;
  }
}

class DeviceChangeReport {
  final bool hasChanges;
  final List<String> changes;
  final List<String> suspiciousChanges;
  final bool isSuspicious;

  DeviceChangeReport({
    required this.hasChanges,
    required this.changes,
    required this.suspiciousChanges,
    required this.isSuspicious,
  });

  Map<String, dynamic> toJson() => {
        'has_changes': hasChanges,
        'changes': changes,
        'suspicious_changes': suspiciousChanges,
        'is_suspicious': isSuspicious,
      };
}
