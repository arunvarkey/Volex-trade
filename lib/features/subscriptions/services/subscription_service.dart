import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:in_app_purchase_android/in_app_purchase_android.dart';
// import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:volex_terminal/features/subscriptions/models/subscription_tier.dart';
import 'package:volex_terminal/features/subscriptions/models/subscription_status.dart';
// import 'package:volex_terminal/features/trading/services/secure_trading_service.dart'; // Removed as Pro Mode is gone

import 'package:flutter/foundation.dart';
import 'package:volex_terminal/core/app_logger.dart';

class SubscriptionService extends ChangeNotifier {
  static const String googlePlayPublicKey =
      'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp8rHarIy5Xhthe99e59imTdOBLel8Okox+NrEvcPqn5f+TGcTMjEPZfPX1CRzSnmm/9U1yZe4RyNaabWj9aMA5Gi8NQy4O16igwKxNknj1+BIvUaFq3mX9HhTO8mPBueRsJNGHkfE7KhAhUNFw07DfZEpaKVD3lB/d2FTrMvab6fXCpxYOjk5KVtLFdsxTO6xYtSci3+YdXEKFidvciLjLwywb8q1Dq3NeXNx4CuzWrMgZP/5pAZD4NcNgcyVlVM6jhSOjcGO/Te/7+qRTNsxud8RDYEywwd54b5/g2NEms1lEAXz2r1ThDfXkVAA3jmM/PgFOjlhQ856MqYaN8r3wIDAQAB';

  final InAppPurchase _iap = InAppPurchase.instance;
  // Accessed lazily so construction never touches Firebase. On platforms where
  // Firebase isn't configured (e.g. web preview), these are simply never read
  // because IAP is unavailable and initialize() returns early.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Signed-in user id, or null when auth/Firebase is unavailable (e.g. web
  /// preview). Callers treat null as "no cloud usage tracking".
  String? get _safeUserId {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final _statusController = StreamController<SubscriptionStatus>.broadcast();

  SubscriptionStatus _currentStatus = SubscriptionStatus.free();

  Stream<SubscriptionStatus> get statusStream => _statusController.stream;
  SubscriptionStatus get currentStatus => _currentStatus;

  // New Getters for UI compatibility
  SubscriptionTier get currentTier => _currentStatus.tier;
  bool get isPremium => _currentStatus.isPremium;

  // Legacy getter for compatibility, though AI is now available to all (limited for free)

  int get maxStrategies => isPremium ? 999999 : 3;
  int get maxBacktests => isPremium ? 999999 : 1;
  int get maxSignals => isPremium ? 999999 : 10;

  // Initialize subscription service
  Future<void> initialize() async {
    AppLogger.info('💳 SubscriptionService: Initializing...');

    // In-app purchases aren't supported on web; default to the free tier so
    // the app can boot for preview without the IAP plugin.
    if (kIsWeb) {
      AppLogger.warning('🌐 Web: IAP unavailable, defaulting to free tier');
      _updateStatus(SubscriptionStatus.free());
      return;
    }

    // Check if IAP is available with timeout to prevent boot hang
    final available = await _iap.isAvailable().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        AppLogger.warning('⏳ IAP check timed out - defaulting to free');
        return false;
      },
    ).catchError((e) {
      AppLogger.error('❌ IAP check failed: $e');
      return false;
    });

    if (!available) {
      AppLogger.warning('⚠️  IAP not available on this device');
      _updateStatus(SubscriptionStatus.free());
      return;
    }

