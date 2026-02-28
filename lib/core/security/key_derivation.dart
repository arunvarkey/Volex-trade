import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:volex_terminal/core/security/device_fingerprint.dart';

class KeyDerivation {
  // PBKDF2 parameters
  static const int _iterations = 100000; // OWASP recommended minimum
  static const int _keyLength = 32; // 256 bits
  static const String _saltPrefix = 'volex_terminal_v2';

  /// Derive encryption key from user credentials + device binding
  static Future<DerivedKey> deriveEncryptionKey({
    required String userSecret, // PIN, password, or biometric hash
    String? additionalEntropy,
  }) async {
    try {
      SecureLogger.info('Deriving encryption key...');

      // Get device fingerprint for device binding
      final deviceFingerprint = await DeviceFingerprint.generateFingerprint();

      // Create unique salt
      final salt = _createSalt(deviceFingerprint);

      // Combine all entropy sources
      final password = _combineEntropy(
        userSecret: userSecret,
        deviceFingerprint: deviceFingerprint,
        additionalEntropy: additionalEntropy,
      );

      // Derive key using PBKDF2
      final derivedKeyBytes = _pbkdf2(
        password: password,
        salt: salt,
        iterations: _iterations,
        keyLength: _keyLength,
      );

      // Encode as base64 for storage
      final derivedKey = base64.encode(derivedKeyBytes);

      SecureLogger.info('Encryption key derived successfully');

      return DerivedKey(
        key: derivedKey,
        salt: base64.encode(salt),
        iterations: _iterations,
        algorithm: 'PBKDF2-HMAC-SHA256',
      );
    } catch (e) {
      SecureLogger.error('Key derivation failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Create unique salt from device fingerprint
  static Uint8List _createSalt(String deviceFingerprint) {
    final saltData = '$_saltPrefix:$deviceFingerprint';
    final hash = sha256.convert(utf8.encode(saltData));
    return Uint8List.fromList(hash.bytes);
  }

  /// Combine multiple entropy sources
  static String _combineEntropy({
    required String userSecret,
    required String deviceFingerprint,
    String? additionalEntropy,
  }) {
    final components = [
      userSecret,
      deviceFingerprint,
      if (additionalEntropy != null) additionalEntropy,
    ];

    return components.join(':');
  }

  /// PBKDF2 key derivation function
  static Uint8List _pbkdf2({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);

    final derivedKey = Uint8List(keyLength);
    var offset = 0;

    for (var blockNumber = 1; offset < keyLength; blockNumber++) {
      final block = _pbkdf2Block(
        hmac: hmac,
        salt: salt,
        blockNumber: blockNumber,
        iterations: iterations,
      );

      final bytesToCopy = (keyLength - offset < block.length)
          ? keyLength - offset
          : block.length;

      derivedKey.setRange(offset, offset + bytesToCopy, block);
      offset += bytesToCopy;
    }

    return derivedKey;
  }

  /// Generate single PBKDF2 block
  static Uint8List _pbkdf2Block({
    required Hmac hmac,
    required Uint8List salt,
    required int blockNumber,
    required int iterations,
  }) {
    // Create block input (salt + block number)
    final blockInput = Uint8List(salt.length + 4);
    blockInput.setRange(0, salt.length, salt);
    blockInput[salt.length] = (blockNumber >> 24) & 0xff;
    blockInput[salt.length + 1] = (blockNumber >> 16) & 0xff;
    blockInput[salt.length + 2] = (blockNumber >> 8) & 0xff;
    blockInput[salt.length + 3] = blockNumber & 0xff;

    // First iteration
    var u = Uint8List.fromList(hmac.convert(blockInput).bytes);
    final result = Uint8List.fromList(u);

    // Remaining iterations
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);

      // XOR with result
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// Verify derived key matches
  static Future<bool> verifyKey({
    required String userSecret,
    required String expectedKey,
    String? additionalEntropy,
  }) async {
    try {
      final derived = await deriveEncryptionKey(
        userSecret: userSecret,
        additionalEntropy: additionalEntropy,
      );

      return derived.key == expectedKey;
    } catch (e) {
      SecureLogger.error('Key verification failed',
          data: {'error': e.toString()});
      return false;
    }
  }

  /// Derive API signing key (different from encryption key)
  static Future<DerivedKey> deriveSigningKey({
    required String apiSecret,
  }) async {
    final deviceFingerprint = await DeviceFingerprint.generateFingerprint();

    return deriveEncryptionKey(
      userSecret: apiSecret,
      additionalEntropy: 'signing_key_v1:$deviceFingerprint',
    );
  }
}

class DerivedKey {
  final String key;
  final String salt;
  final int iterations;
  final String algorithm;

  DerivedKey({
    required this.key,
    required this.salt,
    required this.iterations,
    required this.algorithm,
  });

  Map<String, dynamic> toJson() => {
        'algorithm': algorithm,
        'iterations': iterations,
        'salt': salt,
        // Never include the actual key in JSON!
      };
}
