import 'dart:async';
import 'dart:math';
import '../../domain/candle_model.dart';
import '../../domain/symbol_info.dart';
import '../../domain/order.dart';
import '../../core/app_logger.dart';
import 'exchange_service.dart';

/// A high-fidelity simulated exchange for LIVE mode rehearsal.
/// Mimics latency, slippage, and maintains a virtual LIVE balance.
class PaperExchangeClient implements ExchangeService {
  final Map<String, double> _balances = {'USDT': 1000000.0, 'BTC': 0.0};
  final Random _random = Random();

  // Simulation of account updates
  final StreamController<Map<String, dynamic>> _userStream =
      StreamController<Map<String, dynamic>>.broadcast();

  double _lastPrice = 0.0;

  @override
  Future<List<Candle>> getKlines(SymbolInfo symbol, String interval,
      {int limit = 500}) async {
    // This client doesn't fetch historical data itself; it expects to be used alongside a real repo
    // In a full dry-run, we'd mock this or pipe it to the actual Binance API
    return [];
  }

  @override
  Future<Order> placeOrder({
    required SymbolInfo symbol,
    required String side,
    required double quantity,
    double? price,
  }) async {
    // 1. Simulate Latency (100ms - 300ms)
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));

    final executionPrice = price ?? _lastPrice;

    // 2. Simulate Slippage (0.01% - 0.05%)
    final slippagePercent = (0.01 + _random.nextDouble() * 0.04) / 100;
    final finalPrice = side == "BUY"
        ? executionPrice * (1 + slippagePercent)
        : executionPrice * (1 - slippagePercent);

    final cost = quantity * finalPrice;

    // 3. Update Virtual Balances
    if (side == "BUY") {
      if (_balances['USDT']! < cost) {
        throw Exception("Insufficient virtual USDT");
      }
      _balances['USDT'] = _balances['USDT']! - cost;
      _balances['BTC'] = _balances['BTC']! + quantity;
    } else {
      if (_balances['BTC']! < quantity) {
        throw Exception("Insufficient virtual BTC");
      }
      _balances['BTC'] = _balances['BTC']! - quantity;
      _balances['USDT'] = _balances['USDT']! + cost;
    }

    AppLogger.info(
        "PAPER-LIVE: Order Filled. Side: $side, Qty: $quantity, Price: $finalPrice (Slippage: ${(slippagePercent * 100).toStringAsFixed(3)}%)");

    final order = Order(
      id: 'paper_${DateTime.now().millisecondsSinceEpoch}',
      symbol: symbol.symbol,
      type: price != null ? OrderType.limit : OrderType.market,
      side: side == "BUY" ? OrderSide.buy : OrderSide.sell,
      quantity: quantity,
      price: finalPrice,
      status: OrderStatus.filled,
      filledQuantity: quantity,
      filledPrice: finalPrice,
      filledAt: DateTime.now(),
      isLive: true, // it's "live" in the sense of the simulation
    );

    // Broadcast update (keep legacy map for now if needed by listeners, or switch listener to Order too)
    // For now we assume listeners handle Map, or we update them.
    // The previous implementation sent a map. Let's keep sending map for stream but return Order.
    _userStream.add({
      'type': 'ORDER_TRADE_UPDATE',
      'data': {
        'orderId': order.id,
        'status': 'FILLED',
        'price': finalPrice,
        'quantity': quantity,
      }
    });

    return order;
  }

  @override
  Future<void> cancelOrder(String orderId, SymbolInfo symbol) async {
    await Future.delayed(const Duration(milliseconds: 50));
    AppLogger.info("PAPER-LIVE: Order $orderId cancelled.");
  }

  @override
  Future<Map<String, double>> getBalances() async => _balances;

  @override
  Future<List<Order>> getOpenOrders(SymbolInfo symbol) async => [];

  @override
  Future<List<Map<String, dynamic>>> getPositions() async => [];

  @override
  Stream<Candle> subscribeToKlines(SymbolInfo symbol, String interval) {
    // In actual implementation, we'd pipe real market data into this client
    // For now, it returns an empty stream as the Repo handles the primary data feed
    return const Stream.empty();
  }

  /// Inject real price updates into the paper client so it can calculate slippage/pnl
  void updatePrice(double price) {
    _lastPrice = price;
  }

  @override
  Stream<Map<String, dynamic>> subscribeToUserData() {
    return _userStream.stream;
  }

  /// Dispose resources to prevent memory leaks
  void dispose() {
    _userStream.close();
  }
}
