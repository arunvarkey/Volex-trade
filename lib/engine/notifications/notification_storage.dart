import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/app_logger.dart';
import 'notification_model.dart';

class NotificationStorageService {
  static NotificationStorageService? _instance;
  factory NotificationStorageService() =>
      _instance ??= NotificationStorageService._internal();
  NotificationStorageService._internal();

  File? _file;

  Future<File> get _localFile async {
    if (_file != null) return _file!;
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/notifications.json');
    return _file!;
  }

  /// Loads all notifications
  Future<List<VolexNotification>> loadNotifications() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => VolexNotification.fromJson(j)).toList();
    } catch (e) {
      AppLogger.error("NotificationStorage: Error loading: $e");
      return [];
    }
  }

  /// Saves a list of notifications (overwrite)
  Future<void> saveNotifications(List<VolexNotification> notifications) async {
    final file = await _localFile;
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}
