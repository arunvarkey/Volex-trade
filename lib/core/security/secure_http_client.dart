import 'package:http/http.dart' as http;
import 'package:volex_terminal/core/security/ssl_pinning.dart';
import 'package:volex_terminal/core/security/traffic_obfuscation.dart';
import 'package:volex_terminal/core/security/request_signer.dart';
import 'package:volex_terminal/core/security/rate_limiter.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';

class SecureHttpClient {
  static final _rateLimiter = RateLimiter();
  static http.Client? _client;

  /// Get secure HTTP client with all protections
  static http.Client getClient() {
    _client ??= SSLPinning.createPinnedClient();
    return _client!;
  }

  /// Make secure API request
  static Future<http.Response> secureRequest({
    required String method,
    required Uri uri,
    required Map<String, dynamic> params,
    required String apiSecret,
  }) async {
    // 1. Check rate limit
    final rateLimitCheck = await _rateLimiter.checkLimit(uri.path);
    if (!rateLimitCheck.allowed) {
      throw RateLimitException(rateLimitCheck.reason!);
    }

    // 2. Sign request
    final signed = await RequestSigner.signRequest(
      method: method,
      path: uri.path,
      params: params,
      apiSecret: apiSecret,
    );

    // 3. Obfuscate traffic
    final obfuscated = TrafficObfuscation.obfuscateRequest(signed.params);

    // 4. Add random delay
    await TrafficObfuscation.addRandomDelay();

    // 5. Make request
    final client = getClient();
    final response = await client.post(
      uri,
      headers: signed.toHeaders(),
      body: obfuscated,
    );

    SecureLogger.info('Secure request completed', data: {
      'status': response.statusCode,
      'request_id': signed.requestId,
    });

    return response;
  }
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
}
