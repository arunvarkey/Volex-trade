import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/app_logger.dart';

/// Service for handling encrypted storage of sensitive data like API Keys.
class SecurePersistenceService {
  static final SecurePersistenceService _instance =
      SecurePersistenceService._internal();
  factory SecurePersistenceService() => _instance;
  SecurePersistenceService._internal();

  final _storage = const FlutterSecureStorage();

  // Keys
  static const String _binanceApiKey = 'binance_api_key';
  static const String _binanceApiSecret = 'binance_api_secret';

  /// Save API credentials securely
  Future<void> saveBinanceCredentials(String key, String secret) async {
    try {
      await _storage.write(key: _binanceApiKey, value: key);
      await _storage.write(key: _binanceApiSecret, value: secret);
      AppLogger.info('SecureStorage: Credentials saved.');
    } catch (e) {
      AppLogger.error('SecureStorage Error saving', e);
    }
  }

  /// Retrieve Binance API Key
  Future<String?> getBinanceApiKey() async {
    return await _storage.read(key: _binanceApiKey);
  }

  /// Retrieve Binance API Secret
  Future<String?> getBinanceApiSecret() async {
    return await _storage.read(key: _binanceApiSecret);
  }

  /// Delete credentials
  Future<void> clearCredentials() async {
    await _storage.delete(key: _binanceApiKey);
    await _storage.delete(key: _binanceApiSecret);
    AppLogger.info('SecureStorage: Credentials cleared.');
  }

  /// Helper for generic secure storage
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
}
