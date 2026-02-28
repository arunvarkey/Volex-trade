import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:volex_terminal/core/security/advanced_encryption.dart';
import 'package:volex_terminal/core/security/secure_memory.dart';
import 'dart:convert';

class SecureStorageManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // resetOnError: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      // Use iOS Secure Enclave when available
    ),
  );

  /// Store sensitive data with double encryption
  static Future<void> storeSecure({
    required String key,
    required String value,
    String? userSecret,
    bool requireBiometric = false,
  }) async {
    try {
      SecureLogger.info('Storing secure data', data: {'key': key});

      String dataToStore = value;

      // Apply additional encryption layer if user secret provided
      if (userSecret != null) {
        final encrypted = await AdvancedEncryption.encryptData(
          plaintext: value,
          userSecret: userSecret,
        );
        dataToStore = jsonEncode(encrypted.toJson());
      }

      // Store in secure storage (already encrypted by OS)
      await _storage.write(
        key: key,
        value: dataToStore,
        aOptions: const AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: requireBiometric
              ? KeychainAccessibility.unlocked_this_device
              : KeychainAccessibility.first_unlock_this_device,
        ),
      );

      SecureLogger.info('Secure data stored successfully');
    } catch (e) {
      SecureLogger.error('Failed to store secure data', data: {
        'key': key,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Retrieve sensitive data with double decryption
  static Future<String?> retrieveSecure({
    required String key,
    String? userSecret,
  }) async {
    try {
      SecureLogger.debug('Retrieving secure data', data: {'key': key});

      // Read from secure storage
      final storedData = await _storage.read(key: key);

      if (storedData == null) {
        SecureLogger.debug('No data found for key', data: {'key': key});
        return null;
      }

      // Decrypt if user secret provided
      if (userSecret != null) {
        try {
          final encryptedData = EncryptedData.fromJson(jsonDecode(storedData));
          final decrypted = await AdvancedEncryption.decryptData(
            encryptedData: encryptedData,
            userSecret: userSecret,
          );
          return decrypted;
        } catch (e) {
          SecureLogger.error('Decryption failed',
              data: {'error': e.toString()});
          throw DecryptionFailedException('Failed to decrypt stored data');
        }
      }

      return storedData;
    } catch (e) {
      SecureLogger.error('Failed to retrieve secure data', data: {
        'key': key,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Delete sensitive data
  static Future<void> deleteSecure(String key) async {
    try {
      await _storage.delete(key: key);
      SecureLogger.info('Secure data deleted', data: {'key': key});
    } catch (e) {
      SecureLogger.error('Failed to delete secure data', data: {
        'key': key,
        'error': e.toString(),
      });
    }
  }

  /// Check if key exists
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Get all keys
  static Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      SecureLogger.error('Failed to read all', data: {'error': e.toString()});
      return {};
    }
  }

  /// Wipe all secure storage (nuclear option)
  static Future<void> wipeAll() async {
    try {
      SecureLogger.critical('WIPING ALL SECURE STORAGE');
      await _storage.deleteAll();
      SecureLogger.critical('All secure storage wiped');
    } catch (e) {
      SecureLogger.error('Failed to wipe storage',
          data: {'error': e.toString()});
    }
  }

  /// Store API keys with maximum security
  static Future<void> storeApiKeys({
    required String apiKey,
    required String apiSecret,
    required String userPin,
  }) async {
    // Use secure scope to handle sensitive data
    await SecureScope().execute((scope) async {
      // Wrap sensitive strings
      final secureApiKey = scope.add(SecureMemory.secureString(apiKey));
      final secureApiSecret = scope.add(SecureMemory.secureString(apiSecret));

      // Store with double encryption
      await storeSecure(
        key: 'binance_api_key',
        value: secureApiKey.value,
        userSecret: userPin,
        requireBiometric: true,
      );

      await storeSecure(
        key: 'binance_api_secret',
        value: secureApiSecret.value,
        userSecret: userPin,
        requireBiometric: true,
      );

      SecureLogger.info('API keys stored with maximum security');
    });
  }

  /// Retrieve API keys securely
  static Future<ApiKeys?> retrieveApiKeys({
    required String userPin,
  }) async {
    try {
      final apiKey = await retrieveSecure(
        key: 'binance_api_key',
        userSecret: userPin,
      );

      final apiSecret = await retrieveSecure(
        key: 'binance_api_secret',
        userSecret: userPin,
      );

      if (apiKey == null || apiSecret == null) {
        return null;
      }

      return ApiKeys(
        apiKey: apiKey,
        apiSecret: apiSecret,
      );
    } catch (e) {
      SecureLogger.error('Failed to retrieve API keys', data: {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Delete API keys
  static Future<void> deleteApiKeys() async {
    await deleteSecure('binance_api_key');
    await deleteSecure('binance_api_secret');
    SecureLogger.info('API keys deleted');
  }
}

class ApiKeys {
  final String apiKey;
  final String apiSecret;

  ApiKeys({
    required this.apiKey,
    required this.apiSecret,
  });

  void dispose() {
    SecureMemory.overwriteString(apiKey);
    SecureMemory.overwriteString(apiSecret);
  }
}

class DecryptionFailedException implements Exception {
  final String message;
  DecryptionFailedException(this.message);

  @override
  String toString() => 'DecryptionFailedException: $message';
}
