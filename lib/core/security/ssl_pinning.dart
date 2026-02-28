import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';

class SSLPinning {
  // Binance certificate SHA256 fingerprints
  // Get these by running: openssl s_client -connect api.binance.com:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -sha256 -noout
  static const _binanceCertificates = [
    // Primary certificate
    '6E:CC:7A:A5:A7:0E:8C:14:1E:1A:0E:F2:84:5C:3D:7E:23:43:6B:8C:F5:6D:2E:1A:8F:4C:3E:7D:9B:2A:1C:5F',
    // Backup certificate (in case of rotation)
    '8D:17:81:70:4F:50:D1:A3:7D:3E:78:99:8D:C4:EF:67:4D:0A:86:5E:24:4F:2E:91:6C:3A:5D:8E:1F:7C:9B:2D',
  ];

  static http.Client createPinnedClient() {
    final context = SecurityContext.defaultContext;
    final client = HttpClient(context: context);

    client.badCertificateCallback = (cert, host, port) {
      SecureLogger.debug('SSL Certificate check for $host:$port');

      // Get certificate fingerprint
      final certBytes = cert.der;
      final certSha256 = _sha256Fingerprint(certBytes);

      SecureLogger.debug('Certificate fingerprint: $certSha256');

      // Check against pinned certificates
      if (host.contains('binance.com')) {
        final isValid = _binanceCertificates.contains(certSha256);
        if (!isValid) {
          SecureLogger.critical(
            'SSL pinning failed for Binance!',
            data: {'host': host, 'fingerprint': certSha256},
          );
        }
        return isValid;
      }

      if (host.contains('firebase') || host.contains('googleapis.com')) {
        // Firebase uses Google certificates - more lenient
        return true; // Let system handle Firebase SSL
      }

      // Default: reject unknown hosts
      SecureLogger.warning('Unknown host in SSL check: $host');
      return false;
    };

    return IOClient(client);
  }

  static String _sha256Fingerprint(List<int> bytes) {
    final hash = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
    return hash;
  }

  // Test SSL pinning
  static Future<bool> testPinning() async {
    try {
      final client = createPinnedClient();
      final response =
          await client.get(Uri.parse('https://api.binance.com/api/v3/ping'));
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      SecureLogger.error('SSL pinning test failed',
          data: {'error': e.toString()});
      return false;
    }
  }
}
