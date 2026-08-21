import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../domain/candle_model.dart';
import '../domain/mini_ticker.dart';
import 'data_status.dart';
import 'binance/binance_socket_client.dart';
import '../core/isolate_manager.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/core/synthetic_candles.dart';

import '../core/service_locator.dart';

import 'package:volex_terminal/data/i_market_data_repository.dart';

/// Core repository for real-time and historical market data.
class MarketDataRepository implements IMarketDataRepository {
  factory MarketDataRepository() => getIt<MarketDataRepository>();

  MarketDataRepository.inject();

  /// Visible for testing and mocks
  MarketDataRepository.forTesting();

  final BinanceSocketClient _socketClient = BinanceSocketClient();
  final IsolateManager _isolateManager = IsolateManager();

  // Stream of updates (Real-time)
  final StreamController<Candle> _updatesController =
      StreamController.broadcast();
  @override
  Stream<Candle> get updatesStream => _updatesController.stream;

  @override
  Stream<bool> get connectionStatusStream =>
      _socketClient.connectionStatusStream;

  // Watchlist Stream (Map of Symbol -> Ticker)
  final StreamController<Map<String, MiniTicker>> _watchlistController =
      StreamController.broadcast();
  @override
  Stream<Map<String, MiniTicker>> get watchlistStream =>
      _watchlistController.stream;

  // Data Freshness Stream
  final StreamController<DataStatus> _statusController =
      StreamController.broadcast();
  @override
  Stream<DataStatus> get statusStream => _statusController.stream;

  final Map<String, MiniTicker> _tickerCache = {};

  /// True when the app is serving *generated* candles/ticks because the live
  /// exchange feed was unreachable. Surfaced in the UI so simulated prices are
  /// never mistaken for real market data — a learner reading a chart deserves
  /// to know which one they're looking at.
  bool _simulatedFeed = false;
  bool get isSimulatedFeed => _simulatedFeed;

  bool _initialized = false;

  // Track current connected symbol and interval
  String _currentSymbol = "btcusdt";

  /// The symbol the live candle stream is currently connected to, uppercased.
  ///
  /// Exposed because candles carry no symbol of their own, so a listener on
  /// [updatesStream] otherwise has no way to know which market a tick belongs
  /// to — and applying one market's price to another's position is not a
  /// small error.
  @override
  String get currentSymbol => _currentSymbol.toUpperCase();
  String _currentInterval = "1m";

  // Connection State
  Timer? _fallbackTimer;
  Timer? _pollingTimer;
  DateTime? _lastMsgTime;
  bool _usingPolling = false;

  /// Our subscription to the socket client's broadcast stream.
  ///
  /// connectStream() used to call `_socketClient.stream.listen(...)` every
  /// time without ever cancelling the previous subscription — and
  /// switchStream() routes every symbol and timeframe change through it. So
  /// each switch left another live listener behind, and every one of them ran
  /// _isolateManager.processData() on every incoming tick. Browse ten symbols
  /// and the app did ten times the parsing work per message, for good.
  StreamSubscription<String>? _socketSubscription;

  /// True while the app is backgrounded; see [pauseLiveFeeds].
  bool _paused = false;

  // Synthetic live feed — keeps charts and tickers moving when the real
  // Binance feed is blocked/offline, so the app never looks frozen.
  Timer? _syntheticTimer;
  final Random _rng = Random();
  final Map<String, double> _synthClose = {};
  int _synthBucket = 0;
  String _synthBucketSymbol = '';
  double _synthOpen = 0, _synthHigh = 0, _synthLow = 0;
  static const List<String> _watchSymbols = [
    'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'BNBUSDT',
    'XRPUSDT', 'DOGEUSDT', 'ADAUSDT', 'AVAXUSDT',
    'LINKUSDT', 'MATICUSDT', 'DOTUSDT', 'TRXUSDT',
    'LTCUSDT', 'ATOMUSDT',
  ];

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _isolateManager.start();

    // Listen to Isolate Output
    _isolateManager.outputStream.listen((data) {
      if (data is Candle) {
        _updatesController.add(data);
      } else if (data is List<Candle>) {
        // Snapshot logic handled in future completers
      } else if (data is List<MiniTicker>) {
        for (var t in data) {
          _tickerCache[t.symbol] = t;
        }
        _watchlistController.add(Map.unmodifiable(_tickerCache));
      }
    });

