import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/engine/persistence/persistence_service.dart';
import 'package:volex_terminal/engine/notifications/notification_model.dart';
import 'package:volex_terminal/core/service_locator.dart';

class NotificationBus {
  factory NotificationBus() => getIt<NotificationBus>();
  final PersistenceService _persistence;
  final List<VolexNotification> _history = [];
  final Uuid _uuid = const Uuid();
  final StreamController<VolexNotification> _controller =
      StreamController.broadcast();
  final StreamController<int> _unreadController = StreamController.broadcast();

  NotificationBus.inject(this._persistence) {
    _restore();
  }

  Stream<VolexNotification> get onNotification => _controller.stream;
  List<VolexNotification> get history => List.unmodifiable(_history);

  final StreamController<List<VolexNotification>> _listController =
      StreamController.broadcast();

  Stream<List<VolexNotification>> get historyStream => _listController.stream;
  Stream<int> get unreadCountStream => _unreadController.stream;

  Future<void> _restore() async {
    try {
      final storedRaw =
          _persistence.getList(PersistenceService.notificationsBoxName);
      if (storedRaw.isNotEmpty) {
        _history.clear();
        for (var raw in storedRaw) {
          if (raw is Map) {
            final castedMap = Map<String, dynamic>.from(raw);
            _history.add(VolexNotification.fromJson(castedMap));
          }
        }
        // Sort desc by time (most recent first)
        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _updateStreams();
        AppLogger.info(
            "NOTIF: Restored ${_history.length} notifications from Hive.");
      }
    } catch (e) {
      AppLogger.error("NOTIF: Restore failed: $e");
    }
  }

  void publish({
    required NotificationType type,
    required NotificationSeverity severity,
    required String title,
    required String message,
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    try {
      final note = VolexNotification(
        id: _uuid.v4(),
        type: type,
        severity: severity,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        userId: userId,
        metadata: metadata,
      );

      _history.insert(0, note);
      if (_history.length > 50) {
        _history.removeLast();
      }

      _controller.add(note);
      _updateStreams();
      _persistDebounced();

      AppLogger.info("NOTIF: [${type.name.toUpperCase()}] $title - $message");
    } catch (e, stack) {
      AppLogger.error("NOTIF: Publish failed: $e\n$stack");
    }
  }

  Timer? _debounceTimer;
  void _persistDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _persist();
    });
  }

  Future<void> markAsRead(String id) async {
    final index = _history.indexWhere((n) => n.id == id);
    if (index != -1) {
      _history[index].isRead = true;
      _updateStreams();
      await _persist();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    bool changed = false;
    for (var note in _history) {
      if (note.userId == userId && !note.isRead) {
        note.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      _updateStreams();
      await _persist();
    }
  }

  void _updateStreams() {
    _updateUnreadCount();
    _listController.add(List.unmodifiable(_history));
  }

  void _updateUnreadCount() {
    final count = _history.where((n) => !n.isRead).length;
    _unreadController.add(count);
  }

  Future<void> _persist() async {
    final jsonList = _history.map((n) => n.toJson()).toList();
    await _persistence.saveList(
        PersistenceService.notificationsBoxName, jsonList);
  }

  void remove(String id) {
    _history.removeWhere((n) => n.id == id);
    _updateStreams();
    _persistDebounced();
  }

  void add(VolexNotification notification) {
    _history.insert(0, notification);
    _updateStreams();
    _persistDebounced();
  }

  void clearAll() {
    _history.clear();
    _updateStreams();
    _persist();
  }

  void clear() {
    clearAll();
  }

  void dispose() {
    _controller.close();
    _debounceTimer?.cancel();
    _unreadController.close();
  }
}
