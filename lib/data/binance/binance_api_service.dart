import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/app_logger.dart';
import '../../engine/exchange/exchange_service.dart';
import '../../domain/candle_model.dart';
import '../../domain/symbol_info.dart';
import '../../domain/order.dart'; // Import Order model
import 'binance_stream_mapper.dart';

class BinanceApiService implements ExchangeService {
  static const String _baseUrl = 'https://api.binance.com';
  static const String _wsBaseUrl = 'wss://stream.binance.com:9443/ws';

  final String apiKey;
  final String apiSecret;
  final http.Client _client = http.Client();

  BinanceApiService({required this.apiKey, required this.apiSecret});

  /// Signs the query string using HMAC SHA256
  String _sign(String queryString) {
    final key = utf8.encode(apiSecret);
    final bytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Adds timestamp and signature to parameters
  Map<String, String> _signParams(Map<String, String> params) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, String> newParams = Map.from(params);
    newParams['timestamp'] = timestamp;

    final queryString = Uri(queryParameters: newParams).query;
    final signature = _sign(queryString);

    newParams['signature'] = signature;
    return newParams;
  }

  // ==========================================
  // EXCHANGE SERVICE IMPLEMENTATION
  // ==========================================

  @override
  Future<List<Candle>> getKlines(SymbolInfo symbol, String interval,
      {int limit = 500}) async {
    final rawKlines = await _getKlinesRaw(
      symbol: symbol.symbol,
      interval: interval,
      limit: limit,
    );
    return BinanceStreamMapper.mapSnapshot(rawKlines);
  }

  @override
  Future<Order> placeOrder({
    required SymbolInfo symbol,
    required String side,
    required double quantity,
    double? price,
  }) async {
    final type = price != null ? 'LIMIT' : 'MARKET';
    final result = await _placeOrderRaw(
      symbol: symbol.symbol,
      side: side.toUpperCase(),
      type: type,
      quantity: quantity,
      price: price,
    );

    // Map Binance JSON to Order object
    return Order(
      id: result['orderId'].toString(),
      symbol: result['symbol'],
      type: result['type'] == 'LIMIT' ? OrderType.limit : OrderType.market,
      side: result['side'] == 'BUY' ? OrderSide.buy : OrderSide.sell,
      quantity: double.parse(result['origQty']),
      price: price ?? 0.0,
      status: _mapBinanceStatus(result['status']),
      filledQuantity: double.parse(result['executedQty']),
      filledPrice: result['price'].toDouble() > 0
          ? result['price'].toDouble()
          : (price ?? 0.0), // Approximate if market
      filledAt: DateTime.fromMillisecondsSinceEpoch(result['transactTime']),
      isLive: true,
    );
  }

  OrderStatus _mapBinanceStatus(String status) {
    switch (status) {
      case 'NEW':
        return OrderStatus.open;
      case 'FILLED':
        return OrderStatus.filled;
      case 'CANCELED':
        return OrderStatus.cancelled;
      case 'REJECTED':
        return OrderStatus.rejected;
      default:
        return OrderStatus.open;
    }
  }

  @override
  Future<void> cancelOrder(String orderId, SymbolInfo symbol) async {
    await _cancelOrderRaw(symbol: symbol.symbol, orderId: orderId);
  }

  @override
  Future<Map<String, double>> getBalances() async {
    final account = await getAccountInfo();
    final balances = <String, double>{};
    if (account['balances'] != null) {
      for (var b in account['balances']) {
        balances[b['asset']] = double.parse(b['free']);
      }
    }
    return balances;
  }

