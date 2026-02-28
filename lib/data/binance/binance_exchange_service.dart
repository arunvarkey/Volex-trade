import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/symbol_info.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/engine/exchange/exchange_service.dart';
import 'package:volex_terminal/data/binance/binance_api_service.dart';
import 'package:volex_terminal/core/app_logger.dart';

class BinanceExchangeService implements ExchangeService {
  final BinanceApiService _api;

  BinanceExchangeService(this._api);

  @override
  Future<List<Candle>> getKlines(SymbolInfo symbol, String interval,
      {int limit = 500}) async {
    return await _api.getKlines(symbol, interval, limit: limit);
  }

  @override
  Stream<Candle> subscribeToKlines(SymbolInfo symbol, String interval) {
    return _api.subscribeToKlines(symbol, interval);
  }

  @override
  Future<Map<String, double>> getBalances() async {
    return await _api.getBalances();
  }

  @override
  Future<Order> placeOrder({
    required SymbolInfo symbol,
    required String side, // BUY/SELL
    required double quantity,
    double? price,
  }) async {
    AppLogger.info("BINANCE: Placing Order: $side $quantity ${symbol.symbol}");

    final response = await _api.placeOrder(
      symbol: symbol,
      side: side,
      quantity: quantity,
      price: price,
    );

    AppLogger.info("BINANCE: Order Response: ${response.id}");
    return response;
  }

  @override
  Future<void> cancelOrder(String orderId, SymbolInfo symbol) async {
    await _api.cancelOrder(orderId, symbol);
  }

  @override
  Future<List<Order>> getOpenOrders(SymbolInfo symbol) async {
    return await _api.getOpenOrders(symbol);
  }

  @override
  Future<List<Map<String, dynamic>>> getPositions() async {
    return await _api.getPositions();
  }

  @override
  Stream<Map<String, dynamic>> subscribeToUserData() {
    return _api.subscribeToUserData();
  }
}
