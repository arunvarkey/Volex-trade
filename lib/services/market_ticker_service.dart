import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/domain/mini_ticker.dart';

/// Polls Binance's public 24hr ticker REST endpoint for a curated watchlist.
///
/// The WebSocket layer only streams the active chart symbol, so this service
/// gives the rest of the app (ticker tape, markets list) live multi-symbol
/// prices on every platform, including web. Self-contained singleton; UI
/// listens via [ChangeNotifier].
class MarketTickerService extends ChangeNotifier {
  MarketTickerService._();
  static final MarketTickerService instance = MarketTickerService._();

  static const List<String> symbols = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
    'BNBUSDT',
    'XRPUSDT',
    'DOGEUSDT',
    'ADAUSDT',
    'AVAXUSDT',
  ];

  /// Friendly names for the watchlist rows.
  static const Map<String, String> names = {
    'BTCUSDT': 'Bitcoin',
    'ETHUSDT': 'Ethereum',
    'SOLUSDT': 'Solana',
    'BNBUSDT': 'BNB',
    'XRPUSDT': 'XRP',
    'DOGEUSDT': 'Dogecoin',
    'ADAUSDT': 'Cardano',
    'AVAXUSDT': 'Avalanche',
  };

  static const Duration _pollInterval = Duration(seconds: 10);

  final Map<String, MiniTicker> _tickers = {};
  Timer? _timer;
  bool _fetching = false;

  bool get hasData => _tickers.isNotEmpty;

  MiniTicker? ticker(String symbol) => _tickers[symbol];

  /// Tickers in watchlist order (only those already fetched).
  List<MiniTicker> get tickers => [
        for (final s in symbols)
          if (_tickers[s] != null) _tickers[s]!,
      ];

  /// Idempotent: first call fetches immediately and starts polling.
  void start() {
    if (_timer != null) return;
    _fetch();
    _timer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  /// Stop polling. Called when the app goes to the background — this used to
  /// keep hitting Binance every 10 seconds for a tape nobody could see.
  /// [start] is idempotent, so resuming is just another start().
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final symbolsParam = Uri.encodeComponent(jsonEncode(symbols));
      final uri = Uri.parse(
          'https://api.binance.com/api/v3/ticker/24hr?symbols=$symbolsParam');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        AppLogger.warning('TICKER: HTTP ${response.statusCode}');
        return;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return;

      for (final item in decoded) {
        if (item is! Map) continue;
        final symbol = item['symbol'];
        if (symbol is! String) continue;
        _tickers[symbol] = MiniTicker(
          symbol: symbol,
          closePrice: _toDouble(item['lastPrice']),
          openPrice: _toDouble(item['openPrice']),
          highPrice: _toDouble(item['highPrice']),
          lowPrice: _toDouble(item['lowPrice']),
          volume: _toDouble(item['volume']),
          quoteVolume: _toDouble(item['quoteVolume']),
        );
      }
      notifyListeners();
    } catch (e) {
      // Keep last good data; next poll retries.
      AppLogger.warning('TICKER: fetch failed: $e');
    } finally {
      _fetching = false;
    }
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
