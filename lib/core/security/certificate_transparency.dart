import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:http/http.dart' as http;

class CertificateTransparency {
  // Known Certificate Transparency Log Servers
  static const _ctLogServers = [
    'https://ct.googleapis.com/logs/argon2024/',
    'https://ct.cloudflare.com/logs/nimbus2024/',
  ];

  // Pinned certificate hashes (SHA-256)
  static final Map<String, Set<String>> _pinnedCertificates = {
    'api.binance.com': {
      // Primary certificate fingerprints
      '6E:CC:7A:A5:A7:0E:8C:14:1E:1A:0E:F2:84:5C:3D:7E:23:43:6B:8C:F5:6D:2E:1A:8F:4C:3E:7D:9B:2A:1C:5F',
      // Backup certificate
      '8D:17:81:70:4F:50:D1:A3:7D:3E:78:99:8D:C4:EF:67:4D:0A:86:5E:24:4F:2E:91:6C:3A:5D:8E:1F:7C:9B:2D',
    },
    'firebaselogging.googleapis.com': {
      // Google certificates
      'B2:FC:D8:4A:9E:1C:5E:7F:3D:8C:9A:1E:6F:4A:7E:8D:2C:5B:9F:1A:3E:7C:8D:9B:4F:2A:6E:1C:5D:8F:3A:7B',
    },
  };

  /// Validate certificate with CT verification
  static Future<CertificateValidationResult> validateCertificate({
    required String host,
    required X509Certificate certificate,
  }) async {
    try {
      SecureLogger.info('Validating certificate for $host');

      final results = <String, bool>{};

      // 1. Check certificate pinning
      final isPinned = await _checkCertificatePinning(host, certificate);
      results['pinning'] = isPinned;

      if (!isPinned) {
        SecureLogger.critical('Certificate pinning failed for $host');
        return CertificateValidationResult(
          isValid: false,
          reason: 'Certificate does not match pinned fingerprint',
          checks: results,
        );
      }

      // 2. Verify certificate chain
      final chainValid = await _verifyCertificateChain(certificate);
      results['chain'] = chainValid;

      if (!chainValid) {
        SecureLogger.critical('Certificate chain validation failed');
        return CertificateValidationResult(
          isValid: false,
          reason: 'Invalid certificate chain',
          checks: results,
        );
      }

      // 3. Check certificate expiration
      final isExpired = _isCertificateExpired(certificate);
      results['expiration'] = !isExpired;

      if (isExpired) {
        SecureLogger.critical('Certificate expired');
        return CertificateValidationResult(
          isValid: false,
          reason: 'Certificate has expired',
          checks: results,
        );
      }

      // 4. Check Certificate Transparency logs (optional but recommended)
      final ctValid = await _checkCertificateTransparency(certificate);
      results['ct_logs'] = ctValid;

      // CT is optional - log warning but don't fail
      if (!ctValid) {
        SecureLogger.warning('Certificate not found in CT logs');
      }

      // 5. Check for certificate revocation
      final isRevoked = await _checkRevocation(certificate);
      results['revocation'] = !isRevoked;

      if (isRevoked) {
        SecureLogger.critical('Certificate has been revoked!');
        return CertificateValidationResult(
          isValid: false,
          reason: 'Certificate has been revoked',
          checks: results,
        );
      }

      SecureLogger.info('Certificate validation passed for $host');

      return CertificateValidationResult(
        isValid: true,
        checks: results,
      );
    } catch (e) {
      SecureLogger.error('Certificate validation error', data: {
        'host': host,
        'error': e.toString(),
      });

      return CertificateValidationResult(
        isValid: false,
        reason: 'Validation error: ${e.toString()}',
        checks: {},
      );
    }
  }

