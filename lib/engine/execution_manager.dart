import 'dart:async';
import 'dart:convert';
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
import 'package:volex_terminal/engine/persistence/persistence_service.dart';
import 'package:volex_terminal/services/analytics_service.dart';
import 'package:volex_terminal/engine/execution/i_execution_service.dart';
import 'package:volex_terminal/features/academy/services/xp_service.dart';
import 'package:volex_terminal/features/trade_checks/services/trade_check_service.dart';
import 'package:volex_terminal/features/trade_checks/ui/trade_check_dialog.dart';
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

  // Strategies the user has activated for paper trading this session.
  final Set<String> _activeStrategyIds = {};

  // Execution status
  bool _isExecuting = false;
  String? _lastError;

  /// Where the paper account is saved between launches.
  ///
  /// Optional so tests can build a manager with no storage behind it; when
  /// null, saving and restoring are both no-ops.
  final PersistenceService? _persistence;

  ExecutionManager({
    ExchangeService? exchange,
    RiskManager? riskManager,
    PersistenceService? persistence,
  })  : _exchange = exchange ?? PaperExchangeClient(),
        _riskManager = riskManager ?? RiskManager(),
        _persistence = persistence;

  static ExecutionManager provide({
    required dynamic marketData,
    required RiskManager riskManager,
    required dynamic persistence,
    ExchangeService? exchange,
  }) {
    return ExecutionManager(
      riskManager: riskManager,
      exchange: exchange,
      // This was accepted and dropped, along with marketData. Nothing about
      // the paper account survived a restart: balance back to $100k, every
      // position and order gone. For a simulator whose whole promise is
      // practising over time and reviewing your record, that erased the
      // record on every launch.
      persistence: persistence is PersistenceService ? persistence : null,
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

  Set<String> get activeStrategyIds => Set.unmodifiable(_activeStrategyIds);

  ExchangeService get exchange => _exchange;

  /// Standard interface method for placing orders.
  ///
  /// The protective levels used to be dropped here: the trade ticket sets
  /// stopLossPrice/takeProfitPrice on the Order, and this forwarded
  /// everything except those two, so a position opened through this path
  /// never carried a stop no matter what the user chose on the ticket.
  @override
  Future<OrderResult?> placeOrder(Order order) async {
    // Route on the order's own type. This used to send everything to
    // placeMarketOrder, so a limit order from the ticket filled instantly at
    // whatever limit price was typed — you could "buy" far below the market
    // and be filled on the spot — while the confirmation still read "Limit
    // order placed". The resting-order machinery (_checkPendingOrders) was
    // already there and simply never reached.
    if (order.type == OrderType.limit) {
      return await placeLimitOrder(
        symbol: order.symbol,
        side: order.side,
        quantity: order.quantity,
        limitPrice: order.price,
        strategyId: order.strategyId,
        stopLoss: order.stopLossPrice,
        takeProfit: order.takeProfitPrice,
      );
    }

    return await placeMarketOrder(
      symbol: order.symbol,
      side: order.side,
      quantity: order.quantity,
      strategyId: order.strategyId,
      currentPrice: order.price,
      stopLoss: order.stopLossPrice,
      takeProfit: order.takeProfitPrice,
    );
  }

  /// Places an order after the pre-trade checks.
  /// Used by UI components to intercept emotional trades.
  Future<OrderResult?> placeOrderWithGuard(
      BuildContext context, Order order) async {
    // 0. Feature Flag Check
    final flags = getIt<FeatureFlagService>();
    if (!flags.areTradeChecksEnabled) {
      return placeOrder(order);
    }

    // Pre-trade checks
    try {
      final tradeChecks = getIt<TradeCheckService>();
      final analysis = await tradeChecks.analyzeTradeIntent(order);

      if (analysis.shouldWarn) {
        // Analytics: Warning Triggered
        AnalyticsService.instance
            // Event names are kept as-is so the analytics series is
            // continuous across the rename to "trade checks".
            .logEvent('ai_guardian_warning_shown', parameters: {
          'symbol': order.symbol,
          'risk_score': analysis.riskScore,
          'emotional_state': analysis.emotionalState.name,
          'pattern_count': analysis.patterns.length,
        });

        if (!context.mounted) return await placeOrder(order);

        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => TradeCheckDialog(analysis: analysis),
        );

        if (proceed != true) {
          AnalyticsService.instance.logEvent('ai_guardian_action',
              parameters: {'action': 'cancelled'});
          return OrderResult(
              success: false,
              message: "User canceled trade after a pre-trade warning.");
        }

        AnalyticsService.instance.logEvent('ai_guardian_action',
            parameters: {'action': 'proceeded'});
      }
    } catch (e) {
      AppLogger.error("Trade check failed: $e");
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
    bool isReduction = false,
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
        // A trade that closes or reduces a position is exempt from the daily
        // loss limit. Nothing in the codebase ever passed this, so it was
        // always false: once the limit was hit, closeOrder was rejected and
        // the user could not exit a losing position — and because protective
        // exits close through the same path, their stop-losses stopped firing
        // at exactly the moment the limit says they are losing money. A risk
        // control that traps you in a trade is worse than none.
        isReduction: isReduction,
      );

      if (!isValid) {
        throw Exception("Risk Validation Failed.");
      }

      final symbolInfo = SymbolInfo(
        symbol: symbol,
        displayName: symbol,
        wsStreamName: "${symbol.toLowerCase()}@kline_1m",
      );

      // The paper simulator prices its fill (and the slippage on it) from the
      // last price it was told about — and nothing ever told it, so
      // _lastPrice sat at 0.0 and every market fill came back at zero. Hand
      // it the price the caller validated against.
      //
      // This is done here rather than by passing `price:` to placeOrder,
      // because on a real exchange that parameter means "limit price": a mark
      // price sent that way would turn a market order into a limit order.
      final exchange = _exchange;
      if (exchange is PaperExchangeClient) {
        exchange.updatePrice(executionPrice);
      }

      final filled = await _exchange.placeOrder(
        symbol: symbolInfo,
        side: side == OrderSide.buy ? "BUY" : "SELL",
        quantity: quantity,
      );

      // The exchange builds its own Order and knows nothing about the
      // ticket's protective levels, so they have to be carried across —
      // otherwise the stop-loss and take-profit the user set are silently
      // dropped on the way to the position.
      //
      // The fill price is also belt-and-braces guarded: anything that comes
      // back non-positive falls back to the validated price rather than
      // opening a position at an entry of zero, which would report the whole
      // mark price as profit.
      final fillPrice = resolveFillPrice(
        reported: filled.filledPrice ?? filled.price,
        validated: executionPrice,
      );

      final order = filled.copyWith(
        price: fillPrice,
        filledPrice: fillPrice,
        stopLossPrice: stopLoss,
        takeProfitPrice: takeProfit,
        strategyId: strategyId,
      );

      _orders.add(order);
      _updatePositionAfterTrade(order);
      _persist();

      // Placing a paper trade is a repeatable, XP-earning action.
      XpService.instance.addXp(XpService.tradeXp);

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
    double? stopLoss,
    double? takeProfit,
  }) async {
    _isExecuting = true;
    notifyListeners();

    try {
      // Limit orders used to skip risk validation entirely — only the market
      // path checked — so an order the risk manager would have rejected could
      // be rested and later filled without ever being examined.
      final isValid = _riskManager.validateOrder(
        quantity: quantity,
        priceUsdt: limitPrice,
        strategyId: strategyId,
        isLive: isLiveMode,
      );

      if (!isValid) {
        throw Exception("Risk Validation Failed.");
      }

      // Create a pending order instead of immediate market execution.
      // The protective levels ride along on the resting order so they are
      // still attached when it fills (see _fillOrderLocal).
      final order = Order(
        id: const Uuid().v4(),
        symbol: symbol,
        type: OrderType.limit, // Correctly set as limit
        side: side,
        quantity: quantity,
        price: limitPrice,
        status: OrderStatus.open, // Status remains 'open' or 'pending'
        strategyId: strategyId,
        stopLossPrice: stopLoss,
        takeProfitPrice: takeProfit,
        isLive: isLiveMode,
      );

      _orders.add(order);
      // A resting order has to survive a restart too, or the user comes back
      // to find a limit they placed has quietly vanished.
      _persist();

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
    _checkPendingOrders(null, currentPrice);

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
    _checkProtectiveExits(null, currentPrice);
    if (changed) notifyListeners();
  }

  /// Closes any open position whose stop-loss or take-profit has been reached
  /// at [price]. Without this, a stop set on the order ticket would be shown
  /// to the user but never actually trigger. Pass [symbol] to limit the check
  /// to one market (the mark price only applies to that market).
  void _checkProtectiveExits(String? symbol, double price) {
    if (price <= 0) return;
    // Collect first: closing mutates _positions.
    final toClose = <Position>[];
    for (final pos in _positions) {
      if (!pos.isOpen) continue;
      if (symbol != null && pos.symbol != symbol) continue;
      final isLong = pos.side == OrderSide.buy;
      if (FinancialMath.shouldTriggerProtectiveExit(
        isLong: isLong,
        price: price,
        stopLoss: pos.stopLoss,
        takeProfit: pos.takeProfit,
      )) {
        AppLogger.info("EXEC: Protective exit hit for ${pos.symbol} at "
            "$price — closing position.");
        toClose.add(pos);
      }
    }
    for (final pos in toClose) {
      // Fire and forget: closeOrder places the offsetting market order.
      unawaited(closeOrder(pos.id, price));
    }
  }

  /// Updates unrealized PnL for open positions of a single [symbol] only.
  /// Used by the multi-symbol strategy runner, where each symbol has its own
  /// mark price and applying one price to every position would be wrong.
  void updateUnrealizedPnlForSymbol(String symbol, double currentPrice) {
    bool changed = false;
    for (final pos in _positions) {
      if (pos.isOpen && pos.symbol == symbol) {
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
    _checkPendingOrders(symbol, currentPrice);
    _checkProtectiveExits(symbol, currentPrice);
    if (changed) notifyListeners();
  }

  /// Fill any resting limit order that [currentPrice] has crossed.
  ///
  /// [symbol] scopes the check to one market. It used to be unscoped, priced
  /// off whichever market the chart happened to be on, so a sell limit resting
  /// at 2000 would fill the instant *any* symbol printed above 2000.
  void _checkPendingOrders(String? symbol, double currentPrice) {
    final pending = _orders
        .where((o) =>
            o.status == OrderStatus.open &&
            o.type == OrderType.limit &&
            (symbol == null || o.symbol == symbol))
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
      _persist();
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

  /// Positions with a close already in flight.
  ///
  /// Closing is asynchronous — the simulated exchange takes 100-300ms — but
  /// the position stays open until the offsetting order comes back. Anything
  /// that re-checks in that window sees an open position and asks again, and
  /// two offsetting orders do not close a position twice: the second one
  /// opens an equal position the other way round.
  ///
  /// Two ways in. Protective exits run on every price update, and prices now
  /// arrive from both the watchlist poll and the candle stream. And a user
  /// double-tapping Close is the same thing by hand.
  final Set<String> _closingPositionIds = {};

  /// Closes an open position by placing an offsetting market order.
  @override
  Future<void> closeOrder(String orderId, [double? currentPrice]) async {
    if (_closingPositionIds.contains(orderId)) return;

    final pos = _positions.firstWhere(
      (p) => p.id == orderId,
      orElse: () => throw Exception("Position not found"),
    );

    if (!pos.isOpen) return;
    _closingPositionIds.add(orderId);

    try {
      // placeMarketOrder requires a mark price; derive it from the position's
      // last-known unrealized PnL when the caller doesn't supply one, so a
      // manual "Close" always works instead of throwing.
      final mark = currentPrice ?? _positionMarkPrice(pos);

      await placeMarketOrder(
        symbol: pos.symbol,
        side: pos.side == OrderSide.buy ? OrderSide.sell : OrderSide.buy,
        quantity: pos.quantity,
        currentPrice: mark,
        // Exiting is always a reduction, so it is not blocked by the daily
        // loss limit. See the note in placeMarketOrder.
        isReduction: true,
      );
    } finally {
      // Released even if the order threw, so a failed close can be retried
      // rather than leaving the position permanently unclosable.
      _closingPositionIds.remove(orderId);
    }
  }

  /// Best-estimate current price of an open position, backed out from its
  /// entry and last-marked unrealized PnL. Falls back to the entry price.
  double _positionMarkPrice(Position pos) {
    final pnl = pos.unrealizedPnl;
    if (pnl == null || pos.quantity == 0) return pos.entryPrice;
    return pos.side == OrderSide.buy
        ? pos.entryPrice + pnl / pos.quantity
        : pos.entryPrice - pnl / pos.quantity;
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
  bool isStrategyRunning(String id) => _activeStrategyIds.contains(id);

  /// Starts an automated trading strategy.
  @override
  Future<void> startStrategy(String id) async {
    if (_activeStrategyIds.add(id)) {
      AppLogger.info("EXEC: Starting Strategy $id");
      AnalyticsService.instance
          .logEvent('strategy_started', parameters: {'strategy_id': id});
      notifyListeners();
    }
  }

  /// Stops an automated trading strategy.
  @override
  Future<void> stopStrategy(String id) async {
    if (_activeStrategyIds.remove(id)) {
      AppLogger.info("EXEC: Stopping Strategy $id");
      AnalyticsService.instance
          .logEvent('strategy_stopped', parameters: {'strategy_id': id});
      notifyListeners();
    }
  }

  /// Emergency stop for all running strategies.
  void stopAllStrategy() {
    if (_activeStrategyIds.isNotEmpty) {
      AppLogger.info("EXEC: Stopping all strategies");
      _activeStrategyIds.clear();
      notifyListeners();
    }
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
    _activeStrategyIds.clear();
    _paperBalance = 100000.0;
    _liveBalance = 0.0;
    _isReadOnly = false;
    _persist();
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

  /// Storage key for the saved paper account.
  static const String _stateKey = 'exec_paper_state_v1';

  /// How many orders to keep. The account is stored as a single JSON blob in
  /// shared preferences, so the history cannot grow without bound.
  static const int _maxStoredOrders = 200;

  /// Reload the paper account saved by [_persist].
  ///
  /// Never throws: a blob written by an older build, or a corrupted one, must
  /// not stop the app from starting. In that case the account simply begins
  /// fresh, which is what happened on every launch before this existed.
  Future<void> restoreState() async {
    final store = _persistence;
    if (store == null) return;

    try {
      final raw = store.getString(_stateKey);
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;

      _paperBalance =
          (data['paperBalance'] as num?)?.toDouble() ?? _paperBalance;

      final positions = (data['positions'] as List?) ?? const [];
      _positions
        ..clear()
        ..addAll(positions
            .whereType<Map<String, dynamic>>()
            .map(Position.fromJson));

      final orders = (data['orders'] as List?) ?? const [];
      _orders
        ..clear()
        ..addAll(orders.whereType<Map<String, dynamic>>().map(Order.fromJson));

      AppLogger.info(
          "EXEC: Restored ${_positions.length} positions, ${_orders.length} "
          "orders, balance ${_paperBalance.toStringAsFixed(2)}.");
      notifyListeners();
    } catch (e, stack) {
      AppLogger.error("EXEC: Could not restore saved account — starting "
          "fresh.", e, stack);
    }
  }

  /// Save the paper account after anything that changes it.
  ///
  /// Deliberately not called from the price-update path: marking positions
  /// happens many times a second and none of it needs to survive a restart,
  /// since unrealized P&L is recomputed from the entry price on the next tick.
  void _persist() {
    final store = _persistence;
    if (store == null) return;

    try {
      // Newest orders are the ones worth keeping if the list is trimmed.
      final orders = _orders.length > _maxStoredOrders
          ? _orders.sublist(_orders.length - _maxStoredOrders)
          : _orders;

      unawaited(store.setString(
        _stateKey,
        jsonEncode({
          'paperBalance': _paperBalance,
          'positions': _positions.map((p) => p.toJson()).toList(),
          'orders': orders.map((o) => o.toJson()).toList(),
        }),
      ));
    } catch (e) {
      // Failing to save must never break the trade that just happened.
      AppLogger.error("EXEC: Could not save account state", e);
    }
  }

  /// Decide the price a position actually opens at.
  ///
  /// [reported] is whatever the exchange said it filled at; [validated] is the
  /// price the caller checked risk against and the user saw on the ticket.
  ///
  /// A fill that comes back as zero, negative or non-finite is not a fill at
  /// any price — opening a position at an entry of 0 makes the entire mark
  /// price look like profit, and an entry of NaN poisons every P&L sum that
  /// touches it. In those cases the validated price is the honest answer.
  static double resolveFillPrice({
    required double reported,
    required double validated,
  }) {
    if (reported > 0 && reported.isFinite) return reported;
    return validated;
  }

  /// Taker fee charged on every simulated fill, as a fraction of notional.
  ///
  /// 0.075% — the same rate the backtest engine models, deliberately. The
  /// paper simulator used to fill for free while backtests charged fees and
  /// slippage, so the same strategy looked better traded by hand than it did
  /// in its own backtest. That gap teaches the single most expensive lesson a
  /// new trader can learn wrong: that costs do not matter. It especially
  /// flatters high-frequency behaviour — the overtrading this app's own
  /// guardian warns about — because free execution is exactly what makes
  /// churning look viable.
  static const double takerFeeRate = 0.00075;

  /// The fee on a fill of [quantity] at [price].
  static double feeFor(double quantity, double price) {
    final notional = (quantity * price).abs();
    if (notional <= 0 || !notional.isFinite) return 0;
    return notional * takerFeeRate;
  }

  /// Debit a fill's fee from whichever balance is in play.
  void _chargeFee(double quantity, double price) {
    final fee = feeFor(quantity, price);
    if (fee <= 0) return;
    if (isLiveMode) {
      _liveBalance -= fee;
    } else {
      _paperBalance -= fee;
    }
  }

  // Helper Methods
  void _updatePositionAfterTrade(Order order) {
    final index =
        _positions.indexWhere((p) => p.symbol == order.symbol && p.isOpen);

    // Every fill costs something, whichever branch below handles it.
    _chargeFee(order.quantity, order.filledPrice ?? order.price);

    if (index == -1) {
      // New position
      _positions.add(Position(
        id: const Uuid().v4(),
        symbol: order.symbol,
        side: order.side,
        quantity: order.quantity,
        entryPrice: order.filledPrice ?? order.price,
        openedAt: DateTime.now(),
        // Carry the ticket's protective exits onto the position so they can
        // actually be enforced (see _checkProtectiveExits).
        stopLoss: order.stopLossPrice,
        takeProfit: order.takeProfitPrice,
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
