import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'secure_persistence_service.dart';
import '../../core/app_logger.dart';
import '../../core/service_locator.dart';

import '../../core/security/encryption_key_service.dart';
import '../../core/security/hive_migration_service.dart';

class PersistenceService {
  factory PersistenceService() => getIt<PersistenceService>();
  final SharedPreferences _prefs;

  PersistenceService.inject({required SharedPreferences prefs})
      : _prefs = prefs;

  static const String settingsBoxName = 'settings';
  static const String stateBoxName = 'app_state';
  static const String notificationsBoxName = 'notifications';
  static const String analyticsBoxName = 'analytics';

  final secure = SecurePersistenceService();

  Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      final boxes = [
        settingsBoxName,
        stateBoxName,
        notificationsBoxName,
        analyticsBoxName,
      ];

      // 1. Migrate any unencrypted data
      await HiveMigrationService.migrateToEncrypted(boxes);

      // 2. Get Encryption Key
      final key = await EncryptionKeyService.getEncryptionKey();
      final cipher = HiveAesCipher(key);

      // 3. Open Encrypted
      await Future.wait([
        Hive.openBox(settingsBoxName, encryptionCipher: cipher),
        Hive.openBox(stateBoxName, encryptionCipher: cipher),
        Hive.openBox(notificationsBoxName, encryptionCipher: cipher),
        Hive.openBox(analyticsBoxName, encryptionCipher: cipher),
      ]);
      AppLogger.info("PERSISTENCE: Hive initialized (Encrypted).");
    } catch (e) {
      AppLogger.error("PERSISTENCE: Initialization failed: $e");
      rethrow; // Critical failure if persistence doesn't load
    }
  }

  // --- SharedPreferences Helpers ---
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  // --- Settings Persistence ---

  Future<void> saveSetting<T>(String key, T value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final box = Hive.box(settingsBoxName);
      final value = box.get(key, defaultValue: defaultValue);
      if (value == null) return defaultValue;
      if (value is! T) {
        AppLogger.warning(
            "PERSISTENCE: Type mismatch for $key. Expected $T but got ${value.runtimeType}. Returning default.");
        return defaultValue;
      }
      return value;
    } catch (e) {
      AppLogger.error("PERSISTENCE: getSetting failed for $key: $e");
      return defaultValue;
    }
  }

  // --- App State Persistence ---

  Future<void> saveState<T>(String key, T value) async {
    final box = Hive.box(stateBoxName);
    await box.put(key, value);
  }

  T? getState<T>(String key, {T? defaultValue}) {
    try {
      final box = Hive.box(stateBoxName);
      final value = box.get(key, defaultValue: defaultValue);
      if (value == null) return defaultValue;
      if (value is! T) {
        AppLogger.warning(
            "PERSISTENCE: State type mismatch for $key. Returning default.");
        return defaultValue;
      }
      return value;
    } catch (e) {
      AppLogger.error("PERSISTENCE: getState failed for $key: $e");
      return defaultValue;
    }
  }

  // --- List/Collection Persistence (e.g., Notifications) ---

  Future<void> saveList(String boxName, List<dynamic> items) async {
    final box = Hive.box(boxName);
    await box.clear();
    await box.addAll(items);
  }

  List<dynamic> getList(String boxName) {
    final box = Hive.box(boxName);
    return box.values.toList();
  }

  // --- Global Ops ---

  Future<void> clearAll() async {
    await Future.wait([
      Hive.box(settingsBoxName).clear(),
      Hive.box(stateBoxName).clear(),
      Hive.box(notificationsBoxName).clear(),
      Hive.box(analyticsBoxName).clear(),
    ]);
    AppLogger.info("PERSISTENCE: All storage cleared.");
  }

  Future<void> flushState() async {
    // Hive automatically saves, but we can compact/flush to be sure
    try {
      await Future.wait([
        Hive.box(settingsBoxName).compact(),
        Hive.box(stateBoxName).compact(),
      ]);
    } catch (e) {
      AppLogger.error("PERSISTENCE: saveState failed: $e");
    }
  }
}
