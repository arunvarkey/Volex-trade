import '../../domain/candle_model.dart';
import '../../domain/symbol_info.dart';
import '../../domain/order.dart';
import '../../core/app_logger.dart';
import 'exchange_service.dart';

/// Exception thrown when a write operation (order placement/cancellation)
/// is attempted in a read-only environment.
class ReadOnlyViolationException implements Exception {
  final String message;
  ReadOnlyViolationException(this.message);
  @override
  String toString() => "Security Alert: $message";
}

/// A decorator that enforces a strict read-only policy on any [ExchangeService].
/// It allows all data-fetching methods but throws [ReadOnlyViolationException]
/// for any method that modifies account state.
class ReadOnlyExchangeGuard implements ExchangeService {
  final ExchangeService inner;

  ReadOnlyExchangeGuard(this.inner);

  @override
  Future<Map<String, double>> getBalances() => inner.getBalances();

  @override
  Future<List<Order>> getOpenOrders(SymbolInfo symbol) async {
    return inner.getOpenOrders(symbol);
  }

  @override
  Future<List<Map<String, dynamic>>> getPositions() => inner.getPositions();

  @override
  Future<List<Candle>> getKlines(SymbolInfo symbol, String interval,
          {int limit = 500}) =>
      inner.getKlines(symbol, interval, limit: limit);

  @override
  Stream<Candle> subscribeToKlines(SymbolInfo symbol, String interval) =>
      inner.subscribeToKlines(symbol, interval);

  @override
  Stream<Map<String, dynamic>> subscribeToUserData() =>
      inner.subscribeToUserData();

  // --- BLOCKED WRITE OPERATIONS ---

  @override
  Future<Order> placeOrder({
    required SymbolInfo symbol,
    required String side,
    required double quantity,
    double? price,
  }) async {
    // In read-only mode, we block orders.
    // Throwing is safer than returning a dummy order which might imply success.
    throw Exception("Cannot place order in Read-Only Mode");
  }

  @override
  Future<void> cancelOrder(String orderId, SymbolInfo symbol) {
    AppLogger.warning(
        "SECURITY: Blocked cancelOrder attempt on read-only exchange.");
    throw ReadOnlyViolationException(
        "Order cancellation is disabled in READ-ONLY mode.");
  }
}
