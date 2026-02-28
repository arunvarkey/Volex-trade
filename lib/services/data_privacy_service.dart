import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/core/services/auth/security_service.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/engine/execution_manager.dart';

/// Service for GDPR/CCPA Compliance.
class DataPrivacyService extends ChangeNotifier {
  static final DataPrivacyService _instance = DataPrivacyService._internal();
  factory DataPrivacyService() => _instance;
  DataPrivacyService._internal();

  bool _isPrivacyMode = false;
  bool _shareAnalytics = true;
  bool _shareCrashReports = true;

  bool get isPrivacyMode => _isPrivacyMode;
  bool get shareAnalytics => _shareAnalytics;
  bool get shareCrashReports => _shareCrashReports;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPrivacyMode = prefs.getBool('privacy_mode') ?? false;
    _shareAnalytics = prefs.getBool('share_analytics') ?? true;
    _shareCrashReports = prefs.getBool('share_crash_reports') ?? true;
    notifyListeners();
  }

  Future<void> setPrivacyMode(bool enabled) async {
    _isPrivacyMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_mode', enabled);
    notifyListeners();
    AppLogger.info('Privacy Mode set to: $enabled');
  }

  Future<void> updateConsent({
    bool? analytics,
    bool? crashReports,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (analytics != null) {
      _shareAnalytics = analytics;
      await prefs.setBool('share_analytics', analytics);
    }
    if (crashReports != null) {
      _shareCrashReports = crashReports;
      await prefs.setBool('share_crash_reports', crashReports);
    }
    notifyListeners();
  }

  /// Exports all available user data to a JSON file.
  Future<void> exportUserData() async {
    try {
      const String uid = "local_secure_user";
      const String email = "local_user@device";

      AppLogger.info("PRIVACY: Starting data export for $uid...");

      // 1. Aggregate Data
      // Mock execution manager data for now if not available
      List<Map<String, dynamic>> ordersList = [];
      try {
        final executionManager = getIt<ExecutionManager>();
        ordersList = executionManager.orders
            .map((o) => {
                  'id': o.id,
                  'symbol': o.symbol,
                  'side': o.side.toString(),
                  'size': o.quantity,
                  'price': o.price,
                  'timestamp': o.timestamp.toIso8601String(),
                })
            .toList();
      } catch (e) {
        // ExecutionManager might not be ready or registered
        AppLogger.warning("PRIVACY: Could not fetch orders for export: $e");
      }

      final exportData = {
        'user_profile': {
          'uid': uid,
          'email': email,
          'export_date': DateTime.now().toIso8601String(),
        },
        'preferences': {
          'privacy_mode': _isPrivacyMode,
          'share_analytics': _shareAnalytics,
        },
        'trading_history': ordersList,
      };

      // 2. Write to File
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/volex_user_data.json');
      await file.writeAsString(jsonString);

      // 3. Share File
      await Share.shareXFiles([XFile(file.path)],
          text: 'Your Volex Data Export');

      AppLogger.info("PRIVACY: Data export completed.");
    } catch (e) {
      AppLogger.error("PRIVACY: Data export failed: $e");
      rethrow;
    }
  }

  /// Permanently deletes the user's account and data.
  Future<void> deleteUserAccount() async {
    try {
      AppLogger.warning("PRIVACY: Starting account deletion...");
      await purgeAllData();
      AppLogger.info("PRIVACY: Account deletion completed.");
    } catch (e) {
      AppLogger.error("PRIVACY: Account deletion failed: $e");
      rethrow;
    }
  }

  Future<void> purgeAllData() async {
    AppLogger.warning('PURGING ALL USER DATA');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Reset Security Service
    try {
      final security = getIt<SecurityService>();
      await security.clearAuthData();
    } catch (e) {
      AppLogger.warning("Could not clear security data: $e");
    }

    _isPrivacyMode = false;
    notifyListeners();
  }
}
