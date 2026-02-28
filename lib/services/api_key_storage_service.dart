import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:volex_terminal/core/app_logger.dart';
import 'dart:convert';

class ApiKeyStorageService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static late final encrypt.Encrypter _encrypter;
  static late final encrypt.IV _iv;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Get or Generate Master Key
      String? keyString = await _secureStorage.read(key: 'api_master_key');
      if (keyString == null) {
        final key = encrypt.Key.fromSecureRandom(32);
        keyString = base64.encode(key.bytes);
        await _secureStorage.write(key: 'api_master_key', value: keyString);
      }

      // 2. Setup Encrypter
      final key = encrypt.Key.fromBase64(keyString);

      String? ivString = await _secureStorage.read(key: 'api_master_iv');
      if (ivString == null) {
        final iv = encrypt.IV.fromSecureRandom(16);
        ivString = iv.base64;
        await _secureStorage.write(key: 'api_master_iv', value: ivString);
      }
      _iv = encrypt.IV.fromBase64(ivString);

      _encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      _initialized = true;
    } catch (e) {
      AppLogger.error("ApiKeyStorage init failed: $e");
    }
  }

  static Future<void> storeBinanceKeys({
    required String apiKey,
    required String secretKey,
  }) async {
    if (!_initialized) await initialize();

    final encryptedApiKey = _encrypter.encrypt(apiKey, iv: _iv);
    final encryptedSecret = _encrypter.encrypt(secretKey, iv: _iv);

    await _secureStorage.write(
      key: 'binance_api_key',
      value: encryptedApiKey.base64,
    );

    await _secureStorage.write(
      key: 'binance_secret_key',
      value: encryptedSecret.base64,
    );
  }

  static Future<Map<String, String>?> getBinanceKeys() async {
    if (!_initialized) await initialize();

    final encryptedApiKey = await _secureStorage.read(key: 'binance_api_key');
    final encryptedSecret =
        await _secureStorage.read(key: 'binance_secret_key');

    if (encryptedApiKey == null || encryptedSecret == null) {
      return null;
    }

    try {
      return {
        'apiKey': _encrypter.decrypt64(encryptedApiKey, iv: _iv),
        'secretKey': _encrypter.decrypt64(encryptedSecret, iv: _iv),
      };
    } catch (e) {
      AppLogger.error("Failed to decrypt API keys: $e");
      return null;
    }
  }
}
