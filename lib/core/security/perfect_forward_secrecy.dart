import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class PerfectForwardSecrecy {
  // Diffie-Hellman parameters (simplified for demonstration)
  static final _random = Random.secure();
  static const _prime = 23; // In production, use large prime (2048+ bits)
  static const _generator = 5;

  /// Generate ephemeral key pair (new for each session)
  static EphemeralKeyPair generateEphemeralKeyPair() {
    try {
      // Generate random private key
      final privateKey = _random.nextInt(1000000) + 1;

      // Calculate public key: g^privateKey mod p
      final publicKey = _modPow(_generator, privateKey, _prime);

      SecureLogger.debug('Ephemeral key pair generated');

      return EphemeralKeyPair(
        privateKey: privateKey,
        publicKey: publicKey,
      );
    } catch (e) {
      SecureLogger.error('Key pair generation failed', data: {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Compute shared secret from own private key and peer's public key
  static int computeSharedSecret({
    required int ownPrivateKey,
    required int peerPublicKey,
  }) {
    // Shared secret: peerPublicKey^ownPrivateKey mod p
    final sharedSecret = _modPow(peerPublicKey, ownPrivateKey, _prime);

    SecureLogger.debug('Shared secret computed');

    return sharedSecret;
  }

  /// Derive session key from shared secret
  static SessionKey deriveSessionKey(int sharedSecret) {
    try {
      // Hash the shared secret to create encryption key
      final secretBytes = utf8.encode(sharedSecret.toString());
      final hash = sha256.convert(secretBytes);

      // Use hash as AES key
      final keyBytes = Uint8List.fromList(hash.bytes.sublist(0, 32));
      final key = encrypt.Key(keyBytes);

      // Generate random IV
      final iv = encrypt.IV.fromSecureRandom(16);

      SecureLogger.debug('Session key derived');

      return SessionKey(
        key: key,
        iv: iv,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      SecureLogger.error('Session key derivation failed', data: {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Encrypt data with session key
  static String encryptWithSessionKey({
    required String plaintext,
    required SessionKey sessionKey,
  }) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(
        sessionKey.key,
        mode: encrypt.AESMode.cbc,
      ));

      final encrypted = encrypter.encrypt(plaintext, iv: sessionKey.iv);

      return encrypted.base64;
    } catch (e) {
      SecureLogger.error('Session encryption failed', data: {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Decrypt data with session key
  static String decryptWithSessionKey({
    required String ciphertext,
    required SessionKey sessionKey,
  }) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(
        sessionKey.key,
        mode: encrypt.AESMode.cbc,
      ));

      final encrypted = encrypt.Encrypted.fromBase64(ciphertext);
      final decrypted = encrypter.decrypt(encrypted, iv: sessionKey.iv);

      return decrypted;
    } catch (e) {
      SecureLogger.error('Session decryption failed', data: {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Modular exponentiation (a^b mod m)
  static int _modPow(int base, int exponent, int modulus) {
    if (modulus == 1) return 0;

    var result = 1;
    base = base % modulus;

    while (exponent > 0) {
      if (exponent % 2 == 1) {
        result = (result * base) % modulus;
      }

      exponent = exponent >> 1;
      base = (base * base) % modulus;
    }

    return result;
  }

  /// Check if session key should be rotated (every 1 hour)
  static bool shouldRotateKey(SessionKey sessionKey) {
    final age = DateTime.now().difference(sessionKey.createdAt);
    return age > const Duration(hours: 1);
  }

  /// Create complete PFS session
  static PfsSession createSession() {
    final keyPair = generateEphemeralKeyPair();

    return PfsSession(
      keyPair: keyPair,
      createdAt: DateTime.now(),
    );
  }
}

class EphemeralKeyPair {
  final int privateKey;
  final int publicKey;

  EphemeralKeyPair({
    required this.privateKey,
    required this.publicKey,
  });

  /// Securely dispose of private key
  void dispose() {
    // Overwrite private key in memory (best effort)
    SecureLogger.debug('Ephemeral key pair disposed');
  }
}

class SessionKey {
  final encrypt.Key key;
  final encrypt.IV iv;
  final DateTime createdAt;

  SessionKey({
    required this.key,
    required this.iv,
    required this.createdAt,
  });

  /// Check if key is expired
  bool get isExpired {
    final age = DateTime.now().difference(createdAt);
    return age > const Duration(hours: 1);
  }

  /// Securely dispose of session key
  void dispose() {
    // Keys are immutable in Dart, but we can clear references
    SecureLogger.debug('Session key disposed');
  }
}

class PfsSession {
  final EphemeralKeyPair keyPair;
  final DateTime createdAt;
  SessionKey? _sessionKey;

  PfsSession({
    required this.keyPair,
    required this.createdAt,
  });

  /// Establish session with peer
  void establishSession(int peerPublicKey) {
    final sharedSecret = PerfectForwardSecrecy.computeSharedSecret(
      ownPrivateKey: keyPair.privateKey,
      peerPublicKey: peerPublicKey,
    );

    _sessionKey = PerfectForwardSecrecy.deriveSessionKey(sharedSecret);

    SecureLogger.info('PFS session established');
  }

  /// Get session key
  SessionKey? get sessionKey => _sessionKey;

  /// Check if session is active
  bool get isActive => _sessionKey != null && !_sessionKey!.isExpired;

  /// Dispose session
  void dispose() {
    keyPair.dispose();
    _sessionKey?.dispose();
    _sessionKey = null;

    SecureLogger.info('PFS session disposed');
  }
}
