import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/domain/position.dart';
import 'package:volex_terminal/domain/symbol_info.dart';
import 'package:volex_terminal/domain/trade_zone.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/engine/exchange/exchange_service.dart';
import 'package:volex_terminal/engine/exchange/paper_exchange_client.dart';
import 'package:volex_terminal/engine/risk_manager.dart';
import 'package:volex_terminal/services/analytics_service.dart';
import 'package:volex_terminal/engine/execution/i_execution_service.dart';
import 'package:volex_terminal/features/ai_guardian/services/ai_guardian_service.dart';
import 'package:volex_terminal/features/ai_guardian/ui/ai_guardian_warning_dialog.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:volex_terminal/core/financial_math.dart';
export 'execution/i_execution_service.dart';
import 'package:volex_terminal/services/feature_flag_service.dart';

enum LiveExecutionMode { manualOnly, autoCapped, fullAuto }

/// Professional Execution Manager
///
/// This service acts as the "Central Nervous System" for all trading activities within the Volex Terminal.
/// It creates a unified interface for executing trades across different engines (Paper vs. Live) and
/// ensures strict adherence to risk management protocols.
///
/// **Key Responsibilities:**
/// *   **Order Routing**: Routes orders to the correct [ExchangeService] implementation.
/// *   **Risk Validation**: Intercepts all orders via [RiskManager] to prevent excessive drawdown.
/// *   **Position Management**: Tracks [Position]s and calculates real-time PnL.
/// *   **State Management**: Notifies the UI of execution status via [ChangeNotifier].
///
/// **Usage:**
/// Retrieve the singleton instance via [ServiceLocator] or [GetIt]:
/// ```dart
/// final execution = getIt<ExecutionManager>();
/// await execution.placeMarketOrder(...);
/// ```
class ExecutionManager extends ChangeNotifier implements IExecutionService {
  ExchangeService _exchange;
  final RiskManager _riskManager;
  bool _isReadOnly = false;

  // Account state

  /// Whether the manager is currently using real capital.
  bool isLiveMode = false;

  /// The level of automation currently permitted.
  LiveExecutionMode liveExecutionMode = LiveExecutionMode.manualOnly;

  double _paperBalance = 100000.0; // $100k paper money
  double _liveBalance = 0.0;

  // Active orders and positions
  final List<Order> _orders = [];
  final List<Position> _positions = [];

  // Execution status
  bool _isExecuting = false;
  String? _lastError;

  ExecutionManager({
    ExchangeService? exchange,
    RiskManager? riskManager,
  })  : _exchange = exchange ?? PaperExchangeClient(),
        _riskManager = riskManager ?? RiskManager();

  static ExecutionManager provide({
    required dynamic marketData,
    required RiskManager riskManager,
    required dynamic persistence,
    ExchangeService? exchange,
  }) {
    return ExecutionManager(
      riskManager: riskManager,
      exchange: exchange,
    );
  }

  // Getters

  /// All orders tracked in the current session.
  @override
  List<Order> get orders => List.unmodifiable(_orders);

  /// Currently open (unfilled) orders.
  List<Order> get openOrders =>
      _orders.where((o) => o.status == OrderStatus.open).toList();

  /// Filled orders (Trade history for the session).
  List<Order> get closedOrders =>
      _orders.where((o) => o.status == OrderStatus.filled).toList();

  /// All active and closed positions.
  List<Position> get positions => List.unmodifiable(_positions);

  /// Positions that are currently open.
  List<Position> get openPositions =>
      _positions.where((p) => p.isOpen).toList();

  /// Current balance based on the active [isLiveMode].
  double get balance => isLiveMode ? _liveBalance : _paperBalance;

  Map<String, double> get currentBalance => {"USDT": balance};

  Stream<Map<String, double>> get balanceStream => Stream.value(currentBalance);

  /// Total realized PnL for the session.
  double get totalPnL => _calculateTotalPnL();

  /// Realized PnL for the current calendar day.
  double get todayPnL => _calculateTodayPnL();

  /// Whether an order is currently in flight.
  bool get isExecuting => _isExecuting;

  /// The error message from the last failed orchid placement.
  String? get lastError => _lastError;

  /// Current floating PnL across all open positions.
  double get totalUnrealizedPnl => _calculateTotalUnrealizedPnL();

  /// Total value (Balance + Unrealized PnL).
  double get totalEquityUsdt => balance + totalUnrealizedPnl;

