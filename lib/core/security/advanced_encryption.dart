import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:volex_terminal/core/security/key_derivation.dart';
import 'dart:io'; // Added missing import for File

class AdvancedEncryption {
  // AES-256-GCM parameters
  static const int _keySize = 32; // 256 bits
  static const int _ivSize = 16; // 128 bits
  static const int _tagSize = 16; // 128 bits

  /// Encrypt data with AES-256-GCM
  static Future<EncryptedData> encryptData({
    required String plaintext,
    required String userSecret,
    String? additionalData,
  }) async {
    try {
      SecureLogger.debug('Encrypting data...');

      // Derive encryption key
      final derivedKey = await KeyDerivation.deriveEncryptionKey(
        userSecret: userSecret,
        additionalEntropy: additionalData,
      );

      // Decode key
      final keyBytes = base64.decode(derivedKey.key);
      final key =
          encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, _keySize)));

      // Generate random IV
      final iv = encrypt.IV.fromSecureRandom(_ivSize);

      // Create encrypter
      final encrypter = encrypt.Encrypter(encrypt.AES(
        key,
        mode: encrypt.AESMode.gcm,
        padding: null, // GCM doesn't need padding
      ));

      // Encrypt
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Create metadata
      final metadata = EncryptionMetadata(
        algorithm: 'AES-256-GCM',
        version: '1.0',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      SecureLogger.debug('Data encrypted successfully');

      return EncryptedData(
        ciphertext: encrypted.base64,
        iv: iv.base64,
        tag: base64
            .encode(encrypted.bytes.sublist(encrypted.bytes.length - _tagSize)),
        metadata: metadata,
      );
    } catch (e) {
      SecureLogger.error('Encryption failed', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Decrypt data with AES-256-GCM
  static Future<String> decryptData({
    required EncryptedData encryptedData,
    required String userSecret,
    String? additionalData,
  }) async {
    try {
      SecureLogger.debug('Decrypting data...');

      // Verify metadata
      if (encryptedData.metadata.algorithm != 'AES-256-GCM') {
        throw EncryptionException('Unsupported encryption algorithm');
      }

      // Derive encryption key (must match encryption)
      final derivedKey = await KeyDerivation.deriveEncryptionKey(
        userSecret: userSecret,
        additionalEntropy: additionalData,
      );

      // Decode key and IV
      final keyBytes = base64.decode(derivedKey.key);
      final key =
          encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, _keySize)));
      final iv = encrypt.IV.fromBase64(encryptedData.iv);

      // Create encrypter
      final encrypter = encrypt.Encrypter(encrypt.AES(
        key,
        mode: encrypt.AESMode.gcm,
        padding: null,
      ));

      // Decrypt
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData.ciphertext);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      SecureLogger.debug('Data decrypted successfully');

      return decrypted;
    } catch (e) {
      SecureLogger.error('Decryption failed', data: {'error': e.toString()});
      throw EncryptionException('Failed to decrypt data: ${e.toString()}');
    }
  }

  /// Encrypt file
  static Future<void> encryptFile({
    required String inputPath,
    required String outputPath,
    required String userSecret,
  }) async {
    try {
      // Read file
      final file = await File(inputPath).readAsString();

      // Encrypt
      final encrypted = await encryptData(
        plaintext: file,
        userSecret: userSecret,
      );

      // Write encrypted data
      final outputFile = File(outputPath);
      await outputFile.writeAsString(jsonEncode(encrypted.toJson()));

      SecureLogger.info('File encrypted', data: {'output': outputPath});
    } catch (e) {
      SecureLogger.error('File encryption failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Decrypt file
  static Future<String> decryptFile({
    required String inputPath,
    required String userSecret,
  }) async {
    try {
      // Read encrypted file
      final file = File(inputPath);
      final encryptedJson = jsonDecode(await file.readAsString());
      final encrypted = EncryptedData.fromJson(encryptedJson);

      // Decrypt
      final decrypted = await decryptData(
        encryptedData: encrypted,
        userSecret: userSecret,
      );

      SecureLogger.info('File decrypted', data: {'input': inputPath});

      return decrypted;
    } catch (e) {
      SecureLogger.error('File decryption failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Generate cryptographic hash
  static String hash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Verify hash
  static bool verifyHash(String data, String expectedHash) {
    return hash(data) == expectedHash;
  }

  /// Secure comparison (constant time to prevent timing attacks)
  static bool secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}

class EncryptedData {
  final String ciphertext;
  final String iv;
  final String tag;
  final EncryptionMetadata metadata;

  EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.tag,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'iv': iv,
        'tag': tag,
        'metadata': metadata.toJson(),
      };

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: json['ciphertext'],
      iv: json['iv'],
      tag: json['tag'],
      metadata: EncryptionMetadata.fromJson(json['metadata']),
    );
  }
}

class EncryptionMetadata {
  final String algorithm;
  final String version;
  final int timestamp;

  EncryptionMetadata({
    required this.algorithm,
    required this.version,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'algorithm': algorithm,
        'version': version,
        'timestamp': timestamp,
      };

  factory EncryptionMetadata.fromJson(Map<String, dynamic> json) {
    return EncryptionMetadata(
      algorithm: json['algorithm'],
      version: json['version'],
      timestamp: json['timestamp'],
    );
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