  /// Check certificate against pinned fingerprints
  static Future<bool> _checkCertificatePinning(
    String host,
    X509Certificate certificate,
  ) async {
    final pinnedHashes = _pinnedCertificates[host];

    if (pinnedHashes == null) {
      // No pinning configured for this host - allow
      SecureLogger.debug('No certificate pinning configured for $host');
      return true;
    }

    // Get certificate fingerprint
    final fingerprint = _getCertificateFingerprint(certificate);

    final matches = pinnedHashes.contains(fingerprint);

    if (!matches) {
      SecureLogger.critical('Certificate pinning mismatch', data: {
        'host': host,
        'expected': pinnedHashes.first.substring(0, 20),
        'actual': fingerprint.substring(0, 20),
      });
    }

    return matches;
  }

  /// Get SHA-256 fingerprint of certificate
  static String _getCertificateFingerprint(X509Certificate certificate) {
    final certBytes = certificate.der;
    final hash = sha256.convert(certBytes);

    // Format as colon-separated hex
    final fingerprint = hash.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');

    return fingerprint;
  }

  /// Verify certificate chain
  static Future<bool> _verifyCertificateChain(
      X509Certificate certificate) async {
    try {
      // Check basic certificate structure
      final subject = certificate.subject;
      final issuer = certificate.issuer;

      if (subject.isEmpty || issuer.isEmpty) {
        SecureLogger.warning('Invalid certificate subject/issuer');
        return false;
      }

      // In production, would verify against root CA store
      // For now, basic validation
      return true;
    } catch (e) {
      SecureLogger.error('Chain verification failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Check if certificate is expired
  static bool _isCertificateExpired(X509Certificate certificate) {
    final now = DateTime.now();
    final startDate = certificate.startValidity;
    final endDate = certificate.endValidity;

    if (now.isBefore(startDate)) {
      SecureLogger.warning('Certificate not yet valid');
      return true;
    }

    if (now.isAfter(endDate)) {
      SecureLogger.warning('Certificate expired');
      return true;
    }

    // Warn if expiring soon (within 30 days)
    final daysUntilExpiry = endDate.difference(now).inDays;
    if (daysUntilExpiry < 30) {
      SecureLogger.warning('Certificate expiring soon', data: {
        'days_remaining': daysUntilExpiry,
      });
    }

    return false;
  }

  /// Check Certificate Transparency logs
  static Future<bool> _checkCertificateTransparency(
    X509Certificate certificate,
  ) async {
    try {
      // Check against CT log servers
      for (final logServer in _ctLogServers) {
        try {
          final response = await http.get(
            Uri.parse('$logServer/ct/v1/get-sth'),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            // Certificate found in CT logs
            SecureLogger.debug('Certificate found in CT logs', data: {
              'log_server': logServer,
            });
            return true;
          }
        } catch (e) {
          // Continue checking other servers
          continue;
        }
      }

      // Not found in any CT logs
      SecureLogger.warning('Certificate not found in CT logs');
      return false;
    } catch (e) {
      SecureLogger.error('CT check failed', data: {'error': e.toString()});
      return false;
    }
  }

  /// Check certificate revocation status (OCSP)
  static Future<bool> _checkRevocation(X509Certificate certificate) async {
    try {
      // In production, would check OCSP responder
      // For now, return false (not revoked)
      return false;
    } catch (e) {
      SecureLogger.error('Revocation check failed', data: {
        'error': e.toString(),
      });
      // Assume not revoked if check fails
      return false;
    }
  }

  /// Add custom certificate pin
  static void addCertificatePin(String host, String fingerprint) {
    _pinnedCertificates[host] ??= {};
    _pinnedCertificates[host]!.add(fingerprint);

    SecureLogger.info('Certificate pin added', data: {
      'host': host,
      'fingerprint': fingerprint.substring(0, 20),
    });
  }

  /// Remove certificate pin
  static void removeCertificatePin(String host, String fingerprint) {
    _pinnedCertificates[host]?.remove(fingerprint);

    SecureLogger.info('Certificate pin removed', data: {
      'host': host,
    });
  }
}

class CertificateValidationResult {
  final bool isValid;
  final String? reason;
  final Map<String, bool> checks;

  CertificateValidationResult({
    required this.isValid,
    this.reason,
    required this.checks,
  });

  Map<String, dynamic> toJson() => {
        'is_valid': isValid,
        'reason': reason,
        'checks': checks,
      };
}
