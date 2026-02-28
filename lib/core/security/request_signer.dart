import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:volex_terminal/core/security/device_fingerprint.dart';

class RequestSigner {
  static const _signatureVersion = 'v1';
  static const _uuid = Uuid();

  // Nonce cache to prevent replay attacks
  static final _usedNonces = <String, DateTime>{};
  static const _nonceTTL = Duration(minutes: 5);

  /// Sign an API request
  static Future<SignedRequest> signRequest({
    required String method,
    required String path,
    required Map<String, dynamic> params,
    required String apiSecret,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _generateNonce();
    final requestId = _uuid.v4();
    final deviceFingerprint = await DeviceFingerprint.generateFingerprint();

    // Create canonical request string
    final canonicalRequest = _createCanonicalRequest(
      method: method,
      path: path,
      params: params,
      timestamp: timestamp,
      nonce: nonce,
      requestId: requestId,
      deviceFingerprint: deviceFingerprint,
    );

    // Generate signature
    final signature = _generateSignature(canonicalRequest, apiSecret);

    // Add anti-tampering headers
    final signedParams = {
      ...params,
      'timestamp': timestamp,
      'nonce': nonce,
      'request_id': requestId,
      'device_fingerprint': deviceFingerprint,
      'signature_version': _signatureVersion,
      'signature': signature,
    };

    SecureLogger.debug('Request signed', data: {
      'method': method,
      'path': path,
      'request_id': requestId,
      'timestamp': timestamp,
    });

    return SignedRequest(
      params: signedParams,
      signature: signature,
      timestamp: timestamp,
      nonce: nonce,
      requestId: requestId,
    );
  }

  /// Verify a signed request (for server-side validation if needed)
  static bool verifyRequest({
    required String method,
    required String path,
    required Map<String, dynamic> params,
    required String apiSecret,
  }) {
    try {
      final timestamp = params['timestamp'] as int?;
      final nonce = params['nonce'] as String?;
      final signature = params['signature'] as String?;
      final requestId = params['request_id'] as String?;
      final deviceFingerprint = params['device_fingerprint'] as String?;

      if (timestamp == null ||
          nonce == null ||
          signature == null ||
          requestId == null ||
          deviceFingerprint == null) {
        SecureLogger.warning('Missing required signature fields');
        return false;
      }

      // Check timestamp (prevent old requests)
      final requestTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(requestTime);

      if (age > const Duration(minutes: 5)) {
        SecureLogger.warning('Request too old',
            data: {'age_seconds': age.inSeconds});
        return false;
      }

      // Check for nonce reuse (replay attack)
      if (_isNonceUsed(nonce)) {
        SecureLogger.critical('Nonce reuse detected - possible replay attack!',
            data: {
              'nonce': nonce,
              'request_id': requestId,
            });
        return false;
      }

      // Recreate canonical request
      final canonicalRequest = _createCanonicalRequest(
        method: method,
        path: path,
        params: Map<String, dynamic>.from(params)..remove('signature'),
        timestamp: timestamp,
        nonce: nonce,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );

      // Verify signature
      final expectedSignature = _generateSignature(canonicalRequest, apiSecret);
      final isValid = expectedSignature == signature;

      if (isValid) {
        _markNonceUsed(nonce);
      } else {
        SecureLogger.critical('Signature verification failed!', data: {
          'request_id': requestId,
        });
      }

      return isValid;
    } catch (e) {
      SecureLogger.error('Request verification error',
          data: {'error': e.toString()});
      return false;
    }
  }

  /// Create canonical request string for signing
  static String _createCanonicalRequest({
    required String method,
    required String path,
    required Map<String, dynamic> params,
    required int timestamp,
    required String nonce,
    required String requestId,
    required String deviceFingerprint,
  }) {
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();

    final paramString =
        sortedKeys.map((key) => '$key=${params[key]}').join('&');

    // Create canonical string
    final canonical = [
      method.toUpperCase(),
      path,
      paramString,
      timestamp.toString(),
      nonce,
      requestId,
      deviceFingerprint,
      _signatureVersion,
    ].join('\n');

    return canonical;
  }

  /// Generate HMAC-SHA512 signature
  static String _generateSignature(String data, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha512, key);
    final digest = hmac.convert(bytes);

    return base64.encode(digest.bytes);
  }

  /// Generate cryptographically secure nonce
  static String _generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _uuid.v4();
    final nonceData = '$timestamp:$random';

    return sha256.convert(utf8.encode(nonceData)).toString();
  }

  /// Check if nonce has been used (replay attack prevention)
  static bool _isNonceUsed(String nonce) {
    _cleanupExpiredNonces();
    return _usedNonces.containsKey(nonce);
  }

  /// Mark nonce as used
  static void _markNonceUsed(String nonce) {
    _usedNonces[nonce] = DateTime.now();
    _cleanupExpiredNonces();
  }

  /// Remove expired nonces from cache
  static void _cleanupExpiredNonces() {
    final now = DateTime.now();
    _usedNonces.removeWhere((nonce, time) {
      return now.difference(time) > _nonceTTL;
    });
  }

  /// Clear nonce cache (for testing)
  static void clearNonceCache() {
    _usedNonces.clear();
  }
}

class SignedRequest {
  final Map<String, dynamic> params;
  final String signature;
  final int timestamp;
  final String nonce;
  final String requestId;

  SignedRequest({
    required this.params,
    required this.signature,
    required this.timestamp,
    required this.nonce,
    required this.requestId,
  });

  /// Get headers for HTTP request
  Map<String, String> toHeaders() {
    return {
      'X-Signature': signature,
      'X-Timestamp': timestamp.toString(),
      'X-Nonce': nonce,
      'X-Request-ID': requestId,
      'X-Signature-Version': RequestSigner._signatureVersion,
    };
  }

  /// Get query string
  String toQueryString() {
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }
}
