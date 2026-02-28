import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cloud_storage_service.dart';
import '../../engine/persistence/order_storage_service.dart';
import '../../engine/persistence/subscription_storage_service.dart';
import '../../engine/persistence/persistence_manager.dart'; // Day 35
import 'package:volex_terminal/domain/order.dart';
import '../subscription/strategy_subscription.dart'; // Model
import '../../core/app_logger.dart';

class SyncEngine extends ChangeNotifier {
  static SyncEngine? _instance;
  factory SyncEngine() => _instance ??= SyncEngine._internal();
  SyncEngine._internal() {
    _startAutoSync();
  }

  /// For testing: Reset the singleton state
  @visibleForTesting
  void reset({bool startTimer = false}) {
    _timer?.cancel();
    _isOffline = false;
    _isSyncing = false;
    _lastSyncTime = null;
    if (startTimer) {
      _startAutoSync();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  final CloudStorageService _cloud = CloudStorageService();
  final OrderStorageService _orderStorage = OrderStorageService();
  final SubscriptionStorageService _subStorage = SubscriptionStorageService();
  final PersistenceManager _persistence = PersistenceManager(); // Day 35

  bool _isOffline = false;
  bool _isSyncing = false;
  String? _lastSyncTime;

  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;
  String? get lastSyncTime => _lastSyncTime;

  // Auto-sync timer
  Timer? _timer;

  void _startAutoSync() {
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncAll();
    });
  }

  void setOfflineMode(bool enabled) {
    _isOffline = enabled;
    notifyListeners();
    if (!enabled) {
      syncAll(); // Try to sync immediately when coming online
    }
  }

  /// Main entry point to sync all data
  Future<void> syncAll() async {
    if (_isOffline) return;
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();
    AppLogger.info("SYNC: Starting full sync...");
    await _persistence.createBackup(); // Backup before merge

    try {
      await Future.wait([
        syncOrders(),
        syncSubscriptions(),
        // Add other syncs here (Strategies, Parameters, Profile)
      ]);
      _lastSyncTime = DateTime.now().toIso8601String();
      AppLogger.info("SYNC: Full sync completed at $_lastSyncTime");
    } catch (e) {
      AppLogger.error("SYNC: Error during sync: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Syncs Orders (Trade History)
  Future<void> syncOrders() async {
    if (_isOffline) return;
    const key = 'orders';

    // 1. Download
    final cloudData = await _cloud.download(key);
    List<Order> cloudOrders = [];
    if (cloudData != null && cloudData['orders'] != null) {
      cloudOrders =
          (cloudData['orders'] as List).map((o) => Order.fromJson(o)).toList();
    }

    // 2. Load Local
    final localOrders = await _orderStorage.getAllOrders();

    // 3. Conflict Resolution / Merging
    final mergedMap = <String, Order>{};

    for (var o in cloudOrders) {
      mergedMap[o.id] = o;
    }

    for (var o in localOrders) {
      if (mergedMap.containsKey(o.id)) {
        final existing = mergedMap[o.id]!;
        if (existing.status == OrderStatus.closed) {
          // Cloud has closed it, keep cloud
        } else if (o.status == OrderStatus.closed) {
          // Local has closed it, overwrite cloud entry in map
          mergedMap[o.id] = o;
        } else {
          mergedMap[o.id] = o;
        }
      } else {
        mergedMap[o.id] = o;
      }
    }

    final mergedList = mergedMap.values.toList();
    mergedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 4. Update Both Ends
    await _cloud
        .upload(key, {'orders': mergedList.map((o) => o.toJson()).toList()});

    await _orderStorage.saveAllOrders(mergedList);

    AppLogger.info("SYNC: Orders synced. Total: ${mergedList.length}");
  }

  Future<void> syncSubscriptions() async {
    if (_isOffline) return;
    const key = 'subscriptions';

    // 1. Download Cloud Subs
    final cloudData = await _cloud.download(key);
    List<StrategySubscription> cloudSubs = [];
    if (cloudData != null && cloudData['subscriptions'] != null) {
      cloudSubs = (cloudData['subscriptions'] as List)
          .map((s) => StrategySubscription.fromJson(s))
          .toList();
    }

    // 2. Load Local Subs
    final localSubs = await _subStorage.loadSubscriptions();

    // 3. Merge Logic
    final mergedMap = <String, StrategySubscription>{};

    String getCompositeKey(StrategySubscription s) =>
        "${s.subscriberUserId}_${s.strategyId}";

    for (var s in cloudSubs) {
      mergedMap[getCompositeKey(s)] = s;
    }

    for (var s in localSubs) {
      final k = getCompositeKey(s);
      if (mergedMap.containsKey(k)) {
        final existing = mergedMap[k]!;
        if (s.status == SubscriptionStatus.active &&
            existing.status != SubscriptionStatus.active) {
          mergedMap[k] = s;
        } else if (existing.status == SubscriptionStatus.active &&
            s.status != SubscriptionStatus.active) {
          // keep existing
        } else {
          if (s.renewalDate.isAfter(existing.renewalDate)) {
            mergedMap[k] = s;
          }
        }
      } else {
        mergedMap[k] = s;
      }
    }

    final mergedList = mergedMap.values.toList();

    // 4. Update Cloud & Local
    await _cloud.upload(
        key, {'subscriptions': mergedList.map((s) => s.toJson()).toList()});
    await _subStorage.saveSubscriptions(mergedList);

    AppLogger.info("SYNC: Subscriptions synced. Total: ${mergedList.length}");
  }

  void pushUpdate(String type) {
    // Triggers
  }
}