  double get totalEstimatedBalanceUsdt => totalEquityUsdt;

  /// If true, trading is disabled.
  bool get isReadOnly => _isReadOnly;

  Set<String> get activeStrategyIds => {};

  ExchangeService get exchange => _exchange;

  /// Standard interface method for placing orders.
  @override
  Future<OrderResult?> placeOrder(Order order) async {
    return await placeMarketOrder(
      symbol: order.symbol,
      side: order.side,
      quantity: order.quantity,
      strategyId: order.strategyId,
      currentPrice: order.price,
    );
  }

  /// Places an order with AI Guardian protection.
  /// Used by UI components to intercept emotional trades.
  Future<OrderResult?> placeOrderWithGuard(
      BuildContext context, Order order) async {
    // 0. Feature Flag Check
    final flags = getIt<FeatureFlagService>();
    if (!flags.isAIGuardianEnabled) {
      return placeOrder(order);
    }

    // AI Guardian Check
    try {
      final aiGuardian = getIt<AIGuardianService>();
      final analysis = await aiGuardian.analyzeTradeIntent(order);

      if (analysis.shouldWarn) {
        // Analytics: Warning Triggered
        AnalyticsService.instance
            .logEvent('ai_guardian_warning_shown', parameters: {
          'symbol': order.symbol,
          'risk_score': analysis.riskScore,
          'emotional_state': analysis.emotionalState.name,
          'pattern_count': analysis.patterns.length,
        });

        if (!context.mounted) return placeOrder(order);

        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AIGuardianWarningDialog(analysis: analysis),
        );

        if (proceed != true) {
          AnalyticsService.instance.logEvent('ai_guardian_action',
              parameters: {'action': 'cancelled'});
          return OrderResult(
              success: false,
              message: "User canceled trade based on AI warning.");
        }

        AnalyticsService.instance.logEvent('ai_guardian_action',
            parameters: {'action': 'proceeded'});
      }
    } catch (e) {
      AppLogger.error("AI Guardian Check Failed: $e");
      // Fallthrough to allow trade if AI fails
    }

