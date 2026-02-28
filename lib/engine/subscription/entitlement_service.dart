import 'package:flutter/foundation.dart';
import '../access_control_service.dart';
import '../strategy/strategy_metadata.dart';
import '../persistence/subscription_storage_service.dart';
import 'strategy_subscription.dart';
import 'creator_revenue_record.dart';
import '../notifications/notification_bus.dart';
import '../notifications/notification_model.dart';
import '../sync/sync_engine.dart'; // Day 35
import '../../core/app_logger.dart';

class EntitlementService {
  static final EntitlementService _instance = EntitlementService._internal();
  factory EntitlementService() => _instance;
  EntitlementService._internal() {
    _restoreState();
  }

  AccessControlService get _accessControl => AccessControlService();
  SubscriptionStorageService get _storage => SubscriptionStorageService();
  NotificationBus get _bus => NotificationBus();
  SyncEngine get _sync => SyncEngine();

  // In-memory store: UserId -> List<Subscriptions>
  final Map<String, List<StrategySubscription>> _subscriptions = {};

  // Revenue Store
  final List<CreatorRevenueRecord> _revenueRecords = [];

  Future<void> _restoreState() async {
    final subs = await _storage.loadSubscriptions();
    for (var sub in subs) {
      _subscriptions.putIfAbsent(sub.subscriberUserId, () => []).add(sub);
    }

    final revenue = await _storage.loadRevenueRecords();
    _revenueRecords.addAll(revenue);

    AppLogger.info(
        "ENTITLEMENT: Restored ${subs.length} subscriptions and ${revenue.length} revenue records.");
  }

  bool hasAccess(String userId, StrategyMetadata strategy) {
    // 1. Operators always have access
    if (_accessControl.currentRole == UserRole.operator) return true;

    // 2. Free strategies are accessible to all
    if (!strategy.isPaid) return true;

    // 3. Check for Active Subscription
    final userSubs = _subscriptions[userId] ?? [];
    return userSubs.any((s) => s.strategyId == strategy.id && s.isActive);
  }

  Future<void> subscribe(String userId, StrategyMetadata strategy) async {
    if (!_accessControl.canSubscribeToStrategies) {
      throw Exception("User permission denied: cannot subscribe.");
    }

    // Determine price (Monthly default for MVP)
    double price = strategy.monthlyPrice;

    // Create Subscription
    final newSub = StrategySubscription(
      strategyId: strategy.id,
      subscriberUserId: userId,
      startDate: DateTime.now(),
      renewalDate: DateTime.now().add(const Duration(days: 30)),
      status: SubscriptionStatus.active,
      price: price,
    );

    _subscriptions.putIfAbsent(userId, () => []).add(newSub);

    // Save Persistence
    final allSubs = _subscriptions.values.expand((element) => element).toList();
    await _storage.saveSubscriptions(allSubs);

    // Day 34: Notification
    _bus.publish(
      type: NotificationType.user,
      severity: NotificationSeverity.info,
      title: "Subscription Active",
      message: "You have successfully subscribed to ${strategy.name}.",
      userId: userId,
    );

    // Day 35: Sync
    _sync.syncSubscriptions();

    // Record Revenue (70/30 split mocked)
    final revenue = price * 0.70;
    final record = CreatorRevenueRecord(
      strategyId: strategy.id,
      creatorUserId: strategy.author,
      subscriberUserId: userId,
      period: DateTime.now(),
      amount: revenue,
    );
    _revenueRecords.add(record);
    await _storage.saveRevenueRecords(_revenueRecords);

    AppLogger.info(
        "ENTITLEMENT: Subscribed $userId to ${strategy.name}. Revenue recorded: $revenue");
  }

  // Debug/Test helper
  @visibleForTesting
  void reset() {
    _subscriptions.clear();
    _revenueRecords.clear();
  }
}
