import 'dart:async';
import '../../core/app_logger.dart';

enum SyncStatus { idle, syncing, success, error }

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  Timer? _syncTimer;

  void init() {
    // Start periodic "sync" every 2 minutes
    _syncTimer =
        Timer.periodic(const Duration(minutes: 2), (_) => triggerSync());
  }

  Future<void> triggerSync() async {
    if (_currentStatus == SyncStatus.syncing) return;

    _updateStatus(SyncStatus.syncing);
    AppLogger.info("CLOUD_SYNC: Starting background synchronization...");

    // Simulate network latency
    await Future.delayed(const Duration(seconds: 3));

    // In a real app, we would gather all local Hive data and push to REST/GraphQL
    // For now, we just pretend it worked.
    _updateStatus(SyncStatus.success);
    AppLogger.info("CLOUD_SYNC: Sync complete. All state pushed to cloud.");

    // Return to idle after a few seconds
    await Future.delayed(const Duration(seconds: 5));
    _updateStatus(SyncStatus.idle);
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _syncTimer?.cancel();
    _statusController.close();
  }
}
