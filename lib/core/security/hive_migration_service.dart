import 'package:hive/hive.dart';
import '../../core/app_logger.dart';
import '../../core/security/encryption_key_service.dart';

class HiveMigrationService {
  static Future<void> migrateToEncrypted(List<String> boxNames) async {
    for (final boxName in boxNames) {
      if (await Hive.boxExists(boxName)) {
        try {
          // Attempt to open encrypted first - if it works, we are good
          final key = await EncryptionKeyService.getEncryptionKey();
          final cipher = HiveAesCipher(key);
          final box = await Hive.openBox(boxName, encryptionCipher: cipher);
          await box.close();
        } catch (e) {
          // If encrypted open fails, it might be unencrypted.
          // Warning: Hive throws specific errors.
          // If it's unencrypted, we need to read it raw, then re-write encrypted.

          AppLogger.info(
              "MIGRATION: Detected unencrypted box $boxName. Migrating...");

          try {
            // Open unencrypted
            final oldBox = await Hive.openBox(boxName);
            final Map<dynamic, dynamic> data = Map.from(oldBox.toMap());
            await oldBox.close();

            // Delete old file
            await oldBox.deleteFromDisk();

            // Re-open encrypted
            final key = await EncryptionKeyService.getEncryptionKey();
            final cipher = HiveAesCipher(key);
            final newBox =
                await Hive.openBox(boxName, encryptionCipher: cipher);

            // Restore data
            await newBox.putAll(data);
            await newBox.close();

            AppLogger.info("MIGRATION: $boxName migrated successfully.");
          } catch (migrateError) {
            AppLogger.error(
                "MIGRATION: Failed to migrate $boxName: $migrateError");
            // If migration fails, we might lose data, but security is priority.
            // We'll proceed to open empty encrypted box in main flow.
          }
        }
      }
    }
  }
}
