import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/app_logger.dart';

/// Centralized manager for file persistence hardening.
/// Responsibilities:
/// - Backup/Restore
/// - Corruption checks (Basic)
/// - Schema Versioning (Placeholder)
class PersistenceManager {
  static PersistenceManager? _instance;
  factory PersistenceManager() => _instance ??= PersistenceManager._internal();
  PersistenceManager._internal();

  Future<void> createBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create();
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filesToBackup = [
        'orders.json',
        'subscriptions.json',
        'revenue.json',
        'notifications.json'
      ];

      for (var fName in filesToBackup) {
        final origin = File('${dir.path}/$fName');
        if (await origin.exists()) {
          await origin.copy('${backupDir.path}/${fName}_$timestamp.bak');
        }
      }
      AppLogger.info("PERSISTENCE: Backup created for $timestamp");
    } catch (e) {
      AppLogger.error("PERSISTENCE: Backup failed: $e");
    }
  }

  Future<void> restoreLastBackup() async {
    // Logic to find latest backup and overwrite current files
    // Not auto-implemented for MVP safety, but infrastructure is here.
    AppLogger.info(
        "PERSISTENCE: Restore requested (Manual override required).");
  }

  // Hardening: Verify JSON integrity
  Future<bool> verifyIntegrity(File file) async {
    if (!await file.exists()) return true;
    try {
      final content = await file.readAsString();
      // Try verify end of file or checksum if we had one
      return content.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