    // Setup purchase listener
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => AppLogger.error('❌ Purchase stream error: $error'),
    );

    // Restore previous purchases
    await restorePurchases();

    // Load current status from Firestore
    await _loadSubscriptionStatus();

    AppLogger.info('✅ SubscriptionService: Initialized');
  }

  // Helper to update status and notify
  void _updateStatus(SubscriptionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
    notifyListeners();
  }

  // Load subscription status from Firestore
  Future<void> _loadSubscriptionStatus() async {
    final userId = _safeUserId;
    if (userId == null) {
      _updateStatus(SubscriptionStatus.free());
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        final status = SubscriptionStatus.fromJson(doc.data()!);
        AppLogger.info('📊 Loaded subscription: ${status.tier}');
        _updateStatus(status);
      } else {
        _updateStatus(SubscriptionStatus.free());
      }
    } catch (e) {
      AppLogger.error('❌ Error loading subscription: $e');
      _updateStatus(SubscriptionStatus.free());
    }
  }

  // Get available products
  Future<List<ProductDetails>> getAvailableProducts() async {
    final productIds = <String>{
      SubscriptionProduct.explorerPremium.platformProductId,
      SubscriptionProduct.premiumYearly.platformProductId,
    };

    final response = await _iap.queryProductDetails(productIds);

    if (response.error != null) {
      AppLogger.error('❌ Error fetching products: ${response.error}');
      return [];
    }

    if (response.notFoundIDs.isNotEmpty) {
      AppLogger.warning('⚠️  Products not found: ${response.notFoundIDs}');
    }

    AppLogger.info('✅ Found ${response.productDetails.length} products');
    return response.productDetails;
  }

  // Purchase subscription
  Future<bool> purchaseSubscription(SubscriptionProduct product) async {
    try {
      // Get product details
      final products = await getAvailableProducts();
      final productDetails = products.firstWhere(
        (p) => p.id == product.platformProductId,
        orElse: () =>
            throw Exception('Product not found: ${product.platformProductId}'),
      );

      // Create purchase param
      final purchaseParam = PurchaseParam(productDetails: productDetails);

      // Start purchase
      AppLogger.info('💳 Starting purchase: ${product.name}');

      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      return success;
    } catch (e) {
      AppLogger.error('❌ Purchase error: $e');
      return false;
    }
  }

  // Handle purchase updates
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      AppLogger.info(
          '📱 Purchase update: ${purchase.productID} - ${purchase.status}');

      if (purchase.status == PurchaseStatus.pending) {
        // Show pending UI
        _showPendingUI();
      } else if (purchase.status == PurchaseStatus.error) {
        // Show error safely
        if (purchase.error != null) {
          _handlePurchaseError(purchase.error!);
        } else {
          AppLogger.error(
              '📱 Unknown purchase error for ${purchase.productID}');
        }
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify and grant subscription
        await _verifyAndGrantSubscription(purchase);
      }

      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  // Verify purchase with backend
  Future<void> _verifyAndGrantSubscription(PurchaseDetails purchase) async {
    try {
      AppLogger.info('🔐 Verifying purchase: ${purchase.productID}');

      // Get user ID
      final userId = _safeUserId;
      if (userId == null) {
        AppLogger.error('❌ No user logged in');
        return;
      }

      // Determine tier from product ID
      SubscriptionTier tier = SubscriptionTier.free;
      if (purchase.productID.contains('premium')) {
        tier = SubscriptionTier.explorerPremium;
      }

      // Create subscription record
      final subscriptionData = {
        'tier': tier.toString(),
        'is_active': true,
        'purchase_id': purchase.purchaseID,
        'product_id': purchase.productID,
        'purchase_date': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'receipt': purchase.verificationData.serverVerificationData,
      };

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .set(subscriptionData, SetOptions(merge: true));

      // Update local status
      final newStatus = SubscriptionStatus(
        tier: tier,
        isActive: true,
        purchaseDate: DateTime.now(),
        purchaseId: purchase.purchaseID,
      );
      _updateStatus(newStatus);

      // Log analytics
      await _analytics.logEvent(
        name: 'subscription_purchased',
        parameters: {
          'tier': tier.toString(),
          'product_id': purchase.productID,
        },
      );

      AppLogger.info('✅ Subscription granted: $tier');
    } catch (e) {
      AppLogger.error('❌ Error granting subscription: $e');
    }
  }

  // Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      AppLogger.info('🔄 Restoring purchases...');
      await _iap.restorePurchases();
    } catch (e) {
      AppLogger.error('❌ Error restoring purchases: $e');
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription() async {
    // Note: Actual cancellation happens through App Store/Play Store
    // This just updates our records
    final userId = _safeUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .update({
      'is_active': false,
      'cancelled_at': FieldValue.serverTimestamp(),
    });

    _updateStatus(SubscriptionStatus.free());
  }

  // Check if user has access to feature
  bool hasAccessTo(String feature) {
    if (_currentStatus.isPremium) return true;

    // Default to false for premium features if on free plan
    switch (feature) {
      case 'unlimited_signals':
      // Wire key, not a label: this string is stored in Remote Config
      // and in shipped analytics. The feature is now called trade
      // checks everywhere the user can see it; renaming the key would
      // reset the flag and split the event history.
      case 'ai_guardian':
      // 'advanced_analytics', 'custom_watchlists' and 'export_history'
      // used to be listed here and sold on the paywall. None of them is
      // implemented anywhere in the app, so gating them meant charging for
      // nothing. They are removed rather than left as dormant keys.
      case 'unlimited_strategies':
        return false;
      default:
        return true;
    }
  }

  // Check strategy generation limit
  Future<bool> checkAndTrackStrategyGeneration() async {
    if (_currentStatus.isPremium) return true;

    final todayCount = await _getDailyUsageCount('strategy_generations');
    if (todayCount >= 3) {
      AppLogger.warning('⚠️ Strategy limit reached');
      return false;
    }

    await _trackDailyUsage('strategy_generations');
    return true;
  }

  // Check backtest limit
  Future<bool> checkAndTrackBacktest() async {
    if (_currentStatus.isPremium) return true;

    final todayCount = await _getDailyUsageCount('backtest_runs');
    if (todayCount >= 1) {
      AppLogger.warning('⚠️ Backtest limit reached');
      return false;
    }

    await _trackDailyUsage('backtest_runs');
    return true;
  }

  // Generic daily usage tracker
  Future<void> _trackDailyUsage(String collectionName) async {
    final userId = _safeUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .add({
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Generic daily usage counter
  Future<int> _getDailyUsageCount(String collectionName) async {
    final userId = _safeUserId;
    if (userId == null) return 0;

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .where('created_at', isGreaterThanOrEqualTo: todayStart)
        .get();

    return snapshot.docs.length;
  }

  // Check signal limit for free users
  Future<bool> canViewMoreSignals() async {
    if (_currentStatus.isPremium) return true;

    // For free users, check daily limit
    final dailyCount = await getRemainingDailySignals();
    return dailyCount > 0;
  }

  // Get remaining signals for today
  Future<int> getRemainingDailySignals() async {
    if (_currentStatus.isPremium) return 999;

    final todayCount = await _getTodayViewCount();
    return 10 - todayCount; // 10 per day limit
  }

  // Get today's signal view count
  Future<int> _getTodayViewCount() async {
    // Reuse generic method
    return _getDailyUsageCount('signal_views');
  }

  // Track signal view and check limit
  Future<bool> checkAndTrackSignalView(String signalId) async {
    // Premium users have unlimited access
    if (_currentStatus.isPremium) {
      return true;
    }

    // Check if free user can view more signals
    final canView = await canViewMoreSignals();

    if (!canView) {
      AppLogger.warning('⚠️  Signal limit reached for free user');
      return false;
    }

    // Track this view
    await _trackDailyUsage('signal_views'); // Simplified tracking
    AppLogger.info('✅ Signal view tracked');

    return true;
  }

  // UI helpers
  void _showPendingUI() {
    AppLogger.info('⏳ Purchase pending...');
  }

  void _handlePurchaseError(IAPError error) {
    AppLogger.error('Purchase failed: ${error.message}');
  }

  @override
  void dispose() {
    _subscription.cancel();
    _statusController.close();
    super.dispose();
  }
}
