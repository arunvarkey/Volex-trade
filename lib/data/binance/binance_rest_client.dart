import 'package:http/http.dart' as http;
import '../../core/rate_limiter.dart';
import '../../core/app_logger.dart';

/// REST API client with rate limiting for Binance API.
///
/// Prevents IP bans by limiting requests to 1000/minute (safety margin).
/// Binance actual limit: 1200/minute.
class BinanceRestClient {
  static final _instance = BinanceRestClient._();
  factory BinanceRestClient() => _instance;
  BinanceRestClient._();

  final _rateLimiter = RateLimiter(
    maxRequests: 1000, // Safety margin (Binance limit: 1200/min)
    window: const Duration(minutes: 1),
  );

  int _requestCount = 0;
  DateTime _windowStart = DateTime.now();

  /// Makes a GET request with rate limiting
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    await _rateLimiter.throttle();
    _trackRequest();

    AppLogger.debug('REST: GET $url');
    return http.get(url, headers: headers);
  }

  /// Makes a POST request with rate limiting
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    await _rateLimiter.throttle();
    _trackRequest();

    AppLogger.debug('REST: POST $url');
    return http.post(url, headers: headers, body: body);
  }

  void _trackRequest() {
    final now = DateTime.now();
    if (now.difference(_windowStart).inMinutes >= 1) {
      if (_requestCount > 0) {
        AppLogger.info('REST: $_requestCount requests in last minute');
      }
      _requestCount = 0;
      _windowStart = now;
    }
    _requestCount++;
  }

  /// Gets current request count in this window
  int get requestCount => _requestCount;
}
