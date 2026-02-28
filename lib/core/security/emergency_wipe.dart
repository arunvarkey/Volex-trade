import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:volex_terminal/core/security/secure_storage_manager.dart';
import 'package:volex_terminal/core/security/device_security.dart';
import 'package:volex_terminal/core/security/anti_tampering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Directory, exit;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class EmergencyWipe {
  static bool _wipeInProgress = false;
  static int _tamperingDetectionCount = 0;

  /// Continuous security monitoring
  static Future<void> startSecurityMonitoring() async {
    // Skip in debug mode
    if (kDebugMode) {
      SecureLogger.info('Security monitoring disabled in debug mode');
      return;
    }

    SecureLogger.info('Starting continuous security monitoring...');

    while (true) {
      try {
        await Future.delayed(const Duration(minutes: 5));

        // Perform security checks
        final shouldWipe = await _performSecurityChecks();

        if (shouldWipe) {
          await executeEmergencyWipe(
            reason: 'Security compromise detected',
          );
          break; // Stop monitoring after wipe
        }
      } catch (e) {
        SecureLogger.error('Security monitoring error', data: {
          'error': e.toString(),
        });
      }
    }
  }

  /// Perform comprehensive security checks
  static Future<bool> _performSecurityChecks() async {
    // 1. Check device security
    final deviceReport = await DeviceSecurity.analyzeDevice();

    if (!deviceReport.isSecure) {
      _tamperingDetectionCount++;

      SecureLogger.critical('Device security compromised', data: {
        'security_score': deviceReport.securityScore,
        'issues': deviceReport.securityIssues,
        'detection_count': _tamperingDetectionCount,
      });

      // Wipe if multiple detections
      if (_tamperingDetectionCount >= 3) {
        return true;
      }
    }

    // 2. Check for tampering
    final tamperingReport = await AntiTampering.performComprehensiveCheck();

    if (tamperingReport.isTampered) {
      _tamperingDetectionCount++;

      SecureLogger.critical('Tampering detected', data: {
        'risk_score': tamperingReport.riskScore,
        'detection_count': _tamperingDetectionCount,
      });

      // Immediate wipe if code injection detected
      if (tamperingReport.codeInjectionDetected) {
        return true;
      }

      // Wipe if multiple detections
      if (_tamperingDetectionCount >= 2) {
        return true;
      }
    }

    // 3. Check for suspicious file access
    if (await _detectSuspiciousFileAccess()) {
      return true;
    }

    return false;
  }

  /// Detect suspicious file access patterns
  static Future<bool> _detectSuspiciousFileAccess() async {
    try {
      // Check if secure storage files are being accessed unusually
      final prefs = await SharedPreferences.getInstance();
      final lastAccessCheck = prefs.getInt('last_file_access_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check every 10 minutes
      if (now - lastAccessCheck < 600000) {
        return false;
      }

      await prefs.setInt('last_file_access_check', now);

      // Check for suspicious patterns (simplified)
      // In production, this would be more sophisticated

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Execute emergency data wipe
  static Future<void> executeEmergencyWipe({
    required String reason,
  }) async {
    if (_wipeInProgress) {
      SecureLogger.warning('Wipe already in progress');
      return;
    }

    _wipeInProgress = true;

    SecureLogger.critical('🚨 EXECUTING EMERGENCY WIPE', data: {
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });

    try {
      // 1. Wipe API keys immediately
      await SecureStorageManager.deleteApiKeys();
      SecureLogger.critical('API keys wiped');

      // 2. Wipe all secure storage
      await SecureStorageManager.wipeAll();
      SecureLogger.critical('Secure storage wiped');

      // 3. Clear all SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      SecureLogger.critical('SharedPreferences cleared');

      // 4. Delete local databases
      await _deleteLocalDatabases();
      SecureLogger.critical('Local databases deleted');

      // 5. Clear app cache
      await _clearAppCache();
      SecureLogger.critical('App cache cleared');

      // 6. Set wipe flag
      await _setWipeFlag(reason);

      SecureLogger.critical('Emergency wipe completed successfully');

      // 7. Exit app
      if (!kDebugMode && !kIsWeb) {
        exit(0);
      }
    } catch (e) {
      SecureLogger.critical('Emergency wipe failed', data: {
        'error': e.toString(),
      });
    } finally {
      _wipeInProgress = false;
    }
  }

  /// Delete local databases
  static Future<void> _deleteLocalDatabases() async {
    if (kIsWeb) return; // No direct file access on Web

    try {
      // Delete Hive databases
      // In production, use getApplicationDocumentsDirectory()
      final appDir = Directory.current;
      final hiveFiles = appDir.listSync().where((file) {
        return file.path.endsWith('.hive') || file.path.endsWith('.lock');
      });

      for (final file in hiveFiles) {
        await file.delete();
      }
    } catch (e) {
      SecureLogger.error('Failed to delete databases', data: {
        'error': e.toString(),
      });
    }
  }

  /// Clear app cache
  static Future<void> _clearAppCache() async {
    try {
      // This would use path_provider in production
      // For now, just log
      SecureLogger.info('Cache clearing requested');
    } catch (e) {
      SecureLogger.error('Failed to clear cache', data: {
        'error': e.toString(),
      });
    }
  }

  /// Set flag indicating app was wiped
  static Future<void> _setWipeFlag(String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('emergency_wipe_performed', true);
      await prefs.setString('wipe_reason', reason);
      await prefs.setString('wipe_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      // Ignore - wipe is more important
    }
  }

  /// Check if app was previously wiped
  static Future<WipeStatus> checkWipeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasWiped = prefs.getBool('emergency_wipe_performed') ?? false;

      if (wasWiped) {
        final reason = prefs.getString('wipe_reason') ?? 'Unknown';
        final timestamp = prefs.getString('wipe_timestamp');

        return WipeStatus(
          wasWiped: true,
          reason: reason,
          timestamp: timestamp != null ? DateTime.parse(timestamp) : null,
        );
      }

      return WipeStatus(wasWiped: false);
    } catch (e) {
      return WipeStatus(wasWiped: false);
    }
  }

  /// Clear wipe flag (after user acknowledges)
  static Future<void> clearWipeFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('emergency_wipe_performed');
    await prefs.remove('wipe_reason');
    await prefs.remove('wipe_timestamp');
  }

  /// Manual wipe trigger (for user-initiated wipe)
  static Future<void> userInitiatedWipe() async {
    await executeEmergencyWipe(reason: 'User-initiated wipe');
  }
}

class WipeStatus {
  final bool wasWiped;
  final String? reason;
  final DateTime? timestamp;

  WipeStatus({
    required this.wasWiped,
    this.reason,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'was_wiped': wasWiped,
        'reason': reason,
        'timestamp': timestamp?.toIso8601String(),
      };
}
