import 'dart:async';
import '../../core/app_logger.dart';
import '../../domain/trade_signal.dart';
import '../../domain/order.dart';
import '../marketplace/marketplace_service.dart';
import '../execution_manager.dart';

/// Engine responsible for executing trades based on subscribed strategy signals.
class CopyTradingEngine {
  final MarketplaceService _marketplace;
  final ExecutionManager _executionManager;
  StreamSubscription? _signalSub;
  bool _isRunning = false;

  CopyTradingEngine(this._marketplace, this._executionManager);

  /// Start listening to signals and executing trades
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _marketplace.startSignalSimulation(); // Ensure signals are flowing

    _signalSub = _marketplace.signalStream.listen(_handleSignal);
    AppLogger.info("COPY_TRADING: Engine started. Listening for signals...");
  }

  /// Stop the engine
  void stop() {
    _signalSub?.cancel();
    _isRunning = false;
    AppLogger.info("COPY_TRADING: Engine stopped.");
  }

  /// Handle incoming trade signal
  Future<void> _handleSignal(TradeSignal signal) async {
    // 1. Verify subscription
    // Simplified: Check if any subscription matches by name (or ideally ID)
    // Since Mock signals use Name, we check by name
    bool isSubscribed = _marketplace.isSubscribedByName(signal.strategyName);

    if (!isSubscribed) {
      return;
    }

    AppLogger.info(
        "COPY_TRADING: Received signal from ${signal.strategyName}: ${signal.side} @ ${signal.price}");

    // 2. Execute Order
    try {
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        symbol: 'BTCUSDT', // Mock symbol
        side: signal.side,
        type: OrderType.market,
        quantity: 0.01, // Fixed size for now or % logic later
        price: signal.price,
        status: OrderStatus.pending,
        timestamp: DateTime.now(),
      );

      // We use placeOrder from ExecutionManager
      // Note: ExecutionManager might need to be adapted if it expects manual confirmation
      // For now, we assume it executes directly.

      // Since ExecutionManager.executeOrder returns void or Future, we just call it.
      await _executionManager.placeOrder(order);

      AppLogger.info(
          "COPY_TRADING: Executed copy trade for ${signal.strategyName}");
    } catch (e) {
      AppLogger.error("COPY_TRADING: Failed to execute signal", e);
    }
  }
}