  @override
  Future<List<Order>> getOpenOrders(SymbolInfo symbol) async {
    final result = await _privateRequest(
      'GET',
      '/api/v3/openOrders',
      {'symbol': symbol.symbol},
    );

    return (result as List)
        .map((o) => Order(
              id: o['orderId'].toString(),
              symbol: o['symbol'],
              type: o['type'] == 'LIMIT' ? OrderType.limit : OrderType.market,
              side: o['side'] == 'BUY' ? OrderSide.buy : OrderSide.sell,
              quantity: double.parse(o['origQty']),
              price: double.parse(o['price']),
              status: _mapBinanceStatus(o['status']),
              filledQuantity: double.parse(o['executedQty']),
              filledPrice: double.parse(o['price']),
              filledAt: DateTime.fromMillisecondsSinceEpoch(o['time']),
              isLive: true,
            ))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPositions() async {
    // Spot does not have "positions" same as futures, usually it implies balances.
    // For now we return empty as this is likely for Future/Margin logic.
    return [];
  }

  @override
  Stream<Candle> subscribeToKlines(SymbolInfo symbol, String interval) {
    final channel = WebSocketChannel.connect(
      Uri.parse('$_wsBaseUrl/${symbol.symbol.toLowerCase()}@kline_$interval'),
    );

    return channel.stream
        .map((message) {
          final json = jsonDecode(message);
          return BinanceStreamMapper.mapKlineToCandle(json);
        })
        .where((c) => c != null)
        .cast<Candle>();
  }

  @override
  Stream<Map<String, dynamic>> subscribeToUserData() {
    // Requires ListenKey management. Returning empty for Day 24 scope.
    // In production, implement ListenKey keep-alive loop.
    return const Stream.empty();
  }

  // ==========================================
  // INTERNAL RAW API METHODS
  // ==========================================

  Future<dynamic> getAccountInfo() async {
    return _privateRequest('GET', '/api/v3/account', {});
  }

  Future<dynamic> _publicRequest(
      String endpoint, Map<String, String> params) async {
    final uri =
        Uri.parse('$_baseUrl$endpoint').replace(queryParameters: params);

    try {
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Binance Public API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      AppLogger.error("Binance Public Request Failed: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> _getKlinesRaw({
    required String symbol,
    required String interval,
    int limit = 500,
  }) async {
    final params = {
      'symbol': symbol,
      'interval': interval,
      'limit': limit.toString(),
    };
    return await _publicRequest('/api/v3/klines', params) as List<dynamic>;
  }

  Future<dynamic> _placeOrderRaw({
    required String symbol,
    required String side,
    required String type,
    double? quantity,
    double? price,
  }) async {
    final params = {
      'symbol': symbol,
      'side': side,
      'type': type,
    };

    if (quantity != null) params['quantity'] = quantity.toString();
    if (price != null) params['price'] = price.toString();

    if (type == 'LIMIT') params['timeInForce'] = 'GTC';

    return _privateRequest('POST', '/api/v3/order', params);
  }

  Future<dynamic> _cancelOrderRaw({
    required String symbol,
    String? orderId,
  }) async {
    final params = {'symbol': symbol};
    if (orderId != null) params['orderId'] = orderId;
    return _privateRequest('DELETE', '/api/v3/order', params);
  }

  Future<dynamic> _privateRequest(
      String method, String endpoint, Map<String, String> params) async {
    final signedParams = _signParams(params);
    final uri =
        Uri.parse('$_baseUrl$endpoint').replace(queryParameters: signedParams);

    final headers = {
      'X-MBX-APIKEY': apiKey,
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    try {
      http.Response response;
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers);
      } else if (method == 'POST') {
        response = await _client.post(uri, headers: headers);
      } else if (method == 'DELETE') {
        response = await _client.delete(uri, headers: headers);
      } else {
        throw UnimplementedError("Method $method not implemented");
      }

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return body;
      } else {
        AppLogger.error(
            "BINANCE API ERROR: ${response.statusCode} - ${response.body}");
        throw Exception("Binance API Error: ${body['msg'] ?? response.body}");
      }
    } catch (e) {
      AppLogger.error("BINANCE EXCEPTION: $e");
      rethrow;
    }
  }
}
