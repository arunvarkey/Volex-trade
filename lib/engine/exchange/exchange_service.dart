import '../../domain/candle_model.dart';
import '../../domain/symbol_info.dart';
import '../../domain/order.dart';

abstract class ExchangeService {
  /// Fetches historical and recent klines/candles
  Future<List<Candle>> getKlines(SymbolInfo symbol, String interval,
      {int limit = 500});

  /// Places a live market or limit order
  Future<Order> placeOrder({
    required SymbolInfo symbol,
    required String side,
    required double quantity,
    double? price,
  });

  /// Cancels an open order
  Future<void> cancelOrder(String orderId, SymbolInfo symbol);

  /// Fetches real-time account balances
  Future<Map<String, double>> getBalances();

  /// Fetches currently open orders
  Future<List<Order>> getOpenOrders(SymbolInfo symbol);

  /// Fetches current positions (especially for margin/futures)
  Future<List<Map<String, dynamic>>> getPositions();

  /// Stream of live price updates
  Stream<Candle> subscribeToKlines(SymbolInfo symbol, String interval);

  /// Stream of account updates (fills, balance changes)
  Stream<Map<String, dynamic>> subscribeToUserData();
}