    _initialized = true;
    _seedWatchlist();
    _startWatchdog();
    _startSyntheticFeed();
  }

  /// Pre-populate every watchlist symbol with a synthetic ticker so the market
  /// list is complete from the first frame. Real ticks (and the synthetic
  /// feed) merge into the same cache, so partial live coverage can no longer
  /// leave the list showing only a handful of coins.
  void _seedWatchlist() {
    for (final s in _watchSymbols) {
      if (_tickerCache.containsKey(s)) continue;
      final gen = SyntheticCandles.generate(s, '1m', 2);
      final open = gen.first.close;
      final close = gen.last.close;
      _synthClose[s] = close;
      _tickerCache[s] = MiniTicker(
        symbol: s,
        closePrice: close,
        openPrice: open,
        highPrice: max(open, close),
        lowPrice: min(open, close),
        volume: open * 1000,
        quoteVolume: open * open * 1000,
      );
    }
    _watchlistController.add(Map.unmodifiable(_tickerCache));
  }

  /// Emits synthetic ticks (~1/sec) whenever the real feed is stale, so the
  /// chart's last candle and the watchlist tickers keep moving live.
  void _startSyntheticFeed() {
    _syntheticTimer?.cancel();
    _syntheticTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      final stale = _lastMsgTime == null ||
          DateTime.now().difference(_lastMsgTime!).inSeconds >= 6;
      if (stale) _emitSyntheticTick();
    });
  }

  void _emitSyntheticTick() {
    // Live prices are being generated, not received — mark the feed simulated.
    _simulatedFeed = true;
    final symbol = _currentSymbol.toUpperCase();
    final intervalMs = _synthIntervalMs(_currentInterval);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final bucket = nowMs - (nowMs % intervalMs);

    final last = _synthClose[symbol] ??
        SyntheticCandles.generate(symbol, _currentInterval, 1).last.close;
    final drift = (_rng.nextDouble() - 0.5) * last * 0.0025;
    var close = last + drift;
    if (close <= 0) close = last;
    _synthClose[symbol] = close;

    if (_synthBucketSymbol != symbol || bucket != _synthBucket) {
      _synthBucketSymbol = symbol;
      _synthBucket = bucket;
      _synthOpen = last;
      _synthHigh = close;
      _synthLow = close;
    } else {
      _synthHigh = max(_synthHigh, close);
      _synthLow = min(_synthLow, close);
    }

    _updatesController.add(Candle(
      time: bucket,
      open: _synthOpen,
      high: _synthHigh,
      low: _synthLow,
      close: close,
      volume: last * (2 + _rng.nextDouble() * 6),
    ));

    // Keep the whole watchlist ticking so tapes and market lists animate.
    for (final s in _watchSymbols) {
      final lp = _synthClose[s] ??
          SyntheticCandles.generate(s, '1m', 1).last.close;
      var np = lp + (_rng.nextDouble() - 0.5) * lp * 0.0025;
      if (np <= 0) np = lp;
      _synthClose[s] = np;
      final prev = _tickerCache[s];
      _tickerCache[s] = MiniTicker(
        symbol: s,
        closePrice: np,
        openPrice: prev?.openPrice ?? lp,
        highPrice: prev != null ? max(prev.highPrice, np) : np,
        lowPrice: prev != null ? min(prev.lowPrice, np) : np,
        volume: lp * 1000,
        quoteVolume: lp * lp * 1000,
      );
    }
    _watchlistController.add(Map.unmodifiable(_tickerCache));
  }

  int _synthIntervalMs(String interval) {
    switch (interval) {
      case '5m':
        return 5 * 60000;
      case '15m':
        return 15 * 60000;
      case '1h':
        return 60 * 60000;
      case '4h':
        return 4 * 60 * 60000;
      case '1d':
        return 24 * 60 * 60000;
      default:
        return 60000;
    }
  }

  void _startWatchdog() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastMsgTime == null) return;
      final diff = DateTime.now().difference(_lastMsgTime!);
      if (diff.inSeconds > 5 && !_usingPolling) {
        _startPolling();
      }
    });
  }

  void _startPolling() {
    AppLogger.warning("WebSocket Stale. Starting REST Polling Fallback...");
    _usingPolling = true;
    _statusController.add(DataStatus.unknown());
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _pollOnce();
    });
  }

  Future<void> _pollOnce() async {
    try {
      final symbol = _currentSymbol.toUpperCase();
      final interval = _currentInterval;
      final klineUrl = Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=1');
      final klineResponse = await http.get(klineUrl);

      if (klineResponse.statusCode == 200) {
        final List<dynamic> json =
            const JsonDecoder().convert(klineResponse.body);
        final candle = Candle.fromJson(json[0]);
        _updatesController.add(candle);
      }

      // TASK 51 Fix: Removed redundant 24hr ticker fetch (2MB+ overhead)
    } catch (e) {
      AppLogger.error("Polling Error: $e");
    }
  }

  @override
  Future<List<Candle>> fetchHistory(
      {String symbol = "BTCUSDT",
      String interval = "1m",
      int limit = 500}) async {
    try {
      final symbolParam = symbol.toUpperCase();
      final url = Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$symbolParam&interval=$interval&limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> json = const JsonDecoder().convert(response.body);
        final candles = json.map((j) => Candle.fromJson(j)).toList();
        if (candles.isNotEmpty) {
          _simulatedFeed = false;
          return candles;
        }
      }
      AppLogger.warning(
          "History: empty/failed real data for $symbol (${response.statusCode}); using synthetic.");
    } catch (e) {
      AppLogger.error("History Fetch Error: $e. Using synthetic candles.");
    }
    // Offline/blocked fallback so the scanner and signal engine always have data.
    _simulatedFeed = true;
    return SyntheticCandles.generate(symbol, interval, limit);
  }

  @override
  void connectStream({String symbol = "btcusdt", String interval = "1m"}) {
    _currentSymbol = symbol;
    _currentInterval = interval;

    final streamUrl =
        "wss://stream.binance.com:9443/ws/$symbol@kline_$interval";
    _socketClient.connect(urlOverride: streamUrl);

    // Replace, never stack: see the note on [_socketSubscription].
    _socketSubscription?.cancel();
    _socketSubscription = _socketClient.stream.listen((msg) {
      _lastMsgTime = DateTime.now();
      if (_usingPolling) {
        _stopPolling();
      }
      _isolateManager.processData(msg);
    });
  }

  /// Stop network and tick activity while the app is in the background.
  ///
  /// Without this the app kept a websocket open, polled Binance over REST
  /// every 2 seconds, ran a 5-second watchdog and emitted synthetic ticks for
  /// as long as it stayed in memory — burning battery and mobile data for
  /// screens nobody was looking at.
  void pauseLiveFeeds() {
    if (_paused) return;
    _paused = true;
    _fallbackTimer?.cancel();
    _pollingTimer?.cancel();
    _syntheticTimer?.cancel();
    _usingPolling = false;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socketClient.disconnect();
    AppLogger.info("DATA: Live feeds paused (app backgrounded).");
  }

  /// Resume what [pauseLiveFeeds] stopped, on the symbol we were last on.
  void resumeLiveFeeds() {
    if (!_paused) return;
    _paused = false;
    _lastMsgTime = null;
    connectStream(symbol: _currentSymbol, interval: _currentInterval);
    _startWatchdog();
    _startSyntheticFeed();
    AppLogger.info("DATA: Live feeds resumed.");
  }

  void _stopPolling() {
    AppLogger.info("WebSocket Restored. Stopping Polling.");
    _usingPolling = false;
    _statusController.add(DataStatus.unknown());
    _pollingTimer?.cancel();
  }

  @override
  void switchStream(String symbol, String interval) {
    _socketClient.disconnect();
    connectStream(symbol: symbol, interval: interval);
  }

  @override
  void switchSymbol(String symbol) {
    switchStream(symbol, _currentInterval);
  }

  @override
  Stream<List<Candle>> getHistoryStream(String symbol, String interval) {
    return Stream.fromFuture(fetchHistory(symbol: symbol, interval: interval));
  }

  @override
  Stream<Candle> getStreamForSymbol(String symbol) {
    return updatesStream.where((c) => true);
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socketClient.disconnect();
    _isolateManager.dispose();
    _updatesController.close();
    _watchlistController.close();
    _statusController.close();
    _fallbackTimer?.cancel();
    _pollingTimer?.cancel();
    _syntheticTimer?.cancel();
  }
}