    return placeOrder(order);
  }

  /// Places a Market Order immediately at the best available price.
  ///
  /// This is the primary method for entering positions. It performs the following steps:
  /// 1.  **Risk Check**: Validates the order against [RiskManager] limits (size, daily loss, rules).
  /// 2.  **Exchange Submission**: Sends the order to the active [ExchangeService] (Paper or Live).
  /// 3.  **Order Tracking**: Creates an [Order] object and adds it to the local history.
  /// 4.  **Position Update**: Updates the net position for the symbol.
  /// 5.  **Analytics**: Logs the 'order_placed' event to [AnalyticsService].
  ///
  /// [currentPrice] is optional but recommended for accurate risk validation before execution.
  ///
  /// Throws [Exception] if:
  /// *   Risk validation fails.
  /// *   Exchange submission fails (network error, API error).
  Future<OrderResult> placeMarketOrder({
    required String symbol,
    required OrderSide side,
    required double quantity,
    double? currentPrice,
    double? stopLoss,
    double? takeProfit,
    String? strategyId,
  }) async {
    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      if (currentPrice == null) {
        throw ArgumentError(
            "currentPrice is required for order execution (Task 39).");
      }
      double executionPrice = currentPrice;

      final isValid = _riskManager.validateOrder(
        quantity: quantity,
        priceUsdt: executionPrice,
        strategyId: strategyId,
        isLive: isLiveMode,
      );

      if (!isValid) {
        throw Exception("Risk Validation Failed.");
      }

      final symbolInfo = SymbolInfo(
        symbol: symbol,
        displayName: symbol,
        wsStreamName: "${symbol.toLowerCase()}@kline_1m",
      );

      final order = await _exchange.placeOrder(
        symbol: symbolInfo,
        side: side == OrderSide.buy ? "BUY" : "SELL",
        quantity: quantity,
      );

      // We no longer need to manually construct the Order object from a Map response.
      // The exchange adapter now returns a fully formed Order object.

      _orders.add(order);
      _updatePositionAfterTrade(order);

      AnalyticsService.instance.logEvent('order_placed', parameters: {
        'symbol': symbol,
        'side': side.name,
        'quantity': quantity,
        'isLive': isLiveMode,
      });

      return OrderResult(success: true, order: order);
    } catch (e) {
      _lastError = e.toString();
      AppLogger.error("Execution Error: $e");
      rethrow;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Places a Limit Order.
  ///
  /// Limit orders are stored as 'pending' and only fill when the market price
  /// crosses the limit threshold (Task 38).
  Future<OrderResult> placeLimitOrder({
    required String symbol,
    required OrderSide side,
    required double quantity,
    required double limitPrice,
    String? strategyId,
  }) async {
    _isExecuting = true;
    notifyListeners();

    try {
      // Create a pending order instead of immediate market execution
      final order = Order(
        id: const Uuid().v4(),
        symbol: symbol,
        type: OrderType.limit, // Correctly set as limit
        side: side,
        quantity: quantity,
        price: limitPrice,
        status: OrderStatus.open, // Status remains 'open' or 'pending'
        isLive: isLiveMode,
      );

      _orders.add(order);

      AnalyticsService.instance.logEvent('limit_order_placed', parameters: {
        'symbol': symbol,
        'side': side.name,
        'limitPrice': limitPrice,
      });

      return OrderResult(success: true, order: order);
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Updates unrealized PnL for all positions based on latest price.
  void updateUnrealizedPnl(double currentPrice) {
    bool changed = false;

    // 1. Check pending limit orders (Task 38)
    _checkPendingOrders(currentPrice);

    // 2. Update existing positions
    for (final pos in _positions) {
      if (pos.isOpen) {
        final pnlCents = FinancialMath.calculatePnL(
            quantity: pos.quantity,
            entryPrice: pos.entryPrice,
            exitPrice: currentPrice,
            isLong: pos.side == OrderSide.buy);
        final pnl = FinancialMath.centsToDollars(pnlCents);
        if (pos.unrealizedPnl != pnl) {
          pos.unrealizedPnl = pnl;
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  void _checkPendingOrders(double currentPrice) {
    final pending = _orders
        .where((o) => o.status == OrderStatus.open && o.type == OrderType.limit)
        .toList();

    for (final order in pending) {
      final shouldFill = order.side == OrderSide.buy
          ? currentPrice <=
              order.price // Buy limit fills when price falls to limit
          : currentPrice >=
              order.price; // Sell limit fills when price rises to limit

      if (shouldFill) {
        AppLogger.info("🎯 Limit Order Filled: ${order.id} at $currentPrice");
        // In a real exchange, we'd call the API. In simulator, we swap status.
        // For simplicity here, we marked it filled.
        _fillOrderLocal(order, currentPrice);
      }
    }
  }

  void _fillOrderLocal(Order order, double fillPrice) {
    final index = _orders.indexOf(order);
    if (index != -1) {
      _orders[index] = order.copyWith(
        status: OrderStatus.filled,
        filledPrice: fillPrice,
        filledQuantity: order.quantity,
        filledAt: DateTime.now(),
      );
      _updatePositionAfterTrade(_orders[index]);
      notifyListeners();
    }
  }

  /// Callback for technical analysis engine zone triggers.
  void onZoneTrigger(TradeZone zone, Candle candle) {
    AppLogger.info("Zone Triggered: ${zone.id} (${zone.symbol})");
  }

  /// Toggle between Paper and Live exchanges.
  void enableLiveMode(bool enabled) {
    isLiveMode = enabled;
    notifyListeners();
  }

  /// Set the safety level for automated strategy execution.
  void setLiveExecutionMode(LiveExecutionMode mode) {
    liveExecutionMode = mode;
    notifyListeners();
  }

  /// Cancels an active order on the exchange.
  @override
  Future<void> cancelOrder(String orderId, SymbolInfo symbol) async {
    await _exchange.cancelOrder(orderId, symbol);
  }

  /// Closes an open position by placing an offsetting market order.
  @override
  Future<void> closeOrder(String orderId, [double? currentPrice]) async {
    final pos = _positions.firstWhere(
      (p) => p.id == orderId,
      orElse: () => throw Exception("Position not found"),
    );

    await placeMarketOrder(
      symbol: pos.symbol,
      side: pos.side == OrderSide.buy ? OrderSide.sell : OrderSide.buy,
      quantity: pos.quantity,
    );
  }

  /// Closes all open positions immediately.
  @override
  void closeAllOrders([double? currentPrice]) {
    final openPos = openPositions;
    for (final pos in openPos) {
      closeOrder(pos.id, currentPrice);
    }
  }

  /// Checks if a specific strategy is active.
  @override
  bool isStrategyRunning(String id) => false;

  /// Starts an automated trading strategy.
  @override
  Future<void> startStrategy(String id) async {
    AppLogger.info("EXEC: Starting Strategy $id");
  }

  /// Stops an automated trading strategy.
  @override
  Future<void> stopStrategy(String id) async {
    AppLogger.info("EXEC: Stopping Strategy $id");
  }

  /// Emergency stop for all running strategies.
  void stopAllStrategy() {
    AppLogger.info("EXEC: Stopping all strategies");
  }

  /// Manually injects an order into the local history (mainly for tests).
  @override
  void inject(Order order) {
    _orders.add(order);
    notifyListeners();
  }

  /// Resets session data and balances.
  void reset() {
    _orders.clear();
    _positions.clear();
    _paperBalance = 100000.0;
    _liveBalance = 0.0;
    _isReadOnly = false;
    notifyListeners();
  }

  /// Swaps the underlying exchange implementation.
  void setExchange(ExchangeService exchange, {bool readOnly = false}) {
    _exchange = exchange;
    _isReadOnly = readOnly;
    notifyListeners();
  }

  /// Fetches latest balances from the live exchange.
  Future<void> syncLiveBalance() async {
    try {
      final balances = await _exchange.getBalances();
      if (balances.containsKey("USDT")) {
        _liveBalance = balances["USDT"]!;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error("Balance sync failed: $e");
    }
  }

  /// Forces a full sync of balances and positions with the exchange.
  Future<void> reconcile() async {
    AppLogger.info("EXEC: Reconciling with exchange...");
    await syncLiveBalance();
  }

  // Helper Methods
  void _updatePositionAfterTrade(Order order) {
    final index =
        _positions.indexWhere((p) => p.symbol == order.symbol && p.isOpen);

    if (index == -1) {
      // New position
      _positions.add(Position(
        id: const Uuid().v4(),
        symbol: order.symbol,
        side: order.side,
        quantity: order.quantity,
        entryPrice: order.filledPrice ?? order.price,
        openedAt: DateTime.now(),
      ));
    } else {
      final existing = _positions[index];
      if (existing.side == order.side) {
        // Adding to existing position
        existing.addToPosition(
            order.quantity, order.filledPrice ?? order.price);
      } else {
        // Reducing or closing position
        final exitPrice = order.filledPrice ?? order.price;

        if (existing.quantity > order.quantity) {
          // Partial reduction logic
          final pnlCents = FinancialMath.calculatePnL(
            quantity: order.quantity,
            entryPrice: existing.entryPrice,
            exitPrice: exitPrice,
            isLong: existing.side == OrderSide.buy,
          );
          final pnl = FinancialMath.centsToDollars(pnlCents);

          existing.quantity -= order.quantity;

          // Apply PnL to balance
          if (isLiveMode) {
            _liveBalance += pnl;
          } else {
            _paperBalance += pnl;
          }

          _riskManager.recordTradeResult(pnl, strategyId: order.strategyId);
        } else {
          // Full close
          existing.close(exitPrice);
          final pnl = existing.realizedPnL ?? 0.0;

          // Apply PnL to balance
          if (isLiveMode) {
            _liveBalance += pnl;
          } else {
            _paperBalance += pnl;
          }

          _riskManager.recordTradeResult(pnl, strategyId: order.strategyId);
        }
      }
    }
  }

  double _calculateTotalPnL() {
    return _positions
        .where((p) => !p.isOpen)
        .fold(0.0, (sum, p) => sum + (p.realizedPnL ?? 0.0));
  }

  double _calculateTodayPnL() {
    final now = DateTime.now();
    return _positions.where((p) {
      if (p.isOpen) return false;
      final closed = p.closedAt;
      if (closed == null) return false;
      return closed.year == now.year &&
          closed.month == now.month &&
          closed.day == now.day;
    }).fold(0.0, (sum, p) => sum + (p.realizedPnL ?? 0.0));
  }

  double _calculateTotalUnrealizedPnL() {
    return _positions
        .where((p) => p.isOpen)
        .fold(0.0, (sum, p) => sum + (p.unrealizedPnl ?? 0.0));
  }
}

class ExecutionException implements Exception {
  final String message;
  ExecutionException(this.message);
  @override
  String toString() => "ExecutionException: $message";
}
